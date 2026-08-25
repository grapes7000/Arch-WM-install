from __future__ import annotations

import json, os, shutil, subprocess, tempfile
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from .codex_review import review as codex_review
from .models import ProfileError, ProfileSpec, load_profile
from .scanner import scan_tree

MANAGED = ("hypr", "quickshell", "waybar")
PROTECTED = ("kitty", "nvim", "starship.toml", "zsh", "atuin", "theme-engine")
PROVIDERS = {"quickshell", "quickshell-git", "noctalia-qs"}


def _now() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")


def _read(path: Path, default: dict | None = None) -> dict:
    try:
        return json.loads(path.read_text())
    except FileNotFoundError:
        return {} if default is None else default


def _write(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(fd, "w") as f:
            json.dump(data, f, indent=2, sort_keys=True); f.write("\n"); f.flush(); os.fsync(f.fileno())
        os.replace(tmp, path)
    except Exception:
        try: os.unlink(tmp)
        except FileNotFoundError: pass
        raise


def _manifest(path: Path) -> list[str]:
    out=[]
    for raw in path.read_text().splitlines():
        value=raw.split("#",1)[0].strip()
        if value and value not in out: out.append(value)
    return out


@dataclass(frozen=True)
class Paths:
    home: Path; config: Path; data_root: Path; state_root: Path; profile_defs: Path
    @classmethod
    def current(cls, defs: Path) -> "Paths":
        h=Path.home(); cfg=Path(os.environ.get("XDG_CONFIG_HOME", h/".config"))
        dat=Path(os.environ.get("XDG_DATA_HOME", h/".local/share")); st=Path(os.environ.get("XDG_STATE_HOME", h/".local/state"))
        return cls(h,cfg,dat/"arch-wm-install/desktop-profiles",st/"arch-wm-install/desktop-profiles",defs)


class DesktopManager:
    def __init__(self, paths: Paths | None=None) -> None:
        self.paths=paths or Paths.current(Path(__file__).resolve().parent/"profiles")
        self.paths.data_root.mkdir(parents=True,exist_ok=True); self.paths.state_root.mkdir(parents=True,exist_ok=True)

    @property
    def registry_path(self): return self.paths.state_root/"registry.json"
    @property
    def package_ledger_path(self): return self.paths.state_root/"packages.json"
    def source_dir(self,p): return self.paths.data_root/"sources"/p
    def payload_dir(self,p): return self.paths.data_root/"profiles"/p/"payload"
    def registry(self): return _read(self.registry_path,{"active":None,"pending":None,"previous":None,"profiles":{}})
    def save_registry(self,d): _write(self.registry_path,d)

    def specs(self) -> dict[str,ProfileSpec]:
        return {s.id:s for s in (load_profile(p) for p in sorted(self.paths.profile_defs.glob("*.json")))}
    def spec(self,p) -> ProfileSpec:
        try: return self.specs()[p]
        except KeyError as e: raise ProfileError(f"unknown curated profile: {p}") from e

    @staticmethod
    def _git(cwd:Path,*args:str)->str:
        r=subprocess.run(["git",*args],cwd=cwd,text=True,capture_output=True)
        if r.returncode: raise ProfileError(f"git {' '.join(args)} failed: {r.stderr.strip()}")
        return r.stdout

    def fetch(self,p,refresh=False):
        s=self.spec(p); d=self.source_dir(p)
        if d.exists() and not refresh: return {"profile":p,"source":str(d),"commit":self._git(d,"rev-parse","HEAD").strip(),"reused":True}
        if d.exists(): shutil.rmtree(d)
        d.parent.mkdir(parents=True,exist_ok=True)
        r=subprocess.run(["git","clone","--depth","1","--branch",s.ref,"--",s.repository,str(d)],text=True,capture_output=True)
        if r.returncode: raise ProfileError(f"git clone failed: {(r.stderr or r.stdout).strip()}")
        return {"profile":p,"source":str(d),"commit":self._git(d,"rev-parse","HEAD").strip(),"reused":False}

    def audit(self,p,use_codex=False):
        s=self.spec(p); root=self.source_dir(p)
        if not root.is_dir(): raise ProfileError(f"{p} has not been fetched; run desktopctl fetch {p}")
        full=scan_tree(root); prefixes=tuple(m.source.rstrip("/") for m in s.config)
        inc=[]; exc=[]
        for f in full["findings"]:
            path=str(f.get("path","")); (inc if any(path==x or path.startswith(x+"/") for x in prefixes) else exc).append(f)
        eff=dict(full); eff["findings"]=inc; eff["blockers"]=sum(x["severity"]=="block" for x in inc); eff["warnings"]=sum(x["severity"]=="warn" for x in inc)
        eff["risk_score"]=min(100,eff["blockers"]*35+eff["warnings"]*3); eff["verdict"]="blocked" if eff["blockers"] else ("review" if eff["warnings"] else "pass")
        out={"profile":p,"static":eff,"source_scan":{k:full[k] for k in ("verdict","risk_score","blockers","warnings")},"excluded_findings":exc}
        if use_codex: out["codex"]=codex_review(s,eff)
        return out

    def _packages(self,s:ProfileSpec,root:Path):
        official=list(s.official_packages); aur=list(s.aur_packages)
        for rel in s.package_files:
            f=root/rel
            if not f.is_file(): raise ProfileError(f"declared package manifest missing: {rel}")
            for x in _manifest(f):
                if x not in official: official.append(x)
        for rel in s.aur_package_files:
            f=root/rel
            if not f.is_file(): raise ProfileError(f"declared AUR manifest missing: {rel}")
            for x in _manifest(f):
                if x not in aur: aur.append(x)
        return official,aur

    @staticmethod
    def _installed(pkg):
        if not shutil.which("pacman"): return False
        return subprocess.run(["pacman","-Q",pkg],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL).returncode==0

    def plan(self,p,use_codex=False):
        s=self.spec(p); root=self.source_dir(p)
        if not root.is_dir(): self.fetch(p)
        audit=self.audit(p,use_codex=use_codex); mappings=[]; missing=[]
        for m in s.config:
            exists=(root/m.source).exists(); mappings.append({"source":m.source,"target":m.target,"exists":exists})
            if not exists: missing.append(m.source)
        official,aur=self._packages(s,root); qs=shutil.which("qs") is not None
        mo=[x for x in official if not self._installed(x) and not(qs and x in PROVIDERS)]
        ma=[x for x in aur if not self._installed(x) and not(qs and x in PROVIDERS)]
        blocked=bool(audit["static"]["blockers"] or missing or audit.get("codex",{}).get("verdict")=="block")
        return {"profile":p,"name":s.name,"repository":s.repository,"ref":s.ref,"runtime":s.runtime,"capabilities":s.capabilities,"mappings":mappings,"protected":sorted(set(PROTECTED)|set(s.protected)),"packages":{"official":official,"aur":aur,"missing_official":mo,"missing_aur":ma,"quickshell_provider_reused":qs and bool(PROVIDERS.intersection(official+aur))},"audit":audit,"blocked":blocked,"notes":s.notes}

    def prepare(self,p,use_codex=False,force_review=False):
        plan=self.plan(p,use_codex=use_codex)
        if plan["blocked"]: raise ProfileError("profile is blocked by safety checks; inspect desktopctl plan output")
        if plan["audit"]["static"]["warnings"] and not force_review: raise ProfileError("profile has static warnings; re-run prepare with --accept-review after reading the plan")
        s=self.spec(p); root=self.source_dir(p); payload=self.payload_dir(p); tmp=payload.with_name("payload.new")
        shutil.rmtree(tmp,ignore_errors=True); (tmp/"config").mkdir(parents=True)
        for m in s.config:
            src=root/m.source; dst=tmp/"config"/m.target
            if src.is_dir(): shutil.copytree(src,dst,symlinks=True)
            else: dst.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(src,dst)
        scan=scan_tree(tmp)
        if scan["blockers"]: shutil.rmtree(tmp,ignore_errors=True); raise ProfileError("curated payload contains a hard blocker; refusing to stage")
        lock={"profile":p,"repository":s.repository,"ref":s.ref,"commit":self._git(root,"rev-parse","HEAD").strip(),"prepared_at":_now(),"scan":scan}; _write(tmp/"profile-lock.json",lock)
        payload.parent.mkdir(parents=True,exist_ok=True); old=payload.with_name("payload.old"); shutil.rmtree(old,ignore_errors=True)
        if payload.exists(): payload.rename(old)
        tmp.rename(payload); shutil.rmtree(old,ignore_errors=True)
        reg=self.registry(); reg.setdefault("profiles",{})[p]={"prepared":True,"commit":lock["commit"],"prepared_at":lock["prepared_at"]}; self.save_registry(reg); return lock

    @staticmethod
    def _query_installed():
        if not shutil.which("pacman"): return []
        r=subprocess.run(["pacman","-Qq"],text=True,capture_output=True); return [x for x in r.stdout.splitlines() if x]

    def install_packages(self,p,apply=False):
        plan=self.plan(p); missing=list(plan["packages"]["missing_official"]); aur=list(plan["packages"]["missing_aur"])
        out={"missing_official":missing,"missing_aur":aur,"installed":[],"apply":apply}
        if not apply or not missing: return out
        if os.geteuid()==0: raise ProfileError("do not run desktopctl as root")
        sim=subprocess.run(["pacman","-S","--needed","--print-format","%n",*missing],text=True,capture_output=True)
        out["simulation"]=[x for x in sim.stdout.splitlines() if x.strip()]
        if sim.returncode: raise ProfileError(f"pacman transaction simulation failed ({sim.returncode}): {sim.stderr.strip()[:1000]}")
        before=set(self._query_installed()); r=subprocess.run(["sudo","pacman","-S","--needed",*missing])
        if r.returncode: raise ProfileError(f"pacman dependency install failed ({r.returncode})")
        after=set(self._query_installed()); added=sorted(after-before); out["installed"]=added; ledger=_read(self.package_ledger_path,{"packages":{}})
        # Record the complete transaction delta, including transitive dependencies,
        # so profile removal never leaves packages behind merely because they were
        # pulled indirectly by pacman.
        for pkg in added:
            e=ledger["packages"].setdefault(pkg,{"preexisting":False,"installed_by_manager":True,"owners":[]})
            if p not in e["owners"]: e["owners"].append(p)
        # Also record requested packages that existed before this profile. Those
        # are user/pre-existing owned and therefore never eligible for removal.
        for pkg in set(plan["packages"]["official"])-set(added):
            e=ledger["packages"].setdefault(pkg,{"preexisting":True,"installed_by_manager":False,"owners":[]})
            if p not in e["owners"]: e["owners"].append(p)
        _write(self.package_ledger_path,ledger); return out

    def capture_monitors(self):
        if not(shutil.which("hyprctl") and os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")): return []
        r=subprocess.run(["hyprctl","monitors","-j"],text=True,capture_output=True)
        try: data=json.loads(r.stdout) if r.returncode==0 else []
        except json.JSONDecodeError: data=[]
        keys=("name","width","height","refreshRate","x","y","scale")
        return [{k:i.get(k) for k in keys} for i in data]

    def select(self,p):
        if p!="arch-wm":
            self.spec(p)
            if not self.payload_dir(p).is_dir(): raise ProfileError(f"{p} is not prepared")
        reg=self.registry(); reg["pending"]=p; reg["monitor_snapshot"]=self.capture_monitors(); self.save_registry(reg)
        return {"pending":p,"monitors_captured":len(reg["monitor_snapshot"])}

    def _capture_arch(self):
        payload=self.payload_dir("arch-wm")
        if payload.is_dir(): return
        (payload/"config").mkdir(parents=True)
        for n in MANAGED:
            src=self.paths.config/n; dst=payload/"config"/n
            if src.exists() and not src.is_symlink(): shutil.copytree(src,dst,symlinks=True) if src.is_dir() else shutil.copy2(src,dst)
        reg=self.registry(); reg.setdefault("profiles",{})["arch-wm"]={"prepared":True,"captured_at":_now(),"local_snapshot":True}; self.save_registry(reg)

    # Compatibility names kept explicit for tests and the future Qt client.
    def _ensure_arch_wm_snapshot(self): self._capture_arch()
    def _apply_monitor_snapshot(self,p,monitors): self._monitors(p,monitors)

    def _backup(self):
        b=self.paths.data_root/"backups"/_now(); (b/"config").mkdir(parents=True)
        for n in MANAGED:
            src=self.paths.config/n
            if not(src.exists() or src.is_symlink()): continue
            dst=b/"config"/n
            if src.is_symlink(): dst.write_text(f"SYMLINK->{os.readlink(src)}\n")
            elif src.is_dir(): shutil.copytree(src,dst,symlinks=True)
            else: shutil.copy2(src,dst)
        return b

    def _monitors(self,p,monitors):
        if p=="arch-wm" or not monitors: return
        s=self.spec(p); hypr=self.payload_dir(p)/"config/hypr"
        if not hypr.is_dir(): return
        lines=["-- Managed monitor safety overlay generated by desktopctl."]
        for m in monitors:
            if not(m.get("name") and m.get("width") and m.get("height")): continue
            mode=f'{int(m["width"])}x{int(m["height"])}'; rr=m.get("refreshRate")
            if rr: mode+=f'@{float(rr):.3f}'.rstrip("0").rstrip(".")
            pos=f'{int(m.get("x") or 0)}x{int(m.get("y") or 0)}'; scale=float(m.get("scale") or 1)
            lines.append(f'hl.monitor({{ output = {json.dumps(str(m["name"]))}, mode = {json.dumps(mode)}, position = {json.dumps(pos)}, scale = {scale:g} }})')
        overlay="\n".join(lines)+"\n"
        if s.monitor_adapter=="mainstream-monitors-lua": (hypr/"monitors.lua").write_text(overlay)
        elif s.monitor_adapter=="tsugumori-user-lua":
            f=hypr/"user.lua"; old=f.read_text() if f.is_file() else ""; begin="-- desktopctl monitor overlay: begin"; end="-- desktopctl monitor overlay: end"
            if begin in old and end in old: old=(old.split(begin,1)[0].rstrip()+"\n"+old.split(end,1)[1].lstrip()).strip()+"\n"
            f.write_text(old.rstrip()+"\n\n"+begin+"\n"+overlay+end+"\n")

    def _theme(self,suspend):
        f=self.paths.config/"theme-engine/targets.conf"; saved=self.paths.state_root/"theme-targets.saved"
        if suspend:
            if not f.is_file() or saved.exists(): return
            text=f.read_text(); saved.write_text(text); out=[]
            for raw in text.splitlines():
                value=raw.split("#",1)[0].strip().split("=",1)[0].strip()
                if value not in {"hypr","hyprlock","wallpaper"}: out.append(raw)
            f.write_text("\n".join(out)+"\n")
        elif saved.is_file(): f.parent.mkdir(parents=True,exist_ok=True); f.write_text(saved.read_text()); saved.unlink()

    def _links(self,p):
        cfg=self.payload_dir(p)/"config"
        if not cfg.is_dir(): raise ProfileError(f"profile payload is missing: {p}")
        for n in MANAGED:
            target=self.paths.config/n; source=cfg/n
            if target.exists() or target.is_symlink(): shutil.rmtree(target) if target.is_dir() and not target.is_symlink() else target.unlink()
            if source.exists(): target.symlink_to(source,target_is_directory=source.is_dir())

    def activate_pending(self,apply=False):
        if os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"): raise ProfileError("refusing to swap Hyprland config inside a running Hyprland session; log out and run `desktopctl launch --apply` from a TTY")
        reg=self.registry(); p=reg.get("pending") or reg.get("active") or "arch-wm"
        if not apply: return {"would_activate":p,"apply":False}
        self._capture_arch()
        if p!="arch-wm" and not self.payload_dir(p).is_dir(): raise ProfileError(f"profile is not prepared: {p}")
        backup=self._backup(); journal={"started_at":_now(),"from":reg.get("active"),"to":p,"backup":str(backup),"status":"switching"}; _write(self.paths.state_root/"switch-journal.json",journal)
        self._theme(p!="arch-wm"); self._monitors(p,reg.get("monitor_snapshot") or []); self._links(p)
        reg["previous"]=reg.get("active"); reg["active"]=p; reg["pending"]=None; self.save_registry(reg); journal["status"]="committed"; _write(self.paths.state_root/"switch-journal.json",journal)
        return {"active":p,"backup":str(backup),"apply":True}

    def launch(self,apply=False):
        self.activate_pending(apply=apply)
        if not apply: return 0
        exe=shutil.which("Hyprland") or shutil.which("hyprland")
        if not exe: raise ProfileError("Hyprland executable not found")
        os.execv(exe,[exe]); return 0

    def status(self):
        r=self.registry(); return {"active":r.get("active"),"pending":r.get("pending"),"previous":r.get("previous"),"prepared":sorted(k for k,v in r.get("profiles",{}).items() if v.get("prepared")),"theme_hypr_targets_suspended":(self.paths.state_root/"theme-targets.saved").exists()}

    def remove(self,p,apply=False,remove_packages=False):
        if p=="arch-wm": raise ProfileError("the captured Arch-WM recovery profile cannot be removed by this command")
        reg=self.registry()
        if p in {reg.get("active"),reg.get("pending")}: raise ProfileError("cannot remove an active or pending profile; select arch-wm first")
        out={"profile":p,"removed":False,"packages_removed":[]}
        if not apply: return out
        shutil.rmtree(self.payload_dir(p).parent,ignore_errors=True); shutil.rmtree(self.source_dir(p),ignore_errors=True); reg.get("profiles",{}).pop(p,None); self.save_registry(reg)
        if remove_packages:
            ledger=_read(self.package_ledger_path,{"packages":{}}); candidates=[]
            for pkg,e in ledger.get("packages",{}).items():
                e["owners"]=[o for o in e.get("owners",[]) if o!=p]
                if e.get("installed_by_manager") and not e.get("preexisting") and not e["owners"]: candidates.append(pkg)
            if candidates:
                r=subprocess.run(["sudo","pacman","-R","--noconfirm",*candidates])
                if r.returncode==0:
                    out["packages_removed"]=candidates
                    for x in candidates: ledger["packages"].pop(x,None)
            _write(self.package_ledger_path,ledger)
        out["removed"]=True; return out

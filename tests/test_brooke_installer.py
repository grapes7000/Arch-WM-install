import hashlib
import io
import json
import os
from pathlib import Path
import subprocess
import tarfile
import tempfile
import unittest
from unittest.mock import patch
from installer import brooke, entry, runtime
ROOT=Path(__file__).resolve().parents[1]

class BrookeInstallerTests(unittest.TestCase):
    def context(self,home,dry=False):
        with patch.object(Path,'home',return_value=home),patch.dict(os.environ,{'XDG_CONFIG_HOME':str(home/'.config'),'XDG_DATA_HOME':str(home/'.local/share'),'XDG_STATE_HOME':str(home/'.local/state')}):
            ctx=runtime.Context(ROOT,runtime.Options(command='install',profile='brooke',dry_run=dry,assets_dir=str(home/'assets')))
        ctx.commands=[]
        ctx.run=lambda command,**kwargs:(ctx.commands.append(list(command)) or subprocess.CompletedProcess(command,0,'',''))
        return ctx
    def archive(self,path,entries):
        path.parent.mkdir(parents=True,exist_ok=True)
        with tarfile.open(path,'w:xz') as t:
            for name,data in entries.items():
                member=tarfile.TarInfo(name);member.size=len(data);t.addfile(member,io.BytesIO(data))
        return hashlib.sha256(path.read_bytes()).hexdigest()
    def test_profile_is_complete_and_has_no_private_ssh_dotfiles(self):
        with tempfile.TemporaryDirectory() as tmp:
            ctx=self.context(Path(tmp),True)
            names=runtime.packages(ctx)
            for package in ['hyprland','quickshell','github-cli','greetd','greetd-regreet','thunar','krita','fontconfig','grim','slurp']:
                self.assertIn(package,names)
            self.assertFalse(ctx.profile.get('dotfiles'))
            opts=runtime.make_options(runtime.parser().parse_args(['install','--profile','brooke','--assets-dir','/example']))
            self.assertEqual(opts.assets_dir,'/example')
    def test_stage_order_and_patch_is_idempotent(self):
        before=runtime.STAGES
        try:
            entry.patch_runtime();entry.patch_runtime()
            names=[s.name for s in runtime.STAGES]
            self.assertEqual(names.count('65-brooke'),1)
            self.assertLess(names.index('60-quickshell'),names.index('65-brooke'))
            self.assertLess(names.index('65-brooke'),names.index('75-login'))
        finally:runtime.STAGES=before
    def test_default_shell_script_selects_brooke_but_accepts_other_profiles(self):
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp)/'python';p.write_text('#!/bin/sh\nprintf "%s\\n" "$@"\n');p.chmod(0o755)
            env=dict(os.environ,PATH=tmp+':'+os.environ['PATH'])
            first=subprocess.run(['bash',str(ROOT/'install.sh'),'--dry-run'],env=env,text=True,capture_output=True,check=True)
            self.assertIn('--profile\nbrooke\n',first.stdout)
            second=subprocess.run(['bash',str(ROOT/'install.sh'),'--profile','desktop','--dry-run'],env=env,text=True,capture_output=True,check=True)
            self.assertNotIn('\nbrooke\n',second.stdout)
    def test_fresh_appearance_install_check_and_owned_rollback(self):
        with tempfile.TemporaryDirectory() as tmp:
            home=Path(tmp);ctx=self.context(home)
            archive=home/'assets/appearance.tar.xz'
            sha=self.archive(archive,{'assets.json':json.dumps({'wallpaper':'@DATA@/assets/wallpaper.jpeg','launchers':[{'name':'Screenshot','command':['hyprshot']}]}).encode(),'assets/wallpaper.jpeg':b'wallpaper','themes/Chicago95-PinkPanel/index.theme':b'theme','icons/Chicago95/index.theme':b'icons','fonts/test.ttf':b'font'})
            with patch.object(brooke,'lock',return_value={'sha256':sha,'repository':'owner/private'}):
                self.assertFalse(brooke.check(ctx));brooke.apply(ctx);self.assertTrue(brooke.check(ctx))
                model=json.loads((ctx.data/'brooke-desktop/assets.json').read_text())
                self.assertTrue(model['wallpaper'].startswith(ctx.data.as_uri()))
                self.assertEqual(model['launchers'][0]['command'],['brooke-screenshot'])
                self.assertTrue((ctx.config/'hypr/generated/theme.lua').is_file())
                self.assertTrue((ctx.config/'dunst/dunstrc').is_file())
            ctx.state.restore()
            self.assertFalse((ctx.data/'brooke-desktop/assets.json').exists())
    def test_brooke_shell_and_hyprland_payload_checks_survive_reinstall(self):
        with tempfile.TemporaryDirectory() as tmp:
            ctx=self.context(Path(tmp));brooke.hypr_apply(ctx);brooke.shell_apply(ctx)
            self.assertTrue(brooke.hypr_check(ctx));self.assertTrue(entry.shell_check(ctx))
            self.assertIn('QS_ICON_THEME = "Chicago95"',(ctx.config/'hypr/conf/env.lua').read_text())
            self.assertIn('require("conf.brooke")',(ctx.config/'hypr/hyprland.lua').read_text())
            self.assertNotIn('HomepageSurface {}',(ctx.config/'quickshell/arch-wm/shell.qml').read_text())
            ctx.state.restore()
            self.assertFalse((ctx.config/'quickshell/arch-wm').exists())
            self.assertFalse((ctx.config/'hypr').exists())
    def test_split_archive_reassembly_and_checksum(self):
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp);(p/'one').write_bytes(b'abc');(p/'two').write_bytes(b'def');(p/'payload.json').write_text(json.dumps({'parts':['one','two']}))
            self.assertEqual(brooke.assemble_archive(p).read_bytes(),b'abcdef')
    def test_unsafe_and_mismatched_archives_are_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            archive=Path(tmp)/'appearance.tar.xz';sha=self.archive(archive,{'assets.json':b'{}','../escape':b'bad'})
            with self.assertRaises(runtime.InstallError):brooke.validate_archive(archive,sha)
            with self.assertRaises(runtime.InstallError):brooke.validate_archive(archive,'0'*64)
    def test_no_change_during_dry_run(self):
        with tempfile.TemporaryDirectory() as tmp:
            home=Path(tmp);ctx=self.context(home,True)
            # A supplied path is not required to exist when merely planning.
            with patch.object(brooke,'assets_fetch',return_value=home/'future-assets'):
                brooke.apply(ctx)
            self.assertFalse((home/'.config').exists())
            self.assertFalse((home/'.local').exists())
if __name__=='__main__':unittest.main()

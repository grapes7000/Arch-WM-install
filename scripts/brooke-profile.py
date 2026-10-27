#!/usr/bin/env python3
"""Private, opt-in importer; dry-run by default. Never runs exported code."""
import argparse, configparser, hashlib, io, json, os, shutil, tempfile
from pathlib import Path
from datetime import datetime, timezone
import xml.etree.ElementTree as ET
REPO = Path(__file__).resolve().parents[1]
def digest(p):
    with p.open('rb') as f: return hashlib.file_digest(f,'sha256').hexdigest()
def safe_files(folder):
    if not folder.exists(): return
    for p in sorted(folder.rglob('*')):
        if p.is_file():
            if not p.resolve().is_relative_to(folder.resolve()): raise ValueError(f'External symlink: {p}')
            yield p,p.relative_to(folder)
def build(export,home,krita=False):
    roots=list((export/'assets/rootfs/home').iterdir())
    if len(roots)!=1: raise ValueError('Expected one exported home')
    src=roots[0]; rootfs=export/'assets/rootfs'; data=home/'.local/share/brooke-desktop'
    files={};gaps=[]
    def add(target,source): files[str(target.relative_to(home))]=source.read_bytes()
    def tree(source,target):
        for p,rel in safe_files(source): add(target/rel,p)
    tree(REPO/'modules/shell',home/'.config/quickshell/brooke')
    files['.config/quickshell/brooke/shell.qml']=(REPO/'modules/shell/brooke.qml').read_bytes()
    for name in ['Chicago95-PinkPanel','Chicago95-Tall']: tree(src/'.themes'/name,home/'.local/share/themes'/name)
    for name in ['Chicago95','BrookeCursor','BrookeCursor-48']:
        origin=next((p for p in [src/'.icons'/name,src/'.local/share/icons'/name] if p.exists()),None)
        if origin: tree(origin,home/'.local/share/icons'/name)
        else:gaps.append('Missing theme: '+name)
    tree(src/'.fonts',home/'.local/share/fonts/brooke-legacy')
    tree(src/'.local/share/fonts',home/'.local/share/fonts/brooke')
    panel=src/'Pictures/themes/panel-assets';tree(panel,data/'panel-assets')
    wallpapers=list((src/'Pictures').rglob('current desktop-background.jpeg'))
    if wallpapers:add(data/'wallpaper.jpeg',wallpapers[0])
    else:gaps.append('Missing active wallpaper')
    model={'wallpaper':(data/'wallpaper.jpeg').as_uri(),'stripes':(data/'panel-assets/striped-panel.jpg.jpg').as_uri(),'launchers':[],'topLaunchers':[]}
    commands={'thunar':['thunar'],'kitty':['kitty'],'firefox':['firefox'],'google chrome':['google-chrome-stable'],'krita':['krita'],'gimp':['gimp'],'gnu image manipulation':['gimp'],'floorp':['flatpak','run','one.ablaze.floorp'],'bluebubbles':['flatpak','run','app.bluebubbles.BlueBubbles'],'screenshot':['hyprshot','-m','region'],'spotify':['spotify'],'signal':['signal-desktop'],'localsend':['localsend'],'kde connect':['kdeconnect-app'],'virtual machine manager':['virt-manager'],'the sims':['steam','steam://rungameid/1222670'],'xfce terminal':['kitty'],'notes':['sticky'],'openrgb':['openrgb']}
    urls={'chatgpt':'https://chatgpt.com','gmail':'https://mail.google.com','instagram':'https://www.instagram.com','pinterest':'https://www.pinterest.com','spacehey':'https://spacehey.com','picsart':'https://picsart.com'}
    xml=src/'.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml'
    if xml.exists():
        doc=ET.parse(xml)
        for panel_name,key in [('panel-1','topLaunchers'),('panel-0','launchers')]:
            element=doc.find(f".//property[@name='{panel_name}']/property[@name='plugin-ids']")
            for value in [] if element is None else element.findall('value'):
                folder=src/('.config/xfce4/panel/launcher-'+value.get('value'))
                for desktop in sorted(folder.glob('*.desktop')):
                    cp=configparser.ConfigParser(interpolation=None,strict=False);cp.read(desktop);entry=cp['Desktop Entry']
                    name=entry.get('Name',desktop.stem);icon=entry.get('Icon','application-x-executable')
                    command=next((v for k,v in commands.items() if k in name.lower()),[])
                    for k,url in urls.items():
                        if k in name.lower():command=['xdg-open',url]
                    if icon.startswith('/'):
                        p=rootfs/icon.lstrip('/')
                        if not p.exists():p=panel/Path(icon).name
                        if p.is_file():
                            dest=data/'launcher-icons'/(hashlib.sha256(str(p.relative_to(rootfs)).encode()).hexdigest()[:12]+p.suffix)
                            add(dest,p);icon=dest.as_uri()
                        else:icon='application-x-executable'
                    model[key].append({'name':name,'icon':icon,'command':command})
                    if not command:gaps.append('Needs portable command: '+name)
        for p in doc.findall(".//property[@name='button-icon']"):
            origin=rootfs/p.get('value','').lstrip('/')
            if origin.is_file():add(data/'star.png',origin);model['star']=(data/'star.png').as_uri()
    if not model['launchers']:
        gaps.append('No launcher order found; fallback used')
        model['launchers']=[{'name':k.title(),'icon':k,'command':v} for k,v in list(commands.items())[:7]]
    files['.local/share/brooke-desktop/assets.json']=(json.dumps(model,indent=2)+'\n').encode()
    for name in ['theme','ui-style']:files[f'.config/theme-engine/generated/{name}.json']=(REPO/f'profiles/brooke/{name}.json').read_bytes()
    for version in ['3.0','4.0']:
        path=home/f'.config/gtk-{version}/settings.ini';cp=configparser.ConfigParser(interpolation=None)
        if path.exists():cp.read(path)
        if not cp.has_section('Settings'):cp.add_section('Settings')
        cp['Settings'].update({'gtk-theme-name':'Chicago95-PinkPanel','gtk-icon-theme-name':'Chicago95','gtk-font-name':'BlackChancery 16','gtk-cursor-theme-name':'BrookeCursor-48','gtk-cursor-theme-size':'48'})
        out=io.StringIO();cp.write(out);files[str(path.relative_to(home))]=out.getvalue().encode()
    css=src/'.config/gtk-3.0/gtk.css'
    if css.exists():
        add(data/'reference/gtk.css',css)
        if '/home/' not in css.read_text() and '@import' not in css.read_text():add(home/'.config/gtk-3.0/gtk.css',css)
        else:gaps.append('GTK CSS retained as reference; imports need adapting')
    if krita:
        for p,rel in safe_files(src/'.local/share/krita'):
            if 'pykrita' not in rel.parts and p.suffix not in ['.so','.sqlite']:add(data/'krita-test/share/krita'/rel,p)
        p=src/'.config/kritarc'
        if p.exists():files['.local/share/brooke-desktop/krita-test/config/kritarc']=('\n'.join(s for s in p.read_text().splitlines() if not s.startswith('ResourceDirectory='))+'\n').encode()
    files['.local/share/brooke-desktop/IMPORT-GAPS.txt']=('\n'.join(gaps)+'\n').encode()
    files['.config/hypr/brooke.lua']=(REPO/'modules/hyprland/config/conf/brooke.lua').read_bytes()
    files['.local/share/brooke-desktop/dunstrc']=(REPO/'profiles/brooke/dunstrc').read_bytes()
    files['.local/share/brooke-desktop/hyprpaper.conf']=(f'preload = {data}/wallpaper.jpeg\nwallpaper = ,{data}/wallpaper.jpeg\n').encode()
    return files,gaps

def atomic(path,content):
    path.parent.mkdir(parents=True,exist_ok=True);fd,name=tempfile.mkstemp(dir=path.parent)
    try:
        with os.fdopen(fd,'wb') as f:f.write(content)
        os.replace(name,path)
    finally:
        if os.path.exists(name):os.unlink(name)
def apply(files,home):
    state=home/'.local/state/brooke-desktop'/datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S.%fZ');records=[]
    # Check every target before the first write.
    for rel in files:
        p=home/rel
        if p.is_symlink() or not p.resolve().is_relative_to(home.resolve()):raise ValueError('Unsafe destination: '+rel)
    for rel,content in files.items():
        p=home/rel
        if p.is_file() and p.read_bytes()==content:continue
        backup=state/'backup'/rel
        if p.exists():backup.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,backup)
        records.append({'path':rel,'existed':p.exists(),'sha256':hashlib.sha256(content).hexdigest()})
        state.mkdir(parents=True,exist_ok=True)
        with (state/'journal.jsonl').open('a') as journal:
            journal.write(json.dumps(records[-1])+'\n');journal.flush();os.fsync(journal.fileno())
        atomic(p,content)
    print(f'Changed {len(records)} files; rollback journal: {state}/journal.jsonl');return state

def rollback(state,home):
    records=[json.loads(line) for line in (state/'journal.jsonl').read_text().splitlines()]
    for rec in reversed(records):
        p=home/rec['path']
        if p.is_symlink() or not p.resolve().is_relative_to(home.resolve()):raise ValueError('Unsafe rollback path')
        if p.exists() and digest(p)!=rec['sha256']:print('SKIP modified file:',rec['path']);continue
        if rec['existed']:atomic(p,(state/'backup'/rec['path']).read_bytes())
        else:p.unlink(missing_ok=True)
def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--export',type=Path);ap.add_argument('--home',type=Path,default=Path.home());ap.add_argument('--apply',action='store_true');ap.add_argument('--krita',action='store_true',help='Stage isolated resources, never activate plugins');ap.add_argument('--rollback',type=Path)
    a=ap.parse_args();home=a.home.expanduser().resolve()
    if a.rollback:rollback(a.rollback,home);return
    if not a.export:ap.error('--export required')
    files,gaps=build(a.export.resolve(),home,a.krita)
    print(f'Plan: {len(files)} files, {sum(map(len,files.values()))//1048576} MiB')
    for gap in gaps:print('NOTE:',gap)
    if a.apply:apply(files,home)
    else:print('Dry run only; add --apply to write. No settings changed.')
if __name__=='__main__':main()

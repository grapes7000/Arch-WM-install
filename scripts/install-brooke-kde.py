#!/usr/bin/env python3
"""Install Brooke's Plasma 6 theme separately from the Hyprland installer."""
import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tarfile
import tempfile

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT))


def run(args):
    subprocess.run(list(map(str,args)),check=True)


class Backup:
    def __init__(self,path):
        self.path=path;self.records=[]
        path.mkdir(parents=True,exist_ok=True)
    def remember(self,target):
        if any(x['target']==str(target) for x in self.records):return
        saved=self.path/str(len(self.records))
        exists=target.exists() or target.is_symlink()
        if exists:
            if target.is_symlink():saved.symlink_to(os.readlink(target))
            elif target.is_dir():shutil.copytree(target,saved,symlinks=True)
            else:shutil.copy2(target,saved)
        self.records.append({'target':str(target),'backup':str(saved) if exists else None})
        (self.path/'manifest.json').write_text(json.dumps(self.records,indent=2)+'\n')
    def install(self,source,target):
        self.remember(target);remove(target);target.parent.mkdir(parents=True,exist_ok=True)
        if source.is_dir():shutil.copytree(source,target)
        else:shutil.copy2(source,target)


def remove(path):
    if path.is_symlink() or path.is_file():path.unlink()
    elif path.exists():shutil.rmtree(path)


def restore(directory):
    for item in reversed(json.loads((directory/'manifest.json').read_text())):
        target=Path(item['target']);remove(target)
        if item['backup']:
            saved=Path(item['backup']);target.parent.mkdir(parents=True,exist_ok=True)
            if saved.is_symlink():target.symlink_to(os.readlink(saved))
            elif saved.is_dir():shutil.copytree(saved,target,symlinks=True)
            else:shutil.copy2(saved,target)
    print('Restored backup. Log out and back in to reload Plasma.')


def desktop_exec(command):
    # Desktop Entry Exec has its own quoting rules; it is not a shell command.
    def quote(arg):
        value=str(arg).replace('%','%%')
        for char in ['\\', '"', '`', '$']:
            value=value.replace(char,'\\'+char)
        return '"'+value+'"'
    return ' '.join(quote(arg) for arg in command)


def launcher_files(model,asset_root,which=shutil.which):
    from urllib.parse import unquote,urlparse
    result=[]
    for i,entry in enumerate(model.get('launchers',[])):
        command=entry.get('command')
        if not isinstance(command,list) or not command or not all(isinstance(a,str) for a in command):continue
        if not which(command[0]):
            print('Launcher application not installed:',entry.get('name',command[0]))
            continue
        icon=str(entry.get('icon','application-x-executable')).replace('@DATA@',asset_root.as_uri())
        if icon.startswith('file:'):icon=unquote(urlparse(icon).path)
        name=str(entry.get('name','Application')).replace('\n',' ').replace('\r',' ')
        icon=icon.replace('\n','').replace('\r','')
        filename=f'brooke-classic-launcher-{i}.desktop'
        content=f'[Desktop Entry]\nType=Application\nName={name}\nIcon={icon}\nExec={desktop_exec(command)}\nTerminal=false\nCategories=Utility;\n'
        result.append((filename,content))
    return result


def textured_panel(svg,texture):
    import base64,re
    encoded=base64.b64encode(texture).decode('ascii')
    pattern='<pattern id="stripes" width="128" height="32" patternUnits="userSpaceOnUse"><image width="128" height="32" preserveAspectRatio="none" xlink:href="data:image/jpeg;base64,'+encoded+'"/></pattern>'
    return re.sub(r'<pattern\b.*?</pattern>',lambda _:pattern,svg,flags=re.S).replace('<svg xmlns=', '<svg xmlns:xlink="http://www.w3.org/1999/xlink" xmlns=',1)


def install(args):
    from installer.brooke import assemble_archive, validate_archive
    if os.geteuid()==0:raise RuntimeError('Run as your regular desktop user, without sudo')
    home=Path.home();data=Path(os.environ.get('XDG_DATA_HOME',home/'.local/share'))
    config=Path(os.environ.get('XDG_CONFIG_HOME',home/'.config'))
    state=Path(os.environ.get('XDG_STATE_HOME',home/'.local/state'))/'brooke-kde'
    if args.rollback:
        restore(Path(args.rollback).expanduser().resolve());return
    required=['fc-cache']+(['plasma-apply-lookandfeel','plasma-apply-colorscheme','plasma-apply-desktoptheme','kwriteconfig6'] if args.apply else [])
    for name in required:
        if not shutil.which(name):raise RuntimeError('Missing command: '+name)
    if args.apply and 'KDE' not in os.environ.get('XDG_CURRENT_DESKTOP','').upper():
        raise RuntimeError('Log into Plasma before using --apply')
    lock=json.loads((ROOT/'profiles/brooke/assets-lock.json').read_text())
    if args.assets_dir:source=Path(args.assets_dir).expanduser().resolve()
    else:
        if not shutil.which('gh'):raise RuntimeError('Install github-cli and run gh auth login first')
        run(['gh','auth','status','--hostname','github.com'])
        run(['gh','auth','setup-git','--hostname','github.com'])
        # Separate cache so this never switches another installer's checkout.
        source=data/'brooke-kde/asset-checkout'
        if not (source/'.git').is_dir():
            source.parent.mkdir(parents=True,exist_ok=True)
            run(['gh','repo','clone',lock['repository'],source,'--','--depth','1'])
        run(['git','-C',source,'fetch','--depth','1','origin',lock['revision']])
        run(['git','-C',source,'checkout','--detach','FETCH_HEAD'])
    archive=assemble_archive(source);validate_archive(archive,lock['sha256'])
    stamp=datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S.%fZ')
    backup=Backup(state/'backups'/stamp)
    print('Backup:',backup.path)
    try:
        with tempfile.TemporaryDirectory(prefix='brooke-kde-') as tmp:
            folder=Path(tmp)
            with tarfile.open(archive,'r:xz') as tar:tar.extractall(folder,filter='data')
            wallpaper=folder/'assets/wallpaper.jpeg'
            if not wallpaper.is_file():raise RuntimeError('Private payload has no wallpaper')
            # Every included theme/cursor/font unit is backed up independently.
            for category in ['themes','icons']:
                for item in (folder/category).iterdir():backup.install(item,data/category/item.name)
            backup.install(folder/'fonts',data/'fonts/brooke')
            backup.install(wallpaper,data/'wallpapers/BrookeClassic/wallpaper.jpeg')
            asset_root=data/'brooke-kde/private-assets'
            backup.install(folder/'assets',asset_root/'assets')
            model=json.loads((folder/'assets.json').read_text())
            launchers=launcher_files(model,asset_root)
            for filename,content in launchers:
                target=data/'applications'/filename;backup.remember(target)
                target.parent.mkdir(parents=True,exist_ok=True);target.write_text(content)
            pinned=['applications:'+name for name,_ in launchers]
            if not pinned:
                pinned=['applications:org.kde.dolphin.desktop','applications:systemsettings.desktop']
            package=ROOT/'profiles/brooke-kde'
            look=data/'plasma/look-and-feel/org.brooke.classic.desktop'
            backup.install(package/'look-and-feel',look)
            layout=look/'contents/layouts/org.kde.plasma.desktop-layout.js'
            layout.write_text(layout.read_text().replace('@WALLPAPER_URL@',json.dumps((data/'wallpapers/BrookeClassic/wallpaper.jpeg').as_uri())).replace('@LAUNCHERS@',json.dumps(pinned)))
            backup.install(package/'desktoptheme',data/'plasma/desktoptheme/brooke-classic')
            texture=(folder/'assets/stripes.jpg').read_bytes()
            style=data/'plasma/desktoptheme/brooke-classic'
            svg=textured_panel((style/'widgets/panel-background.svg').read_text(),texture)
            for variant in ['', 'opaque', 'translucent']:
                panel=style/variant/'widgets/panel-background.svg'
                panel.parent.mkdir(parents=True,exist_ok=True);panel.write_text(svg)
            backup.install(package/'BrookeClassic.colors',data/'color-schemes/BrookeClassic.colors')
        run(['fc-cache','-f'])
        if args.apply:
            for name in ['kdeglobals','kwinrc','kcminputrc','plasmarc','ksplashrc','kded5rc','kded6rc','plasma-org.kde.plasma.desktop-appletsrc']:
                backup.remember(config/name)
            # Defaults set colors/icons/decoration. The layout reset installs
            # Brooke's two panels and wallpaper using Plasma's own APIs.
            run(['plasma-apply-lookandfeel','--apply','org.brooke.classic.desktop','--resetLayout'])
            run(['plasma-apply-colorscheme','BrookeClassic'])
            run(['plasma-apply-desktoptheme','brooke-classic'])
            for key in ['font','menuFont','toolBarFont']:
                run(['kwriteconfig6','--file','kdeglobals','--group','General','--key',key,'BlackChancery,12,-1,5,50,0,0,0,0,0'])
            for version in ['3.0','4.0']:
                target=config/f'gtk-{version}/settings.ini';backup.remember(target)
                target.parent.mkdir(parents=True,exist_ok=True)
                import configparser
                settings=configparser.ConfigParser(interpolation=None);settings.optionxform=str
                if target.exists():settings.read(target)
                if not settings.has_section('Settings'):settings.add_section('Settings')
                for key,value in {'gtk-theme-name':'Chicago95-PinkPanel','gtk-icon-theme-name':'Chicago95','gtk-font-name':'BlackChancery 16','gtk-cursor-theme-name':'BrookeCursor-48','gtk-cursor-theme-size':'48'}.items():settings.set('Settings',key,value)
                with target.open('w') as f:settings.write(f)
        print('Installed Brooke Classic. '+('Log out and back into Plasma.' if args.apply else 'Select it in System Settings > Colors & Themes > Global Theme. Enable desktop layout to install the panels and wallpaper.'))
        print('Rollback: python scripts/install-brooke-kde.py --rollback '+str(backup.path))
    except Exception:
        print('Installation failed; restoring its changes.',file=sys.stderr);restore(backup.path);raise


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--assets-dir',help='existing private brooke-assets checkout; otherwise fetch pinned assets using gh')
    parser.add_argument('--apply',action='store_true',help='apply theme AND replace Plasma panels/layout, with backups')
    parser.add_argument('--rollback',help='backup directory printed by a prior installation; log out of Plasma before restoring')
    args=parser.parse_args()
    if args.rollback and args.apply:parser.error('--rollback and --apply cannot be combined')
    install(args)


if __name__=='__main__':main()

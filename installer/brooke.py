"""Fresh Arch/CachyOS integration for Brooke; appearance payload stays private."""
from __future__ import annotations
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import subprocess
import sys
import tarfile
import tempfile
from . import runtime

def enabled(ctx): return ctx.options.profile == 'brooke'
def lock(ctx): return runtime.json_file(ctx.root/'profiles/brooke/assets-lock.json')
def asset_source(ctx):
    configured = getattr(ctx.options,'assets_dir',None)
    return Path(configured).expanduser().resolve() if configured else ctx.data/'arch-wm-install/brooke-assets'

def validate_archive(archive,expected):
    with archive.open('rb') as handle: actual=hashlib.file_digest(handle,'sha256').hexdigest()
    if actual != expected: raise runtime.InstallError('Brooke appearance archive checksum mismatch')
    with tarfile.open(archive,'r:xz') as handle:
        members=handle.getmembers()
        total=0
        for member in members:
            path=PurePosixPath(member.name)
            if path.is_absolute() or '..' in path.parts or not member.isfile():
                raise runtime.InstallError('Unsafe appearance archive entry: '+member.name)
            if not path.parts or path.parts[0] not in {'themes','icons','fonts','assets','licenses','assets.json'}:
                raise runtime.InstallError('Unexpected appearance archive entry: '+member.name)
            total+=member.size
            if total>1024**3: raise runtime.InstallError('Appearance archive exceeds 1 GiB')
        if not any(m.name=='assets.json' for m in members):raise runtime.InstallError('Appearance archive has no asset model')
    return actual

def assemble_archive(source):
    archive=source/'appearance.tar.xz'
    if archive.is_file():return archive
    manifest=runtime.json_file(source/'payload.json')
    fd,name=tempfile.mkstemp(prefix='.appearance-',dir=source)
    try:
        with os.fdopen(fd,'wb') as out:
            for entry in manifest['parts']:
                path=source/entry
                if not path.resolve().is_relative_to(source.resolve()) or path.is_symlink():raise runtime.InstallError('Unsafe asset part path')
                with path.open('rb') as part:
                    import shutil
                    shutil.copyfileobj(part,out)
        os.replace(name,archive)
    finally:
        if os.path.exists(name):os.unlink(name)
    return archive

def assets_fetch(ctx):
    source=asset_source(ctx)
    expected=lock(ctx)
    if getattr(ctx.options,'assets_dir',None):
        if not (source/'appearance.tar.xz').is_file() and not (source/'payload.json').is_file():raise runtime.InstallError('--assets-dir must be the private asset checkout')
        return source
    repo=expected['repository']
    if ctx.options.dry_run:
        ctx.emit(f'  fetch private appearance repository {repo}; verify pinned SHA-256')
        return source
    if not ctx.has('gh'):raise runtime.InstallError('github-cli is required to fetch private Brooke assets')
    auth=subprocess.run(['gh','auth','status','--hostname','github.com'],capture_output=True,text=True)
    if auth.returncode:
        if ctx.options.noninteractive:
            raise runtime.InstallError('Private Brooke assets require GitHub authentication: run gh auth login, or pass --assets-dir')
        ctx.emit('GitHub sign-in is needed to download your private appearance assets.')
        ctx.run(['gh','auth','login','--hostname','github.com','--git-protocol','https','--web'])
    ctx.run(['gh','auth','setup-git','--hostname','github.com'])
    # Check existence/access before creating an owned checkout.
    ctx.run(['gh','repo','view',repo,'--json','nameWithOwner'],capture=True)
    if not (source/'.git').is_dir():
        ctx._own(source)
        source.parent.mkdir(parents=True,exist_ok=True)
        ctx.run(['gh','repo','clone',repo,str(source),'--','--depth','1'])
    ctx.run(['git','-C',str(source),'fetch','--depth','1','origin',expected.get('revision') or 'main'])
    ctx.run(['git','-C',str(source),'checkout','--detach','FETCH_HEAD'])
    return source

def check(ctx):
    if not enabled(ctx):return True
    marker=ctx.data/'brooke-desktop/installed.json'
    try:
        current=runtime.json_file(marker)
        return (current.get('sha256')==lock(ctx)['sha256'] and
            (ctx.data/'brooke-desktop/assets.json').is_file() and
            (ctx.data/'brooke-desktop/assets/wallpaper.jpeg').is_file() and
            (ctx.config/'theme-engine/generated/theme.json').read_bytes()==(ctx.root/'profiles/brooke/theme.json').read_bytes() and
            (ctx.config/'dunst/dunstrc').is_file())
    except (OSError,ValueError):return False

def appearance_files(ctx,staging):
    """Install directory-sized owned units, avoiding one state write per icon."""
    for category in ['themes','icons']:
        folder=staging/category
        if folder.exists():
            for item in sorted(folder.iterdir()):ctx.install(item,ctx.data/category/item.name)
    if (staging/'fonts').exists():ctx.install(staging/'fonts',ctx.data/'fonts/brooke')
    for name in ['assets','licenses']:
        if (staging/name).exists():ctx.install(staging/name,ctx.data/'brooke-desktop'/name)
    model=json.loads((staging/'assets.json').read_text().replace('@DATA@',(ctx.data/'brooke-desktop').as_uri()))
    for group in ['launchers','topLaunchers']:
        for entry in model.get(group,[]):
            if entry.get('command',[None])[0:1]==['hyprshot']:entry['command']=['brooke-screenshot']
    ctx.write(ctx.data/'brooke-desktop/assets.json',json.dumps(model,indent=2)+'\n')

def apply(ctx):
    if not enabled(ctx):return
    source=assets_fetch(ctx)
    if ctx.options.dry_run:
        ctx.emit('  install private themes/icons/fonts/wallpaper and launcher imagery')
    else:
        archive=assemble_archive(source);validate_archive(archive,lock(ctx)['sha256'])
        for name,expected in lock(ctx).get('files',{}).items():
            item=source/name
            if not item.resolve().is_relative_to(source.resolve()) or item.is_symlink():raise runtime.InstallError('Unsafe private asset file')
            with item.open('rb') as handle:actual=hashlib.file_digest(handle,'sha256').hexdigest()
            if actual!=expected:raise runtime.InstallError('Private asset checksum mismatch: '+name)
        with tempfile.TemporaryDirectory(prefix='brooke-appearance-') as tmp:
            staging=Path(tmp)
            with tarfile.open(archive,'r:xz') as tar:
                # validate_archive rejected links, special files and traversal.
                tar.extractall(staging,filter='data')
            appearance_files(ctx,staging)
    if not ctx.options.dry_run and (source/'krita/BrookiePink.colors').is_file():
        ctx.install(source/'krita/BrookiePink.colors',ctx.data/'krita/color-schemes/BrookiePink.colors')
        if not (ctx.config/'kritarc').exists():
            ctx.write(ctx.config/'kritarc','custom_font_size=15\ncustom_system_font=BlackChancery\nuse_custom_system_font=true\n\n[theme]\nTheme=BrookiePink\n')
    for name in ['theme','ui-style']:
        ctx.install(ctx.root/f'profiles/brooke/{name}.json',ctx.config/f'theme-engine/generated/{name}.json')
    ctx.install(ctx.root/'profiles/brooke/dunstrc',ctx.config/'dunst/dunstrc')
    wallpaper=ctx.data/'brooke-desktop/assets/wallpaper.jpeg'
    # Current hyprpaper supports per-output wallpaper blocks; empty monitor matches all.
    ctx.write(ctx.config/'hypr/hyprpaper.conf',f'splash = false\nipc = true\nwallpaper {{\n    monitor =\n    path = {wallpaper}\n    fit_mode = cover\n}}\n')
    for version in ['3.0','4.0']:
        ctx.write(ctx.config/f'gtk-{version}/settings.ini','[Settings]\ngtk-theme-name=Chicago95-PinkPanel\ngtk-icon-theme-name=Chicago95\ngtk-font-name=BlackChancery 16\ngtk-cursor-theme-name=BrookeCursor-48\ngtk-cursor-theme-size=48\n')
    ctx.write(ctx.config/'fontconfig/conf.d/99-brooke.conf','<?xml version="1.0"?><!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd"><fontconfig><match target="font"><edit name="hinting" mode="assign"><bool>false</bool></edit></match></fontconfig>\n')
    ctx.run(['fc-cache','-f'])
    # Adapt universal tokens using the repo's Hyprland-owned renderer.
    ctx.write(ctx.config/'hypr/generated/theme.lua',lua_appearance(ctx))
    ctx.write(ctx.data/'brooke-desktop/installed.json',json.dumps({'sha256':lock(ctx)['sha256'],'repository':lock(ctx)['repository']},indent=2)+'\n')

def verify(ctx):return ctx.options.dry_run or check(ctx)
def lua_appearance(ctx):
    theme=runtime.json_file(ctx.root/'profiles/brooke/theme.json');style=theme['style'];roles=theme['roles']
    color=roles['accent'].lstrip('#')+'ff'
    return ('-- Generated from the universal Brooke theme by the Hyprland adapter.\n'
        'hl.config({ general = { gaps_in = '+str(style['gaps']//2)+', gaps_out = '+str(style['gaps'])+', border_size = '+str(style['border_width'])+', col = { active_border = "rgba('+color+')", inactive_border = "rgba(606060ff)" } },\n'
        'decoration = { rounding = 0, active_opacity = 1.0, inactive_opacity = 1.0, blur = { enabled = false } } })\n')

def configure_hypr(ctx):
    ctx.install(ctx.root/'profiles/brooke/autostart.lua',ctx.config/'hypr/conf/autostart.lua')
    env=(ctx.root/'modules/hyprland/config/conf/env.lua').read_text().replace('kitty --class yazi -e yazi','thunar').replace('QS_ICON_THEME = "Papirus-Dark"','QS_ICON_THEME = "Chicago95"').replace('QT_WAYLAND_DISABLE_WINDOWDECORATION = "1"','QT_WAYLAND_DISABLE_WINDOWDECORATION = "0"')
    ctx.write(ctx.config/'hypr/conf/env.lua',env)
    text=(ctx.root/'modules/hyprland/config/hyprland.lua').read_text()
    ctx.write(ctx.config/'hypr/hyprland.lua',text+'\nrequire("conf.brooke")\n')
    ctx.install(ctx.root/'modules/hyprland/config/conf/brooke.lua',ctx.config/'hypr/conf/brooke.lua')
    ctx.write(ctx.home/'.local/bin/brooke-screenshot', '#!/bin/sh\nset -eu\nmkdir -p "$HOME/Pictures/Screenshots"\ngeometry=$(slurp) || exit 0\n[ -n "$geometry" ] || exit 0\nexec grim -g "$geometry" "$HOME/Pictures/Screenshots/screenshot-$(date +%Y%m%d-%H%M%S).png"\n',mode=0o755)

def hypr_check(ctx):
    try:
        return ((ctx.config/'hypr/conf/autostart.lua').read_bytes()==(ctx.root/'profiles/brooke/autostart.lua').read_bytes()
            and (ctx.config/'hypr/hyprland.lua').read_text()==(ctx.root/'modules/hyprland/config/hyprland.lua').read_text()+'\nrequire("conf.brooke")\n')
    except OSError:return False

def hypr_apply(ctx):
    runtime.hypr_apply(ctx)
    if enabled(ctx):configure_hypr(ctx)

def shell_apply(ctx):
    runtime.shell_apply(ctx)
    if enabled(ctx):ctx.install(ctx.root/'modules/shell/brooke.qml',ctx.config/'quickshell/arch-wm/shell.qml')

def shell_payload_matches(ctx):
    source=ctx.root/'modules/shell';target=ctx.config/'quickshell/arch-wm'
    if not target.is_dir():return False
    expected=set()
    for p in source.rglob('*'):
        if p.is_dir():continue
        rel=p.relative_to(source);expected.add(rel)
        original=source/'brooke.qml' if rel==Path('shell.qml') else p
        try:
            if (target/rel).read_bytes()!=original.read_bytes():return False
        except OSError:return False
    return all(p.relative_to(target) in expected for p in target.rglob('*') if p.is_file())

def validate(ctx):
    if ctx.options.dry_run:return
    version=ctx.run(['Hyprland','--version'],capture=True).stdout
    match=re.search(r'\b(\d+)\.(\d+)\.(\d+)',version)
    if not match or tuple(map(int,match.groups()))<(0,55,0):raise runtime.InstallError('Brooke profile requires Hyprland 0.55+ (Lua configuration). Update CachyOS first.')
    ctx.run(['luac','-p',str(ctx.config/'hypr/hyprland.lua')])
    ctx.run(['luac','-p',str(ctx.config/'hypr/conf/brooke.lua')])
    ctx.run(['luac','-p',str(ctx.config/'hypr/conf/autostart.lua')])
    # QML import/type warnings are reported separately from parser failures.
    linter=next((p for p in ['/usr/lib/qt6/bin/qmllint','/usr/bin/qmllint'] if Path(p).is_file()),None)
    if not linter:raise runtime.InstallError('Qt QML linter missing; install qt6-declarative')
    shell=ctx.config/'quickshell/arch-wm'
    for p in [shell/'shell.qml',*sorted((shell/'surfaces/brooke').glob('*.qml')),*sorted((shell/'widgets/brooke-panel').glob('*.qml'))]:
        result=ctx.run([linter,'-I','/usr/lib/qt6/qml',str(p)],capture=True,check=False)
        messages=(result.stderr or '')+'\n'+(result.stdout or '')
        if result.returncode not in (0,1) or re.search(r'(^|\n)Error:',messages):
            raise runtime.InstallError('QML validation failed: '+str(p)+'\n'+messages)
        if result.returncode:ctx.emit('  QML type/import warnings (runtime test still required): '+messages.strip())
    ctx.run(['Hyprland','--verify-config','--config',str(ctx.config/'hypr/hyprland.lua')])


def login_apply(ctx):
    if enabled(ctx):validate(ctx)
    runtime.login_apply(ctx)

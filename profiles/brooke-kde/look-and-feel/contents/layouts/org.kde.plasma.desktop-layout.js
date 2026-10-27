// Invoked only by Plasma's explicit Global Theme layout reset.
// The installer substitutes a JSON-escaped, machine-local wallpaper URL.
var wallpaper = @WALLPAPER_URL@;
{ // One panel pair on Plasma's default screen.
    var top = new Panel;
    top.location = 'top';
    top.height = 29;
    top.hiding = 'none';
    top.lengthMode = 'fill';
    top.floating = false;
    top.addWidget('org.kde.plasma.trash');
    top.addWidget('org.kde.plasma.panelspacer');
    var clock = top.addWidget('org.brooke.classic.clock');
    clock.currentConfigGroup = ['Appearance'];
    clock.writeConfig('showSeconds', 2);
    clock.writeConfig('showDate', false);
    top.addWidget('org.kde.plasma.systemtray');
    top.addWidget('org.kde.plasma.panelspacer');

    var bottom = new Panel;
    bottom.location = 'bottom';
    bottom.height = 41;
    bottom.hiding = 'none';
    bottom.lengthMode = 'fill';
    bottom.floating = false;
    var menu = bottom.addWidget('org.kde.plasma.kickoff');
    menu.currentConfigGroup = ['General'];
    menu.writeConfig('icon', 'brooke-star');
    var tasks = bottom.addWidget('org.kde.plasma.icontasks');
    tasks.currentConfigGroup = ['General'];
    tasks.writeConfig('launchers', @LAUNCHERS@);
    bottom.addWidget('org.kde.plasma.pager');
    bottom.addWidget('org.kde.plasma.showdesktop');
}
var ds = desktops();
for (var i = 0; i < ds.length; ++i) {
    ds[i].wallpaperPlugin = 'org.kde.image';
    ds[i].currentConfigGroup = ['Wallpaper', 'org.kde.image', 'General'];
    ds[i].writeConfig('Image', wallpaper);
    ds[i].writeConfig('FillMode', 2);
}

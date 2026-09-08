pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

// Thin wrapper over the StatusNotifierItem host that Quickshell provides.
//
// Applications that want a tray icon register themselves on D-Bus; this service
// exposes them as a plain list so widgets do not have to know about the
// underlying object model, and so tray items can be filtered by status without
// duplicating that logic per surface.
Singleton {
    id: root

    // Passive items are ones the application considers uninteresting right now.
    // Most bars hide them, but hiding by default would make some apps look like
    // they failed to start, so they are surfaced and merely de-emphasised.
    property bool showPassive: true

    readonly property var items: {
        const model = SystemTray.items;
        const all = model ? model.values : [];
        if (root.showPassive)
            return all;
        return all.filter(item => item && item.status !== Status.Passive);
    }

    readonly property int count: root.items.length
    readonly property bool hasItems: root.count > 0

    readonly property bool needsAttention: root.items.some(item => item && item.status === Status.NeedsAttention)

    function isPassive(item) {
        return !!item && item.status === Status.Passive;
    }

    function needsAttentionFor(item) {
        return !!item && item.status === Status.NeedsAttention;
    }

    function labelFor(item) {
        if (!item)
            return "";
        return item.tooltipTitle || item.title || item.id || "Tray item";
    }

    function descriptionFor(item) {
        if (!item)
            return "";
        // Tooltip descriptions are allowed to contain a limited HTML subset;
        // strip it so it can be rendered as plain text.
        const raw = String(item.tooltipDescription || "");
        return raw.replace(/<br\s*\/?>/gi, " ").replace(/<[^>]*>/g, "").trim();
    }

    // A left click is only meaningful when the item implements Activate. Items
    // that set onlyMenu expect the menu to be shown instead.
    function activate(item) {
        if (!item)
            return false;
        if (item.onlyMenu)
            return false;
        item.activate();
        return true;
    }

    function secondaryActivate(item) {
        if (!item || item.onlyMenu)
            return false;
        item.secondaryActivate();
        return true;
    }

    function scroll(item, delta, horizontal) {
        if (!item || delta === 0)
            return false;
        item.scroll(delta, !!horizontal);
        return true;
    }
}

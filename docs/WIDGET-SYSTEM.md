# Unified Widget System

## Principle

A widget is content, not a window. Surfaces own windows, security policy, placement and dimensions.

This separation lets one widget package run in multiple contexts without copying its logic.

## Package contract

```text
widgets/clock/
├── manifest.json
├── Widget.qml
├── Compact.qml       # optional specialized presentation
├── Expanded.qml      # optional specialized presentation
├── Settings.qml      # optional settings UI
└── README.md
```

`manifest.json` declares identity and compatibility:

```json
{
  "id": "clock",
  "name": "Clock",
  "entry": "Widget.qml",
  "surfaces": ["bar", "desktop", "lockscreen"],
  "variants": ["compact", "standard", "expanded"],
  "lockSafe": true,
  "services": ["time"],
  "capabilities": [],
  "constraints": {
    "compact": {"minWidth": 56, "minHeight": 24},
    "standard": {"minWidth": 160, "minHeight": 80}
  }
}
```

## Widget context

The host supplies a context object:

| Property | Meaning |
|---|---|
| `surface` | `bar`, `desktop`, or `lockscreen` |
| `instanceId` | Unique layout instance |
| `variant` | Requested presentation |
| `density` | Compactness scale |
| `locked` | Whether private/dangerous behavior is restricted |
| `availableWidth` | Host constraint |
| `availableHeight` | Host constraint |
| `capabilities` | Explicitly allowed actions |
| `settings` | Instance configuration |

Widgets may change presentation based on context, but they must not duplicate their data model by surface.

## Services

Services are singleton data providers under `modules/shell/services`.

Recommended services:

- Theme
- Hyprland
- Time
- MPRIS
- Audio
- Network
- Power
- SystemStats
- Notifications
- Weather
- Session

A service owns subscriptions and external processes. Widgets consume service properties and methods. Ten widgets must not start ten copies of the same monitor command.

## Surface hosts

### Bar

Uses `PanelWindow`, reserves exclusive space, and exposes start/center/end regions.

### Desktop

Uses a desktop-layer window below normal clients. It exposes named placement zones and supports dragging when edit mode is enabled.

### Lock screen

Uses a dedicated secure surface. Only `lockSafe` widgets load. Capabilities are intersected with a lock-screen allowlist.

## Swapping widgets

The source of truth is layout JSON. Moving the clock from the bar to the desktop means removing its instance from `bar.default.json` and adding an instance to `desktop.default.json`. No QML widget code changes.

A later layout editor may implement drag-and-drop, but it must write the same validated JSON format.

## Failure behavior

- Missing widget: render a small diagnostic placeholder in edit mode; omit it in normal mode.
- Invalid manifest: refuse registration and log the schema path.
- Service unavailable: widget shows a neutral unavailable state.
- Malformed layout: keep the last known-good layout.
- Theme parse error: retain the last known-good theme, then use built-in fallbacks.

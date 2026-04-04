# Configuration Examples

Complete examples for the two runtime JSON files generated/used by Overzicht.

## settings.json

Path: `~/.config/overzicht/settings.json`

```json
{
  "appearance": {
    "rounding": {
      "unsharpen": 0,
      "verysmall": 0,
      "small": 0,
      "normal": 0,
      "large": 0,
      "full": 0,
      "screenRounding": 0,
      "windowRounding": 0
    },
    "font": {
      "family": {
        "main": "sans-serif",
        "title": "sans-serif",
        "expressive": "sans-serif"
      },
      "pixelSize": {
        "smaller": 12,
        "small": 15,
        "normal": 16,
        "larger": 19,
        "huge": 22
      }
    },
    "animation": {
      "duration": {
        "elementMove": 500,
        "elementMoveEnter": 400,
        "elementMoveFast": 200
      }
    },
    "sizes": {
      "elevationMargin": 10
    }
  },
  "overview": {
    "rows": 2,
    "columns": 4,
    "scale": 0.12,
    "enable": true,
    "hideEmptyRows": false,
    "useWorkspaceMap": false,
    "workspaceMap": [],
    "orderRightLeft": false,
    "orderBottomUp": false,
    "previewsEnabled": true,
    "previewMode": "live",
    "includeInactiveMonitorPreviews": true,
    "previewRecaptureDelayMs": 60,
    "effects": {
      "enableBackdrop": false,
      "backdropOpacity": 0.28,
      "panelOpacity": 0.92,
      "workspaceOpacity": 0.86,
      "windowOverlayOpacity": 0.22,
      "enableBlur": false,
      "glassMode": false,
      "glassTintStrength": 0.35,
      "glassBorderOpacity": 0.72,
      "glassShineOpacity": 0.14
    },
    "workspaceSpacing": 5,
    "backgroundPadding": 10,
    "workspaceNumberBaseSize": 250
  },
  "position": {
    "topMargin": 100
  },
  "windowPreview": {
    "iconToWindowRatio": 0.25,
    "iconToWindowRatioCompact": 0.45,
    "xwaylandIndicatorToIconRatio": 0.35,
    "inactiveMonitorOpacity": 0.4
  },
  "hacks": {
    "arbitraryRaceConditionDelay": 150,
    "hyprlandEventDebounceMs": 40
  }
}
```

## colors.json

Path: `~/.config/overzicht/colors.json`

```json
{
  "m3primary": "#fb4934",
  "m3onPrimary": "#282828",
  "m3primaryContainer": "#3c3836",
  "m3onPrimaryContainer": "#fbf1c7",
  "m3onSecondary": "#282828",
  "m3secondaryContainer": "#3c3836",
  "m3onSecondaryContainer": "#fbf1c7",
  "m3onBackground": "#ebdbb2",
  "m3surface": "#282828",
  "m3surfaceContainerHigh": "#3c3836",
  "m3surfaceContainerHighest": "#504945",
  "m3surfaceVariant": "#504945",
  "m3background": "#3c3836",
  "m3secondary": "#b8bb26",
  "m3surfaceContainerLow": "#282828",
  "m3surfaceContainer": "#b8bb26",
  "m3onSurface": "#282828",
  "m3onSurfaceVariant": "#fbf1c7",
  "m3inverseSurface": "#504945",
  "m3inverseOnSurface": "#fbf1c7",
  "m3outline": "#fbf1c7",
  "m3outlineVariant": "#665c54",
  "m3shadow": "#282828"
}
```

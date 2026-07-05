# Configuration Examples

Examples for the two runtime JSON files generated/used by Overzicht.

## settings.json

Path: `~/.config/overzicht/settings.json`

```jsonc
{
  "appearance": {
    "font": {
      "family": {
        // Primary UI font family used by generic text widgets.
        "main": "sans-serif",
        // Reserved title font family override; currently exposed through Appearance but not used by shipped widgets.
        "title": "sans-serif",
        // Expressive font family used for large workspace numbers in the overview.
        "expressive": "sans-serif"
      },
      "pixelSize": {
        // Smallest text size, used by compact overview window labels and tooltips.
        "smaller": 12,
        // Default text size used by StyledText across the UI.
        "small": 15,
        // Reserved normal text size; available through Appearance but not directly used by current overview widgets.
        "normal": 16,
        // Reserved larger text size; available through Appearance but not directly used by current overview widgets.
        "larger": 19,
        // Reserved huge text size; available through Appearance but not directly used by current overview widgets.
        "huge": 22
      }
    },
    "animation": {
      "duration": {
        // Duration for the main spatial movement animation profile.
        "elementMove": 500,
        // Duration for overview window enter/move/resize transitions.
        "elementMoveEnter": 400,
        // Duration for faster UI motions such as tooltip and focus-indicator movement.
        "elementMoveFast": 200
      }
    },
    "sizes": {
      // Extra outer margin used to make room for the overview shadow/elevation effect.
      "elevationMargin": 10
    }
  },
  "overview": {
    // Number of workspace rows shown in each overview page and used for keyboard navigation.
    "rows": 2,
    // Number of workspace columns shown in each overview page and used for keyboard navigation.
    "columns": 4,
    // Scale factor applied to each monitor when drawing workspace thumbnails.
    "scale": 0.12,
    // Master switch for loading the overview widget when the overlay opens.
    "enable": true,
    // Hides rows that have no windows and are not the active workspace row.
    "hideEmptyRows": false,
    // Closes the overview when clicking outside it or when the focus grab is cleared.
    "closeOnFocusLoss": true,
    // Enables per-monitor workspace offsets from workspaceMap when grouping workspaces.
    "useWorkspaceMap": false,
    // Monitor-id keyed workspace start offsets used when useWorkspaceMap is enabled.
    "workspaceMap": [],
    // Reverses workspace columns so visual ordering runs right-to-left.
    "orderRightLeft": false,
    // Reverses workspace rows so visual ordering runs bottom-to-top.
    "orderBottomUp": false,
    // Enables screencopy window previews inside workspace thumbnails.
    "previewsEnabled": true,
    // Preview capture mode: "live" keeps previews streaming, "event"/"snapshot" only refreshes on selected window events.
    "previewMode": "live",
    // Allows previews for windows on other monitors instead of dimming them without capture.
    "includeInactiveMonitorPreviews": true,
    // Delay before re-enabling capture after an event-driven preview refresh.
    "previewRecaptureDelayMs": 60,
    // Wallpaper shown inside empty workspaces; accepts absolute paths and URL-style sources.
    "emptyWorkspaceWallpaper": "",
    "effects": {
      // Shows a fullscreen black backdrop behind the overview overlay.
      "enableBackdrop": false,
      // Opacity of the fullscreen backdrop when enableBackdrop is on.
      "backdropOpacity": 0.28,
      // Opacity of the main overview panel background and border.
      "panelOpacity": 0.92,
      // Opacity of each workspace tile fill/overlay.
      "workspaceOpacity": 0.86,
      // Opacity of the color overlay drawn on top of empty workspace wallpaper images.
      "emptyWorkspaceWallpaperOverlayOpacity": 0.18,
      // Opacity of the overlay tint drawn on top of each window preview.
      "windowOverlayOpacity": 0.22
    },
    // Gap between workspace cells in the overview grid.
    "workspaceSpacing": 5,
    // Inner padding between the overview panel border and the workspace grid.
    "backgroundPadding": 10,
    // Base font size for workspace numbers before monitor scale and overview scale are applied.
    "workspaceNumberBaseSize": 250
  },
  "windowPreview": {
    // Show application icons centered over window previews.
    "showIcons": true,
    // Icon size ratio for normal window previews.
    "iconToWindowRatio": 0.25,
    // Larger icon size ratio used when a preview is too small for the normal layout.
    "iconToWindowRatioCompact": 0.45,
    // Reserved XWayland indicator ratio; exposed in config but not currently rendered.
    "xwaylandIndicatorToIconRatio": 0.35,
    // Opacity applied to preview windows that belong to a different monitor than the current overview panel.
    "inactiveMonitorOpacity": 0.4,
    // Crop full-screen previews to fill the workspace tile. When false, the full preview remains visible with possible padding bars.
    "cropToFill": false
  },
  "hacks": {
    // Small delay used before focus grabs and some window-position recalculations to avoid timing issues.
    "arbitraryRaceConditionDelay": 150,
    // Debounce window/workspace/monitor refreshes triggered by Hyprland events.
    "hyprlandEventDebounceMs": 40
  }
}
```

## colors.json

Path: `~/.config/overzicht/colors.json`

```jsonc
{
  // Primary accent color, exposed as Appearance.colors.colPrimary for accent usage.
  "primary": "#fb4934",
  // Text/icon color intended to sit on top of primary surfaces.
  "onPrimary": "#282828",
  // Container variant of the primary accent color.
  "primaryContainer": "#3c3836",
  // Text/icon color intended to sit on top of primaryContainer surfaces.
  "onPrimaryContainer": "#fbf1c7",
  // Text/icon color intended to sit on top of secondary-colored surfaces.
  "onSecondary": "#282828",
  // Secondary container color, exposed as Appearance.colors.colSecondaryContainer.
  "secondaryContainer": "#3c3836",
  // Text/icon color intended to sit on top of secondaryContainer surfaces.
  "onSecondaryContainer": "#fbf1c7",
  // Default foreground color for generic text, including StyledText.
  "onBackground": "#ebdbb2",
  // Base surface tone; defined for theme completeness but not directly consumed by current overview widgets.
  "surface": "#282828",
  // Higher-emphasis surface tone; currently defined but not directly consumed by current overview widgets.
  "surfaceContainerHigh": "#3c3836",
  // Highest-emphasis surface tone; currently defined but not directly consumed by current overview widgets.
  "surfaceContainerHighest": "#504945",
  // Surface variant tone; currently defined but not directly consumed by current overview widgets.
  "surfaceVariant": "#504945",
  // Main panel/background color used for the overview container.
  "background": "#3c3836",
  // Secondary accent color used for the active workspace border.
  "secondary": "#b8bb26",
  // Workspace tile background color.
  "surfaceContainerLow": "#282828",
  // Window preview overlay base color.
  "surfaceContainer": "#b8bb26",
  // Foreground color for content placed on surfaceContainer surfaces.
  "onSurface": "#282828",
  // Foreground color used for workspace numbers and other content on low-emphasis surfaces.
  "onSurfaceVariant": "#fbf1c7",
  // Tooltip background color via Appearance.colors.colTooltip.
  "inverseSurface": "#504945",
  // Tooltip text color via Appearance.colors.colOnTooltip.
  "inverseOnSurface": "#fbf1c7",
  // Outline color used directly on preview borders and indirectly for subtext/outline roles.
  "outline": "#fbf1c7",
  // Variant outline color mixed into the overview panel border.
  "outlineVariant": "#665c54",
  // Shadow source color used for the overview drop shadow.
  "shadow": "#282828"
}
```

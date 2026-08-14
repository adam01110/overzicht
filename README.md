<div align="center">

  # overzicht

  A personal-use fork of `quickshell-overview`, a Quickshell workspace overview for Hyprland.

  [![Repo Size](https://img.shields.io/github/repo-size/adam01110/overzicht?style=flat-square&label=repo%20size&labelColor=504945&color=3c3836)](https://github.com/adam01110/overzicht)
  <br />
  [![Nix](https://img.shields.io/badge/Nix-flakes-689d6a?style=flat-square&labelColor=504945&logo=nixos&logoColor=ebdbb2)](https://nixos.wiki/wiki/Flakes)
  [![Hyprland](https://img.shields.io/badge/Hyprland-supported-458588?style=flat-square&labelColor=504945&color=458588)](https://hypr.land)
  [![Quickshell](https://img.shields.io/badge/Quickshell-QML-b16286?style=flat-square&labelColor=504945&color=b16286)](https://quickshell.outfoxxed.me/)
  [![Qt6](https://img.shields.io/badge/Qt-6-98971a?style=flat-square&labelColor=504945&logo=qt&logoColor=ebdbb2)](https://www.qt.io/)

  [Overview](#overview) - [Usage](#usage) - [Installation](#installation) - [Configuration](#configuration) - [Development](#development)
</div>

This fork keeps the parts I wanted from `quickshell-overview`, and removes the things i do not.

It is built to fit with the rest of my Nix-based desktop tooling.

<div align="center">
  <img src="./assets/screenshot.png" alt="Overzicht preview" width="640" />
</div>

## Overview

`overzicht` opens a full-screen workspace switcher for Hyprland. It shows the current workspace group as a grid, draws window previews, and can switch workspaces, focus windows, close windows, or move windows through Hyprland IPC.

What it does:

- Shows a grid of Hyprland workspaces with scaled window previews.
- Opens as a full-screen overlay on every monitor.
- Switches workspaces, focuses windows, closes windows, and moves windows through Hyprland IPC.
- Supports mouse actions, drag-and-drop window moves, and keyboard navigation.
- Reads simple JSON config from `~/.config/overzicht/`.
- Ships as a Nix flake package, overlay, Home Manager module, and NixOS module.
- Uses the Quickshell IPC target `overview` and layer-shell namespace `overzicht`.

A Hyprland release with Lua dispatcher support (`hl.dsp`) is required.

What I removed from upstream:

- Matugen and Caelestia color-source handling.
- Dynamic color template generation.
- Glass mode and the related tint/border/shine settings.

## Usage

Run it directly:

```bash
nix run github:adam01110/overzicht
```

The wrapper exposes Quickshell IPC:

```bash
# Toggle the overview
overzicht ipc call overview toggle

# Open it
overzicht ipc call overview open

# Close it
overzicht ipc call overview close
```

When running from the flake directly, pass IPC arguments after `--`:

```bash
nix run .#overzicht -- ipc call overview toggle
```

Keyboard controls while the overview is open:

| Key | Action |
| --- | --- |
| `Left` / `Right` / `Up` / `Down` | Move across the grid |
| `h` / `j` / `k` / `l` | Vim-style grid movement |
| `1` to `9` | Jump to that workspace position |
| `0` | Jump to position 10 when available |
| `Return` | Close the overview |
| `Escape` | Close the overview |

Mouse controls:

- Click a workspace to switch to it.
- Click a window preview to focus it.
- Middle-click a window preview to close it.
- Drag a window preview onto another workspace to move it there.

## Installation

Nix is the only supported installation path.

Available flake outputs:

| Output | Purpose |
| --- | --- |
| `packages.<system>.overzicht` | Main package |
| `packages.<system>.default` | Same package as the default output |
| `overlays.default` | Nixpkgs overlay |
| `homeModules.default` | Home Manager module |
| `nixosModules.default` | NixOS module |

### Home Manager

```nix
{
  imports = [ inputs.overzicht.homeModules.default ];

  programs.overzicht = {
    enable = true;
    systemd.enable = true;

    settings = {
      overview.rows = 2;
      overview.columns = 4;
    };

    colors = {
      primary = "#fb4934";
      secondary = "#b8bb26";
      background = "#3c3836";
    };
  };
}
```

### NixOS

```nix
{
  imports = [ inputs.overzicht.nixosModules.default ];

  services.overzicht.enable = true;
}
```

## Configuration

Config lives here:

| File | Purpose |
| --- | --- |
| `~/.config/overzicht/settings.json` | Layout, previews, behavior, animation timings |
| `~/.config/overzicht/colors.json` | Palette consumed by `common/Appearance.qml` |

The Home Manager module can generate both files. Full examples are in [`EXAMPLE.md`](./EXAMPLE.md).

Useful settings:

- `overview.rows` and `overview.columns` set the workspace grid shape.
- `overview.hideEmptyRows` keeps the grid compact when a row has no windows.
- `overview.closeOnFocusLoss` closes the overlay after outside clicks or focus loss.
- `overview.workspaceMap` lets different monitors start at different workspace offsets.
- `overview.previewMode` can be `live` or event-driven values like `event` / `snapshot`.
- `appearance.rounding.screenRounding` and `appearance.rounding.windowRounding` control overview corner radius. Set them to `0` for a square UI.
- `windowPreview.showIcons` controls centered app icons on previews.
- `windowPreview.cropToFill` controls whether full-screen previews crop into the tile.

## Credits

- [Original project (`Shanu-Kumawat/quickshell-overview`)](https://github.com/Shanu-Kumawat/quickshell-overview)

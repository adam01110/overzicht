{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit
    (lib)
    mkEnableOption
    mkOption
    mkIf
    getExe
    types
    literalExpression
    ;
  inherit (pkgs) callPackage;

  cfg = config.programs.overzicht;
  jsonFormat = pkgs.formats.json {};

  generateJson = name: value:
    if types.str.check value
    then pkgs.writeText name value
    else if types.path.check value || types.package.check value
    then value
    else jsonFormat.generate name value;
in {
  options.programs.overzicht = {
    enable = mkEnableOption "quickshell overview shell";

    systemd.enable = mkEnableOption "systemd user service for overzicht";

    package = mkOption {
      type = types.package;
      default = callPackage ./package.nix {};
      defaultText = literalExpression "callPackage ./package.nix {}";
      description = "Package that provides the `overzicht` executable.";
    };

    settings = mkOption {
      type = types.oneOf [jsonFormat.type types.str types.path];
      default = {
        overview = {
          rows = 2;
          columns = 4;
          scale = 0.12;
          enable = true;
          hideEmptyRows = false;
        };

        hacks.arbitraryRaceConditionDelay = 150;
      };
      description = "Settings written to `~/.config/overzicht/settings.json`.";
    };

    colors = mkOption {
      type = types.oneOf [jsonFormat.type types.str types.path];
      default = {
        m3primary = "#fb4934";
        m3onPrimary = "#282828";
        m3primaryContainer = "#3c3836";
        m3onPrimaryContainer = "#fbf1c7";
        m3onSecondary = "#282828";
        m3secondaryContainer = "#3c3836";
        m3onSecondaryContainer = "#fbf1c7";
        m3onBackground = "#ebdbb2";
        m3surface = "#282828";
        m3surfaceContainerHigh = "#3c3836";
        m3surfaceContainerHighest = "#504945";
        m3surfaceVariant = "#504945";
        m3background = "#3c3836";
        m3secondary = "#b8bb26";
        m3surfaceContainerLow = "#282828";
        m3surfaceContainer = "#b8bb26";
        m3onSurface = "#282828";
        m3onSurfaceVariant = "#fbf1c7";
        m3inverseSurface = "#504945";
        m3inverseOnSurface = "#fbf1c7";
        m3outline = "#fbf1c7";
        m3outlineVariant = "#665c54";
        m3shadow = "#282828";
      };
      description = "Colors written to `~/.config/overzicht/colors.json`.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [cfg.package];

    xdg.configFile = {
      "overzicht/settings.json".source = generateJson "overzicht-settings.json" cfg.settings;
      "overzicht/colors.json".source = generateJson "overzicht-colors.json" cfg.colors;
    };

    systemd.user.services.overzicht = mkIf cfg.systemd.enable {
      Unit = {
        Description = "overzicht";
        After = ["graphical-session-pre.target"];
        PartOf = ["graphical-session.target"];
      };

      Service = {
        ExecStart = getExe cfg.package;
        Restart = "on-failure";
        RestartSec = 1;
      };

      Install.WantedBy = ["graphical-session.target"];
    };

    assertions = [
      {
        assertion = cfg.package != null || !cfg.systemd.enable;
        message = "programs.overzicht.package cannot be null when systemd is enabled.";
      }
    ];
  };
}

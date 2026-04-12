{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: let
  inherit
    (lib)
    # keep-sorted start
    getExe
    literalExpression
    mkEnableOption
    mkIf
    mkOption
    types
    # keep-sorted end
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
    # keep-sorted start block=yes newline_separated=yes
    colors = mkOption {
      type = types.oneOf [jsonFormat.type types.str types.path];
      default = {};
      description = "Colors written to `~/.config/overzicht/colors.json`.";
    };

    enable = mkEnableOption "quickshell overview shell";

    package = mkOption {
      type = types.package;
      default = callPackage ../package.nix {};
      defaultText = literalExpression "callPackage ../package.nix {}";
      description = "Package that provides the `overzicht` executable.";
    };

    settings = mkOption {
      type = types.oneOf [jsonFormat.type types.str types.path];
      default = {};
      description = "Settings written to `~/.config/overzicht/settings.json`.";
    };

    systemd.enable = mkEnableOption "systemd user service for overzicht";
    # keep-sorted end
  };

  config = mkIf cfg.enable {
    # keep-sorted start block=yes newline_separated=yes
    assertions = [
      {
        assertion = cfg.package != null || !cfg.systemd.enable;
        message = "programs.overzicht.package cannot be null when systemd is enabled.";
      }
    ];

    home.packages = [cfg.package];

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

    xdg.configFile = {
      "overzicht/settings.json".source = generateJson "overzicht-settings.json" cfg.settings;
      "overzicht/colors.json".source = generateJson "overzicht-colors.json" cfg.colors;
    };

    # keep-sorted end
  };
}

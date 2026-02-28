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
    literalExpression
    mkIf
    getExe
    types
    ;
  inherit (pkgs) callPackage;

  cfg = config.services.overzicht;
in {
  options.services.overzicht = {
    enable = mkEnableOption "overzicht user service";

    package = mkOption {
      type = types.package;
      default = callPackage ./package.nix {};
      defaultText = literalExpression "callPackage ./package.nix {}";
      description = "Package that provides the `overzicht` executable.";
    };

    target = mkOption {
      type = types.str;
      default = "graphical-session.target";
      description = "User systemd target for overzicht.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [cfg.package];

    systemd.user.services.overzicht = {
      description = "overzicht";
      wantedBy = [cfg.target];
      after = ["graphical-session-pre.target"];
      partOf = [cfg.target];

      serviceConfig = {
        ExecStart = getExe cfg.package;
        Restart = "on-failure";
        RestartSec = 1;
      };
    };
  };
}

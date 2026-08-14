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

  cfg = config.services.overzicht;
in {
  options.services.overzicht = {
    # keep-sorted start block=yes newline_separated=yes
    enable = mkEnableOption "overzicht user service";

    package = mkOption {
      type = types.package;
      default = callPackage ../package.nix {};
      defaultText = literalExpression "callPackage ../package.nix {}";
      description = "Package that provides the `overzicht` executable.";
    };

    target = mkOption {
      type = types.str;
      default = "graphical-session.target";
      description = "User systemd target for overzicht.";
    };
    # keep-sorted end
  };

  config = mkIf cfg.enable {
    # keep-sorted start block=yes newline_separated=yes
    environment.systemPackages = [cfg.package];

    systemd.user.services.overzicht = {
      description = "overzicht";
      wantedBy = [cfg.target];
      after = [cfg.target];
      partOf = [cfg.target];

      serviceConfig = {
        ExecStart = getExe cfg.package;
        Restart = "on-failure";
        RestartSec = 1;
      };
    };
    # keep-sorted end
  };
}

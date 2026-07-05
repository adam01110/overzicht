{inputs, ...}: {
  flake = {
    overlays.default = final: _: {
      overzicht = final.callPackage ../package.nix {
        quickshell = inputs.quickshell.packages.${final.system}.default;
      };
    };

    # keep-sorted start
    homeModules.default = import ../modules/home-module.nix;
    nixosModules.default = import ../modules/nixos-module.nix;
    # keep-sorted end
  };

  perSystem = {
    # keep-sorted start
    config,
    pkgs,
    system,
    # keep-sorted end
    ...
  }: {
    packages = {
      # keep-sorted start
      default = config.packages.overzicht;
      overzicht = pkgs.callPackage ../package.nix {
        quickshell = inputs.quickshell.packages.${system}.default;
      };
      # keep-sorted end
    };
  };
}

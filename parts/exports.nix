_: {
  flake = {
    overlays.default = final: _: {
      overzicht = final.callPackage ../nix/package.nix {};
    };

    homeModules.default = import ../nix/home-module.nix;
    nixosModules.default = import ../nix/nixos-module.nix;
  };

  perSystem = {
    config,
    pkgs,
    ...
  }: {
    packages = {
      overzicht = pkgs.callPackage ../nix/package.nix {};
      default = config.packages.overzicht;
    };
  };
}

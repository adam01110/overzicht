{inputs, ...}:
# Treefmt configuration for repository formatting.
{
  imports = [inputs.treefmt-nix.flakeModule];

  perSystem = _: {
    treefmt = {
      projectRootFile = "flake.nix";

      programs = {
        alejandra.enable = true;
        nixf-diagnose.enable = true;
        deadnix.enable = true;
        statix.enable = true;

        qmlformat.enable = true;

        rumdl-format.enable = true;
      };
    };
  };
}

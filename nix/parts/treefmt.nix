{inputs, ...}:
# Treefmt configuration for repository formatting.
{
  imports = [inputs.treefmt-nix.flakeModule];

  perSystem = _: {
    treefmt = {
      projectRootFile = "flake.nix";

      programs = {
        # keep-sorted start
        alejandra.enable = true;
        deadnix.enable = true;
        nixf-diagnose.enable = true;
        statix.enable = true;
        # keep-sorted end

        qmlformat.enable = true;

        rumdl-format.enable = true;

        keep-sorted.enable = true;
      };
    };
  };
}

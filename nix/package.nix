{
  # keep-sorted start
  lib,
  makeWrapper,
  quickshell,
  stdenvNoCC,
  # keep-sorted end
}: let
  inherit
    (lib)
    # keep-sorted start
    cleanSource
    getExe
    # keep-sorted end
    ;
in
  stdenvNoCC.mkDerivation {
    pname = "overzicht";
    version = "unstable";

    src = cleanSource ../.;

    nativeBuildInputs = [makeWrapper];

    installPhase = ''
      runHook preInstall

      install -dm755 "$out/share/overzicht"
      cp -r ./* "$out/share/overzicht/"

      install -dm755 "$out/bin"
      makeWrapper ${getExe quickshell} "$out/bin/overzicht" \
        --add-flags "-p $out/share/overzicht"

      runHook postInstall
    '';

    meta = {
      description = "Quickshell-based workspace overview";
      homepage = "https://github.com/adam01110/overzicht";
      mainProgram = "overzicht";
      platforms = lib.platforms.linux;
    };
  }

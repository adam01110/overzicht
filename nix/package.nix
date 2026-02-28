{
  lib,
  stdenvNoCC,
  makeWrapper,
  quickshell,
}: let
  inherit
    (lib)
    cleanSource
    getExe
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

    meta = with lib; {
      description = "Quickshell-based workspace overview";
      mainProgram = "overzicht";
      platforms = platforms.linux;
    };
  }

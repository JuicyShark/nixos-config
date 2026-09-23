{
  lib,
  pkgs,
}: let
  package =
    if pkgs.stdenv.hostPlatform.isDarwin
    then pkgs.ghostty-bin
    else pkgs.ghostty;
  launcher = pkgs.writeShellApplication {
    name = "ghostty-launch";
    runtimeInputs = [package];
    text =
      if pkgs.stdenv.hostPlatform.isDarwin
      then ''
        exec /usr/bin/open -na Ghostty.app --args "$@"
      ''
      else ''
        exec ghostty +new-window "$@"
      '';
  };
in {
  inherit package launcher;
  command = lib.getExe launcher;
}

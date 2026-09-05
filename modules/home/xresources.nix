{
  osConfig,
  pkgs,
  lib,
  ...
}:
lib.mkIf (pkgs.stdenv.hostPlatform.isLinux && (osConfig.modules.desktop.enable or false)) {
  xresources.properties = {
    "Xft.hinting" = true;
    "Xft.antialias" = true;
    "Xft.autohint" = false;
    "Xft.lcdfilter" = "lcddefault";
    "Xft.hintstyle" = "hintfull";
    "Xft.rgba" = "rgb";
  };
}

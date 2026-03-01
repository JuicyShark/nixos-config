{
  osConfig,
  lib,
  ...
}:
lib.mkIf (builtins.elem "desktop" osConfig.modules.system.roles) {
  xresources.properties = {
    "Xft.hinting" = true;
    "Xft.antialias" = true;
    "Xft.autohint" = false;
    "Xft.lcdfilter" = "lcddefault";
    "Xft.hintstyle" = "hintfull";
    "Xft.rgba" = "rgb";
  };
}

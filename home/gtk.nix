{
  pkgs,
  osConfig,
  lib,
  ...
}: {
  home.packages = with pkgs;
    lib.mkIf (builtins.elem "desktop" osConfig.modules.system.roles) [gsettings-desktop-schemas];
  gtk = lib.mkIf (builtins.elem "desktop" osConfig.modules.system.roles) {
    enable = true;

    gtk3.extraConfig = {
      gtk-decoration-layout = "menu:";
      gtk-xft-antialias = 1;
      gtk-xft-hinting = 1;
      gtk-xft-hintstyle = "hintfull";
      gtk-xft-rgba = "rgb";
      gtk-recent-files-enabled = false;
    };
  };
}

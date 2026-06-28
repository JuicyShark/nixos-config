{
  pkgs,
  osConfig,
  lib,
  ...
}:
lib.mkIf (pkgs.stdenv.isLinux && (osConfig.modules.desktop.enable or false)) {
  home.packages = with pkgs; [gsettings-desktop-schemas];
  gtk = {
    enable = true;

    gtk3.extraConfig = {
      gtk-decoration-layout = "menu:";
      gtk-xft-antialias = 1;
      gtk-xft-dpi = 98304;
      gtk-xft-hinting = 1;
      gtk-xft-hintstyle = "hintfull";
      gtk-xft-rgba = "rgb";
      gtk-recent-files-enabled = false;
    };
  };
}

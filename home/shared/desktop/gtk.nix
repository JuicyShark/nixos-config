{
  pkgs,
  osConfig,
  lib,
  ...
}:
{
  home.packages = with pkgs; lib.mkIf osConfig.modules.desktop.enable [ gsettings-desktop-schemas ];
  gtk = lib.mkIf osConfig.modules.desktop.enable {
    enable = true;

    gtk3.extraConfig = {
      gtk-decoration-layout = "menu:";
      gtk-xft-antialias = 1;
      gtk-xft-hinting = 1;
      gtk-xft-hintstyle = "hintfull";
      gtk-xft-rgba = "rgb";
      gtk-recent-files-enabled = false;
    };

    iconTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita-dark";
    };
  };
}

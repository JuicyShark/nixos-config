{pkgs, lib, ...}:

{

    stylix = {
      targets.bat.enable = true;
      targets.firefox.enable = true;
      targets.firefox.profileNames = [ "default"];
      targets.foot.enable = true;
      targets.gitui.enable = true;
      targets.hyprland.enable = true;
      targets.nixvim.enable = true;
      targets.rofi.enable = true;
      targets.vesktop.enable = true;
      targets.waybar.enable = true;
      targets.xresources.enable = true;
      targets.yazi.enable = true;
    };
  gtk = {
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
      package = pkgs.papirus-icon-theme;
      name = "Papirus-Dark";
    };
  };
  qt = {
    enable = true;
    platformTheme.name = lib.mkForce "gtk3";

  };
}

{
  lib,
  pkgs,
  osConfig,
  ...
}: let
  inherit (lib) mkIf mkMerge;

  # programs.calls only exists on Linux (GNOME Calls / Phosh)
  isPhone = pkgs.stdenv.isLinux && (osConfig.programs.calls.enable or false);

  no = {
    name = "";
    settings.Hidden = "true";
  };
in
  lib.mkIf pkgs.stdenv.isLinux {
    xdg.desktopEntries = mkMerge [
      (mkIf isPhone {
        anki = no;
        htop = no;
        fish = no;
        nvim = no;
        yazi = no;
        qt5ct = no;
        qt6ct = no;
        gcdemu = no;
        nixos-manual = no;
        image-analyzer = no;
        kvantummanager = no;
        chromium-browser = no;

        "org.gnome.Extensions" = no;
        "org.pwmt.zathura" = no;
        "org.gnome.eog" = no;
        "org.gnome.Settings" = no;
        "org.sigxcpu.Livi" = no;
      })
    ];
  }

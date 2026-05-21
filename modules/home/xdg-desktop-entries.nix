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
      (mkIf (osConfig.modules.desktop.enable or false) (
        lib.mkMerge [
          {
            terminal = {
              name = "Terminal";
              comment = "Open a terminal";
              exec = "kitty --title terminal";
              terminal = false;
              type = "Application";
              categories = [
                "System"
                "Utility"
              ];
            };

            yazi = {
              name = "Yazi";
              comment = "Browse files";
              exec = "kitty --title yazi yazi %f";
              terminal = false;
              type = "Application";
              mimeType = ["inode/directory"];
              categories = [
                "System"
                "FileManager"
              ];
            };
          }
          (lib.optionalAttrs (osConfig.modules.desktop.guiFallback.enable or false) {
            backups-gui = {
              name = "Backups (GUI)";
              comment = "GUI backup fallback (grsync)";
              exec = "grsync";
              terminal = false;
              type = "Application";
              categories = [
                "Utility"
                "System"
              ];
            };
          })
        ]
      ))
    ];
  }

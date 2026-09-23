{
  lib,
  pkgs,
  osConfig,
  ...
}: let
  inherit (lib) mkIf mkMerge;

  # programs.calls only exists on Linux (GNOME Calls / Phosh)
  isPhone = pkgs.stdenv.hostPlatform.isLinux && (osConfig.programs.calls.enable or false);
  hasDesktop = pkgs.stdenv.hostPlatform.isLinux && (osConfig.modules.desktop.enable or false);
  terminal = (import ../../lib/terminal.nix {inherit lib pkgs;}).command;

  no = {
    name = "";
    settings.Hidden = "true";
  };
in
  lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    xdg.desktopEntries = mkMerge [
      (mkIf (hasDesktop && !isPhone) {
        yazi = {
          name = "Yazi";
          genericName = "File Manager";
          comment = "Browse files with Yazi";
          exec = "${terminal} --title=yazi -e ${lib.getExe pkgs.yazi} %U";
          icon = "system-file-manager";
          terminal = false;
          categories = ["System" "FileManager"];
          mimeType = ["inode/directory"];
        };
      })
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
        firefox = no;

        "org.gnome.Extensions" = no;
        "org.pwmt.zathura" = no;
        "org.gnome.eog" = no;
        "org.gnome.Settings" = no;
        "org.sigxcpu.Livi" = no;
      })
    ];
  }

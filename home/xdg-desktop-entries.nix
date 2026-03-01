{
  lib,
  nixosConfig,
  osConfig,
  ...
}: let
  inherit (lib) mkIf mkMerge;

  isPhone = nixosConfig.programs.calls.enable;
  desktopEnabled = builtins.elem "desktop" osConfig.modules.system.roles;
  guiFallback = builtins.elem "desktop-gui-fallback" osConfig.modules.system.roles;
  terminalExec = "kitty";

  no = {
    name = "";
    settings.Hidden = "true";
  };
in {
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
    (mkIf desktopEnabled (
      lib.mkMerge [
        {
          terminal = {
            name = "Terminal";
            comment = "Open a terminal";
            exec = terminalExec;
            terminal = false;
            type = "Application";
            categories = [
              "System"
              "Utility"
            ];
          };
        }
        (lib.optionalAttrs guiFallback {
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

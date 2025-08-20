{
  config,
  osConfig,
  lib,
  pkgs,
  nixosConfig,
  ...
}:
let
  inherit (nixosConfig._module.specialArgs.nix-config.inputs) caelestia-shell;
in
{
  imports = [
    caelestia-shell.homeManagerModules.default
  ];
  config = lib.mkIf osConfig.modules.desktop.enable {

    programs.caelestia = {
      enable = true;

      settings = {
        general.apps = {
          terminal = [ "ghostty" ];
          audio = [ "pwvucontrol" ];

        };
        background.desktopClock.enabled = true;
        background.enabled = true;

        bar = {
          dragThreshold = 20;
          persistent = true;
          showOnHover = false;
          status = {
            showAudio = true;
            showBattery = false;
            showBluetooth = true;
            showKbLayout = false;
            showNetwork = false;
          };

          tray.background = true;
          tray.recolour = true;

          workspaces = {
            activeIndicator = true;
            activeLabel = " ";
            activeTrail = false;
            label = " ";
            occupiedBg = true;
            occupiedLabel = "🪦";
            rounded = true;
            showWindows = false;
            shown = 5;
          };
        };
        border = {
          rounding = 25;
          thickness = 10;
        };
        dashboard = {
          enabled = true;
          dragThreshold = 50;
          mediaUpdateInterval = 500;
          showOnHover = true;
          visualiserBars = 45;

        };
        launcher = {
          actionPrefix = ">";
          dragThreshold = 50;
          enableDangerousActions = false;
          maxShown = 9;
          maxWallpapers = 9;
          useFuzzy = {
            apps = true;
            actions = true;
            schemes = true;
            variants = true;
            wallpapers = true;
          };
        };
        lock.recolourLogo = true;

        notifs = {
          actionOnClick = true;
          clearThreshold = "0.3";
          defaultExpireTimeout = 5000;
          expandThreshold = 20;
          expire = false;
        };
        osd.hideDelay = 3500;

        paths = {
          mediaGif = "root:/assets/bongocat.gif";
          sessionGif = "root:/assets/kurukuru.gif";
          wallpaperDir = "/home/${osConfig.modules.system.username}/media/pictures/wallpaper";
        };
        services = {
          audioIncrement = "0.1";
          weatherLocation = "-28,153";
          useFahrenheit = false;
          useTwelveHourClock = true;
          smartScheme = true;
        };
        session = {
          dragThreshold = 30;
          vimKeybinds = false;
          commands = {
            logout = [
              "loginctl"
              "terminate-user"
            ];
            shutdown = [
              "systemctl"
              "poweroff"
            ];
            hibernate = [
              "systemctl"
              "hibernate"
            ];
            reboot = [
              "systemctl"
              "reboot"
            ];
          };
        };

        /*
          appearance = {
            anims.durations.scale = "1.25";
            font = {
              family = {
                mono = config.stylix.fonts.monospace;
                sans = config.stylix.fonts.sansSerif;
              };
            };
          };
        */
      };

      cli = {
        enable = true;
      };
    };
  };
}

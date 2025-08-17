{
  osConfig,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf osConfig.modules.desktop.enable {
    home.packages = with pkgs; [
      caelestia-shell.packages.${pkgs.system}.default
    ];

    home.file.".config/caelestia/shell.json".text = ''
        {

        "general": {
            "apps": {
              "terminal": [ghostty],
              "audio": [pwvucontrol]
            }
        },
        "background": {
            "enabled": true
        },
        "bar": {
            "dragThreshold": 20,
            "persistent": true,
            "showOnHover": true,
            "status": {
                "showAudio": true,
                "showBattery": false,
                "showBluetooth": true,
                "showKbLayout": false,
                "showNetwork": false
            },
            "workspaces": {
                "activeIndicator": true,
                "activeLabel": "󰮯 ",
                "activeTrail": false,
                "label": " ",
                "occupiedBg": true,
                "occupiedLabel": "󰮯 ",
                "rounded": true,
                "showWindows": true,
                "shown": 5
            }
        },
        "border": {
            "rounding": 25,
            "thickness": 10
        },
        "dashboard": {
          "enabled": true,
          "dragThreshold": 50,
          "mediaUpdateInterval": 500,
          "showOnHover": true,
          "visualiserBars": 45


        },
        "launcher": {
            "actionPrefix": ">",
            "dragThreshold": 50,
            "enableDangerousActions": false,
            "maxShown": 8,
            "maxWallpapers": 9,
            "useFuzzy": {
                "apps": true,
                "actions": true,
                "schemes": true,
                "variants": true,
                "wallpapers": true
            }
        },
        "lock": {
            "maxNotifs": 5
        },
        "notifs": {
            "actionOnClick": true,
            "clearThreshold": 0.3,
            "defaultExpireTimeout": 5000,
            "expandThreshold": 20,
            "expire": false
        },
        "osd": {
            "hideDelay": 2000
        },
        "paths": {
            "mediaGif": "root:/assets/bongocat.gif",
            "sessionGif": "root:/assets/kurukuru.gif",
            "wallpaperDir": "~/media/pictures/wallpaper"
        },
        "services": {
          "audioIncrement": 0.1,
          "weatherLocation": "-28,153",
          "useFahrenheit": false,
          "useTwelveHourClock": true
        },
        "session": {
          "dragThreshold": 30,
          "vimKeybinds": false,
          "commands": {
              "logout": ["loginctl", "terminate-user", ""],
              "shutdown": ["systemctl", "poweroff"],
              "hibernate": ["systemctl", "hibernate"],
              "reboot": ["systemctl", "reboot"]
          }
      }
    '';
  };
}

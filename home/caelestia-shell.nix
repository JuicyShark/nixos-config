{
  config,
  osConfig,
  lib,
  pkgs,
  nixosConfig,
  ...
}: let
  inherit (nixosConfig._module.specialArgs.nix-config.inputs) caelestia-shell;
in {
  imports = [
    caelestia-shell.homeManagerModules.default
  ];
  config = lib.mkIf (builtins.elem "desktop" osConfig.modules.system.roles) {
    home.packages = with pkgs; [
      libcava
      cliphist
    ];
    programs.caelestia = {
      enable = true;
      systemd = {
        enable = true;
        target = "graphical-session.target";
      };

      settings = {
        general.apps = {
          terminal = ["kitty"];
          audio = ["pwvucontrol"];
          playback = ["mpv"];
          explorer = ["yazi"];
        };
        general.idle = {
          inhibitWhenAudio = true;
          lockBeforeSleep = false;

          timeouts = [
            {
              timeout = 1200;
              idleAction = "lock";
            }
          ];
        };

        background = {
          enabled = true;
          desktopClock = {
            enabled = true;
            scale = "1.15";
            position = "bottom-right";
            background = {
              enabled = true;
              opacity = "0.20";
              blur = true;
            };
          };
          visualiser = {
            enabled = false;
            autoHide = true;
          };
        };

        bar = {
          dragThreshold = 20;
          persistent = true;
          showOnHover = false;
          clock.showIcon = false;
          status = {
            showAudio = true;
            showBattery = false;
            showBluetooth = true;
            showKbLayout = false;
            showNetwork = false;
            showMicrophone = false;
            showLockStatus = true;
          };
          popouts = {
            activeWindow = false;
            statusIcons = true;
            tray = true;
          };
          scrollActions = {
            workspaces = false;
          };

          tray.background = true;
          tray.compact = false;
          tray.recolour = false;

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

            specialWorkspaceIcons = [
              {
                name = "steam";
                icon = "sports_esports";
              }
            ];
          };
          sizes = {
            innerWidth = 45;
            windowPreviewSize = 300;
            trayMenuWidth = 350;
          };
          entries = [
            {
              id = "logo";
              enabled = true;
            }
            {
              id = "workspaces";
              enabled = true;
            }
            {
              id = "spacer";
              enabled = true;
            }
            {
              id = "activeWindow";
              enabled = true;
            }

            {
              id = "spacer";
              enabled = true;
            }
            {
              id = "tray";
              enabled = true;
            }
            {
              id = "statusIcons";
              enabled = true;
            }
            {
              id = "idleInhibitor";
              enabled = false;
            }
            {
              id = "clock";
              enabled = true;
            }
            {
              id = "power";
              enabled = true;
            }
          ];
        };
        border = {
          rounding = 25;
          thickness = 8;
        };
        dashboard = {
          enabled = false;
          dragThreshold = 50;
          mediaUpdateInterval = 500;
          showOnHover = true;
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
          hiddenApps = [
            "Kvantum Manager"
            "NixOS Manual"
            "uuctl"
            "Qt6 Settings"
            "Qt5 Settings"
          ];
          sizes = {
            itemWidth = 750;
            itemHeight = 55;
          };
        };
        lock = {
          recolourLogo = true;
          sizes = {
            ratio = "21 / 9";
            centerWidth = 800;
          };
        };
        notifs = {
          actionOnClick = true;
          clearThreshold = "0.3";
          defaultExpireTimeout = 5000;
          expandThreshold = 20;
          groupPrewviewNum = 5;
          expire = true;
          sizes = {
            width = 500;
            image = 50;
            badge = 25;
          };
        };
        osd = {
          enableBrightness = true;
          enableMicrophone = false;
          hideDelay = 3500;
          sizes = {
            sliderWidth = 55;
            sliderHeight = 425;
          };
        };
        paths = {
          mediaGif = "root:/assets/bongocat.gif";
          sessionGif = "root:/assets/kurukuru.gif";
          wallpaperDir = "${config.xdg.userDirs.pictures}/wallpaper";
        };

        services = {
          audioIncrement = "0.1";
          weatherLocation = "-28,153";
          defaultPlayer = "YT Music";
          gpuType = "AMD";
          visualiserBars = 60;
          playerAliases = [
            {
              from = "com.github.th_ch.youtube_music";
              to = "YT Music";
            }
          ];
          useFahrenheit = false;
          useTwelveHourClock = true;
          smartScheme = true;
        };
        utilities = {
          enabled = true;
          maxToasts = 4;
          toasts = {
            audioInputChanged = false;
            audioOutputChanged = true;
            capsLockChanged = true;
            chargingChanged = true;
            configLoaded = false;
            dndChanged = true;
            gameModeChanged = true;
            numLockChanged = true;
            kbLayoutChanged = false;
            vpnChanged = true;
            nowPlaying = false;
          };
          sizes.width = 600;
          sizes.toastWidth = 600;
        };
        sidebar = {
          enabled = true;
          dragThreshold = 80;
          sizes.width = 600;
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
        appearance.anims.durations.scale = "1.33";
      };

      cli = {
        enable = true;
        settings.theme = {
          enableTerm = false;
          enableHypr = false;
          enableDiscord = false;
          enableSpicetify = false;
          enableFuzzel = false;
          enableBtop = false;
          enableGtk = false;
          enableQt = false;
        };
        settings.toggles = {
          communication = {
            discord = {
              enable = true;
              match = [{class = "discord";}];
              command = ["discord"];
              move = true;
            };
            sysmon = {
              btop = {
                enable = true;
                match = [
                  {
                    title = "btop";
                  }
                  {
                    class = "kitty";
                  }
                ];
                command = [
                  "kitty"
                  "-e"
                  "btop"
                ];
              };
            };
          };
        };
      };
    };
  };
}

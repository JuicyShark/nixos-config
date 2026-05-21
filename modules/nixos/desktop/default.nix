{
  inputs,
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib.types) str submodule nullOr bool;
  inherit (config.modules.system) username;
  inherit (config.boot) isContainer;
  inherit (lib) mkIf mkOption mkEnableOption;

  cfg = config.modules.desktop;

  desktopBasePackages = with pkgs; [
    btop
    bitwarden-desktop
    pulsemixer
    rsync
    wl-clipboard-rs
    gparted
    imv
    pciutils
    libmtp
    # Wayland/Hyprland QoL
    wlr-randr
    wdisplays
    hyprshot
    cliphist
    wf-recorder
  ];
in {
  imports = [
    ./gaming.nix
    ./apps.nix
  ];

  options.modules.desktop = {
    enable = mkEnableOption "desktop environment (Hyprland/Wayland)";
    bloat.enable = mkEnableOption "extra desktop applications (Signal, Discord, Obsidian, etc.)";
    gaming.enable = mkEnableOption "gaming features (Steam, GameMode, Wine, Proton, etc.)";
    streaming.enable = mkEnableOption "streaming tools (OBS, streamlink)";
    guiFallback.enable = mkEnableOption "GUI fallback applications (grsync, etc.)";
    virtual.enable = mkEnableOption "virtualization support (quickemu, cdemu)";

    primaryMonitor = mkOption {
      type = submodule {
        options = {
          output = mkOption {
            type = str;
            default = "DP-1";
            description = "Hyprland output name (e.g. DP-2). Used as the fallback when desc is empty.";
          };
          desc = mkOption {
            type = nullOr str;
            default = null;
            description = "EDID description prefix to match the monitor by, e.g. \"Samsung Electric Company C49RG9x\". When set, the monitor is bound by description so cable port swaps don't break the config.";
          };
          wideColor = mkOption {
            type = bool;
            default = false;
            description = "Set Hyprland's monitor.supports_wide_color. Enable for DCI-P3 / 10-bit panels.";
          };
        };
      };
      default = {};
      description = "Primary monitor description used by the desktop module, Hyprland config, Sunshine streaming, and Noctalia shell.";
    };
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = cfg.bloat.enable -> cfg.enable;
          message = "modules.desktop.bloat requires modules.desktop to be enabled";
        }
        {
          assertion = cfg.gaming.enable -> cfg.enable;
          message = "modules.desktop.gaming requires modules.desktop to be enabled";
        }
        {
          assertion = cfg.streaming.enable -> cfg.enable;
          message = "modules.desktop.streaming requires modules.desktop to be enabled";
        }
        {
          assertion = cfg.sunshine.enable -> cfg.enable;
          message = "modules.desktop.sunshine requires modules.desktop to be enabled";
        }
      ];
    }
    (mkIf cfg.enable {
      networking.networkmanager = {
        enable = true;
        wifi.macAddress = "random";
        unmanaged = ["interface-name:ve-*"];
      };

      nixpkgs.overlays = lib.optionals (!isContainer) [
        inputs.hyprland.overlays.hyprland-packages
      ];

      qt = {
        enable = true;
        platformTheme = lib.mkForce "qt5ct";
      };
      hardware.graphics.enable32Bit = true;

      # Bluetooth
      hardware.bluetooth.enable = true;

      environment.sessionVariables = {
        NIXOS_OZONE_WL = "1";
        GDK_BACKEND = "wayland,x11";
        QT_QPA_PLATFORM = "wayland;xcb";
        SDL_VIDEODRIVER = "wayland,x11";
        PROTON_ENABLE_WAYLAND = "1";
        PULSE_LATENCY_MSEC = "60";
        MOZ_ENABLE_WAYLAND = "1";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        _JAVA_AWT_WM_NONREPARENTING = "1";

        XDG_SESSION_TYPE = "wayland";
        XDG_SCREENSHOTS_DIR = "/home/${username}/media/pictures/screenshots";
      };

      programs = {
        hyprland = {
          enable = !isContainer;
          withUWSM = !isContainer;
        };
        uwsm.enable = mkIf (!isContainer) true;
        wayvnc.enable = true;

        nix-ld = {
          enable = true;
          libraries = with pkgs; [
            glibc
            zlib
            openssl
            libgcc
            stdenv.cc.cc.lib
          ];
        };
      };

      xdg.portal = {
        enable = !isContainer;
        extraPortals = with pkgs; [
          xdg-desktop-portal-gtk
          xdg-desktop-portal-termfilechooser
        ];
        config.common = {
          default = [
            "hyprland"
            "gtk"
          ];
          "org.freedesktop.impl.portal.FileChooser" = "termfilechooser";
        };
      };

      services = {
        greetd = mkIf (!isContainer) {
          enable = true;
          settings.default_session = {
            command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --sessions /run/current-system/sw/share/wayland-sessions";
            user = "greeter";
          };
        };

        flatpak.enable = true;
        blueman.enable = true;
        playerctld.enable = true;
        libinput.mouse.accelProfile = "flat";

        pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
          wireplumber.enable = true;
        };

        tumbler.enable = true;
        gvfs.enable = true;
        upower.enable = true;
        udisks2.enable = true;
        power-profiles-daemon.enable = true;
        # Firmware updates over LVFS (NVMe, dock/monitor controllers,
        # Logitech receivers, ZSA boards via flashing tools, etc.).
        fwupd.enable = true;

        # Auto-nice foreground apps (compositor, games) over background work (nix-daemon, syncthing)
        ananicy = {
          enable = true;
          package = pkgs.ananicy-cpp;
        };
      };

      # Kill runaway processes under memory pressure instead of swap-thrashing
      systemd.oomd.enable = true;

      security.rtkit.enable = true;
      boot.kernel.sysctl."vm.legacy_va_layout" = 0;
      security.pam.loginLimits = [
        {
          domain = "@audio";
          item = "memlock";
          type = "-";
          value = "unlimited";
        }
        {
          domain = "@audio";
          item = "rtprio";
          type = "-";
          value = "88";
        }
        {
          domain = "*";
          type = "soft";
          item = "stack";
          value = "8192";
        }
      ];

      # KDE Connect protocol ports for Valent (iOS/Android integration).
      # LocalSend (53317) is opened alongside when the bloat bundle (where
      # the package lives) is enabled, so a minimal desktop doesn't expose it.
      networking.firewall = {
        allowedTCPPortRanges = [
          {
            from = 1714;
            to = 1764;
          }
        ];
        allowedUDPPortRanges = [
          {
            from = 1714;
            to = 1764;
          }
        ];
        allowedTCPPorts = lib.optional cfg.bloat.enable config.modules.ports.localsend;
        allowedUDPPorts = lib.optional cfg.bloat.enable config.modules.ports.localsend;
      };

      environment.systemPackages = desktopBasePackages;
    })
  ];
}

{
  inputs,
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (config.boot) isContainer;
  inherit (lib) mkIf mkEnableOption mkOption;
  username = "juicy";

  cfg = config.modules.desktop;

  desktopBasePackages = with pkgs; [
    btop
    #bitwarden-desktop
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
    gparted
  ];
in {
  imports = [
    inputs.noctalia-greeter.nixosModules.default
    ./gaming.nix
    ./apps.nix
  ];

  options.modules.desktop = {
    enable = mkEnableOption "desktop environment (Hyprland/Wayland)";
    bloat.enable = mkEnableOption "extra desktop applications (Signal, Discord, Obsidian, etc.)";
    gaming = {
      enable = mkEnableOption "gaming features (Steam, GameMode, Wine, Proton, etc.)";
      retro.enable = mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to install retro gaming tools and ports with the gaming bundle.";
      };
    };
    streaming.enable = mkEnableOption "streaming tools (OBS, streamlink)";
    guiFallback.enable = mkEnableOption "GUI fallback applications (grsync, etc.)";
    virtual.enable = mkEnableOption "virtualization support (quickemu, cdemu)";
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
      hardware.i2c.enable = !isContainer;

      users.users.${username}.extraGroups = lib.optionals (!isContainer) ["i2c"];

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
        TZ = config.time.timeZone;
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        _JAVA_AWT_WM_NONREPARENTING = "1";

        XDG_SESSION_TYPE = "wayland";
        XDG_SCREENSHOTS_DIR = "/home/${username}/media/pictures/screenshots";
      };

      programs = {
        hyprland = {
          enable = !isContainer;
          portalPackage = inputs.xdph.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
          withUWSM = !isContainer;
        };
        uwsm.enable = mkIf (!isContainer) true;
        thunar.enable = true;
        wayvnc.enable = true;
        ssh.startAgent = true;

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
        ];
        config.hyprland = {
          default = [
            "hyprland"
            "gtk"
          ];
        };
      };

      services = {
        greetd = mkIf (!isContainer) {
          enable = true;
          settings.default_session.user = "greeter";
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

      programs.noctalia-greeter.enable = !isContainer;

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

      environment.systemPackages = desktopBasePackages;
    })
  ];
}

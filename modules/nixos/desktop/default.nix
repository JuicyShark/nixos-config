{
  inputs,
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (config.boot) isContainer;
  inherit (lib) mkIf mkEnableOption mkOption;
  username = config.modules.profile.username;

  cfg = config.modules.desktop;

  desktopBasePackages = with pkgs; [
    pulsemixer
    rsync
    wl-clipboard-rs
    gparted
    imv
    pciutils
    # Wayland/Hyprland QoL
    wdisplays
    hyprshot
    cliphist
    wf-recorder
  ];
in {
  imports = [
    inputs.noctalia-greeter.nixosModules.default
    ./gaming.nix
  ];

  options.modules.desktop = {
    enable = mkEnableOption "desktop environment (Hyprland/Wayland)";
    applications = {
      enable = mkEnableOption "extra desktop applications (Signal, Discord, Obsidian, etc.)";
      vivaldi.enable = mkEnableOption "Vivaldi browser";
      godot.enable = mkEnableOption "Godot editor";
    };
    annotation.enable = mkEnableOption "Wayland screen annotation tooling";
    gaming = {
      enable = mkEnableOption "gaming features (Steam, GameMode, Wine, Proton, etc.)";
      extraTools.enable = mkEnableOption "extra gaming tools (GOverlay, vkBasalt, WowUp, osu!)";
      gamescope = {
        enable = mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to enable the Gamescope Wayland micro-compositor for games.";
        };
        session.enable = mkEnableOption "a dedicated Steam Gamescope session";
      };
      retro.enable = mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to install retro gaming tools and ports with the gaming bundle.";
      };
    };
    streaming = {
      enable = mkEnableOption "streaming tools";
      chat.enable = mkEnableOption "streaming chat client";
      mirror.enable = mkEnableOption "Wayland display mirroring tool";
    };
    media.jellyfinMpvShim.enable = mkEnableOption "Jellyfin MPV Shim";
    virtual.enable = mkEnableOption "virtualization support (quickemu, cdemu)";
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = cfg.applications.enable -> cfg.enable;
          message = "modules.desktop.applications requires modules.desktop to be enabled";
        }
        {
          assertion = cfg.gaming.enable -> cfg.enable;
          message = "modules.desktop.gaming requires modules.desktop to be enabled";
        }
        {
          assertion = cfg.streaming.enable -> cfg.enable;
          message = "modules.desktop.streaming requires modules.desktop to be enabled";
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
      hardware = {
        graphics.enable32Bit = true;
        i2c.enable = !isContainer;
        bluetooth.enable = true;
      };

      users.users.${username}.extraGroups = lib.optionals (!isContainer) ["i2c"];

      programs = {
        hyprland = {
          enable = !isContainer;
          withUWSM = !isContainer;
          portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
        };
        uwsm.enable = mkIf (!isContainer) true;
        thunar.enable = true;
        ssh = {
          startAgent = true;
          enableAskPassword = true;
          askPassword = "${pkgs.wayprompt}/bin/wayprompt-ssh-askpass";
        };

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
        xdgOpenUsePortal = !isContainer;
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

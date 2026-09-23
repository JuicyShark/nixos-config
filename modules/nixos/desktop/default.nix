{
  inputs,
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (config.boot) isContainer;
  inherit (lib) mkIf mkEnableOption;
  username = config.modules.profile.username;

  cfg = config.modules.desktop;

  desktopBasePackages = with pkgs; [
    rsync
    gparted
    pciutils
  ];
in {
  imports = [
    inputs.noctalia-greeter.nixosModules.default
    ./gaming.nix
  ];

  options.modules.desktop = {
    enable = mkEnableOption "desktop environment (Hyprland/Wayland)";
    applications = {
      enable = mkEnableOption "extra desktop applications (Signal, Discord, LocalSend, etc.)";
    };
    gaming = {
      enable = mkEnableOption "gaming features (Steam, GameMode, Wine, Proton, etc.)";
    };
    streaming = {
      enable = mkEnableOption "streaming tools";
    };
    terminalFileChooser.enable = mkEnableOption "Yazi-backed terminal file chooser portal";
    media.jellyfinMpvShim.enable = mkEnableOption "Jellyfin MPV Shim";
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
        {
          assertion = cfg.terminalFileChooser.enable -> cfg.enable;
          message = "modules.desktop.terminalFileChooser requires modules.desktop to be enabled";
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
        (final: prev: {
          mpv-unwrapped = prev.mpv-unwrapped.overrideAttrs (old: {
            buildInputs = old.buildInputs ++ [final.SDL2];
            mesonFlags = map (flag:
              if flag == "-Dsdl2-gamepad=disabled"
              then "-Dsdl2-gamepad=enabled"
              else flag)
            old.mesonFlags;
          });
        })
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
          package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
          portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
        };
        ssh = {
          startAgent = true;
          enableAskPassword = true;
          askPassword = lib.getExe pkgs.lxqt.lxqt-openssh-askpass;
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
        extraPortals =
          [pkgs.xdg-desktop-portal-gtk]
          ++ lib.optional cfg.terminalFileChooser.enable pkgs.xdg-desktop-portal-termfilechooser;
        config.hyprland =
          {
            default = [
              "hyprland"
              "gtk"
            ];
          }
          // lib.optionalAttrs cfg.terminalFileChooser.enable {
            "org.freedesktop.impl.portal.FileChooser" = ["termfilechooser"];
          };
      };

      services = {
        playerctld.enable = true;
        libinput.mouse.accelProfile = "flat";

        pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
        };

        upower.enable = true;
        udisks2.enable = true;
        power-profiles-daemon.enable = true;
        fwupd.enable = true;
      };

      # Noctalia enables greetd; keep its condition independent of greetd.
      services.displayManager.noctalia-greeter.enable = !isContainer;

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

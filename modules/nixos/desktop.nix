{
  nix-config,
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib.types) str;
  inherit (config.modules.system) username;
  inherit (config.boot) isContainer;
  inherit (lib) mkIf mkOption;

  hasRole = role: builtins.elem role config.modules.system.roles;

  desktopEnabled = hasRole "desktop";
  desktopBloat = hasRole "desktop-bloat";
  desktopGuiFallback = hasRole "desktop-gui-fallback";
  desktopStreaming = hasRole "desktop-streaming";
  desktopGaming = hasRole "desktop-gaming";
  desktopVirtual = hasRole "desktop-virtual";
  desktopNiri = hasRole "desktop-niri";
  desktopHyprland = hasRole "desktop-hyprland" || !desktopNiri;

  hyprlandEnabled = desktopHyprland;
  niriEnabled = desktopNiri;
  compositorCount =
    (
      if hyprlandEnabled
      then 1
      else 0
    )
    + (
      if niriEnabled
      then 1
      else 0
    );

  desktopBasePackages = with pkgs; [
    btop
    bitwarden-desktop
    pulsemixer
    restic
    resticprofile
    rsync
    wl-clipboard-rs
    gparted
    imv
    pciutils
    libmtp
  ];

  bloatPackages = with pkgs; [
    obsidian
    signal-desktop
    pwvucontrol
    discord
    godot
    vivaldi
  ];

  streamingPackages = with pkgs; [streamlink];

  gamingPackages = with pkgs; [
    heroic
    mangohud
    goverlay
    osu-lazer-bin
    wowup-cf
    # Emulators can be added here if needed:
    # ryujinx
    # dolphin-emu
  ];
in {
  options.modules.desktop = {
    primaryMonitorName = mkOption {
      type = str;
      default = "DP-1";
    };
    primaryMonitorMode = mkOption {
      type = str;
      default = "preferred";
      description = "Primary monitor mode used by Hyprland. Defaults to EDID preferred mode for stable startup behavior.";
    };
  };

  config = mkIf desktopEnabled {
    nixpkgs.overlays = lib.optionals (!isContainer && hyprlandEnabled) [
      nix-config.inputs.hyprland.overlays.default
    ];

    qt = {
      enable = true;
      platformTheme = lib.mkForce "qt5ct";
    };
    hardware.graphics.enable32Bit = true;

    # Bluetooth
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;

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

    systemd.settings.Manager = mkIf desktopGaming {DefaultLimitNOFILE = 1048576;};
    programs = {
      # Wayland Compositors
      hyprland.enable = !isContainer && hyprlandEnabled;
      niri.enable = !isContainer && niriEnabled;

      cdemu.enable = desktopVirtual;
      gamemode.enable = desktopGaming;

      steam = {
        enable = desktopGaming && !isContainer;
        localNetworkGameTransfers.openFirewall = true;
        dedicatedServer.openFirewall = true;
        remotePlay.openFirewall = true;
        extraCompatPackages = with pkgs; [proton-ge-bin];
      };
    };
    xdg.portal.enable = !isContainer;

    services = {
      flatpak.enable = true;

      playerctld.enable = true;

      libinput.mouse.accelProfile = "flat";

      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        wireplumber.enable = true;
      };

      dbus.implementation = lib.mkForce "broker";

      tumbler.enable = true;
      gvfs.enable = true;
      upower.enable = true;
    };

    security.rtkit.enable = true;

    security.pam.services.quickshell = {};
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

    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        glibc
        zlib
        openssl
        libgcc
        stdenv.cc.cc.lib
        # Add others as you discover missing SONAMEs, e.g. libcap, libbsd, libcurl, etc.
      ];
    };

    environment.systemPackages =
      (lib.optionals (!isContainer && hyprlandEnabled) [
        pkgs.hyprland-qtutils
        pkgs.hyprwire
      ])
      ++ (lib.optionals (!isContainer && niriEnabled) [pkgs.xwayland-satellite])
      ++ (lib.optionals desktopBloat bloatPackages)
      ++ (lib.optionals desktopStreaming streamingPackages)
      ++ (lib.optionals desktopGaming gamingPackages)
      ++ (lib.optionals desktopVirtual [pkgs.quickemu])
      ++ (lib.optionals desktopGuiFallback [pkgs.grsync])
      ++ desktopBasePackages;
  };
}

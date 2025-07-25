{
  nix-config,
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib.types) float int;
  inherit (config.modules.system) username;
  inherit (config.boot) isContainer;
  inherit (builtins) attrValues;
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    ;
  inherit (cfg) apps;

  cfg = config.modules.desktop;
in
{
  imports = [
  ];
  options.modules.desktop = {
    enable = mkEnableOption "Enable Desktop Environment";
    opacity = mkOption {
      type = float;
      default = 0.95;
    };

    fontSize = mkOption {
      type = int;
      default = 13;
    };
    apps = {
      emacs = mkEnableOption "Emacs";
      bloat = mkEnableOption "GUI applications";
      streaming = mkEnableOption "Streaming Apps";
      gaming = mkEnableOption "Steam + Proton";
      llm = mkEnableOption "Llama llm model runner";
      virtual = mkEnableOption "Enable Qemu Support";
    };

    wallpapers = {
      "32:9".enable = lib.mkEnableOption "Dual monitor wallpapers";
    };
  };

  config = mkIf cfg.enable {
    qt = {
      enable = true;
      platformTheme = lib.mkForce "qt5ct";
    };

    hardware.graphics = {
      enable32Bit = mkIf (pkgs.system == "x86_64-linux") true;
    };

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      GDK_BACKEND = "wayland,x11,*";
      QT_QPA_PLATFORM = "wayland;xcb";
      SDL_VIDEODRIVER = "wayland";
      PULSE_LATENCY_MSEC = "60";
      MOZ_ENABLE_WAYLAND = "1";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      _JAVA_AWT_WM_NONREPARENTING = "1";

      XDG_SESSION_TYPE = "wayland";
      XDG_SCREENSHOTS_DIR = "/home/${username}/pictures/screenshots";
    };

    systemd.extraConfig = mkIf apps.gaming "DefaultLimitNOFILE=1048576";

    programs = {
      firefox.enable = true;
      #ladybird.enable = true; # Keep an eye on, independant web browser

      uwsm.enable = mkIf (!isContainer) true;

      hyprland = {
        enable = mkIf (!isContainer) true;
        withUWSM = true;
        package = nix-config.inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
        portalPackage =
          nix-config.inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;

      };

      cdemu.enable = true;
      steam = {
        enable = mkIf (apps.gaming && !isContainer) true;
        extest.enable = false;
        localNetworkGameTransfers.openFirewall = true;
        dedicatedServer.openFirewall = true;
        remotePlay.openFirewall = true;
        extraCompatPackages = with pkgs; [ proton-ge-bin ];
      };

      gnupg = {
        agent = {
          enable = true;
          pinentryPackage = pkgs.pinentry-qt;
          enableSSHSupport = true;
        };
      };
    };
    xdg.portal = {
      enable = mkIf (!isContainer) true;
      config = {
        sway = {
          default = [
            "gtk"
          ];
        };
        hyprland = {
          default = [
            "hyprland"
            "gtk"
          ];
        };
      };
    };

    services = {
      xserver = {
        enable = true;
        displayManager.lightdm.enable = false;
      };
      playerctld.enable = true;

      ollama.enable = mkIf apps.llm true;
      nextjs-ollama-llm-ui.enable = mkIf apps.llm true;

      libinput = {

        mouse = {
          accelProfile = "flat";
        };
      };

      pipewire = {
        enable = true;
        #alsa.enable = true;
        #alsa.support32Bit = true;
        pulse.enable = true;

        # wireplumber.enable = true;
      };

      dbus.implementation = lib.mkForce "dbus";
      tumbler.enable = true;
      gvfs.enable = true;
      upower.enable = true;
    };

    users.extraGroups.audio.members = [ username ];
    users.extraGroups.media.members = [ username ];

    security.rtkit.enable = true;

    boot.kernel.sysctl."vm.swappiness" = 10;

    security.pam.services.quickshell = { };

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
        value = "99";
      }
      {
        domain = "@audio";
        item = "nofile";
        type = "soft";
        value = "99999";
      }
      {
        domain = "@audio";
        item = "nofile";
        type = "hard";
        value = "99999";
      }
      {
        domain = "@users";
        item = "rtprio";
        type = "-";
        value = 1;
      }
    ];

    services.udev.extraRules = ''
      KERNEL=="hpet", GROUP="audio"
    '';

    environment.systemPackages = mkMerge [
      (mkIf apps.bloat (
        with pkgs;
        [
          iamb
          obsidian

          element-desktop
          signal-desktop
          clipboard-jh

          pwvucontrol
          discord
          pavucontrol
        ]
      ))

      (mkIf apps.streaming (
        with pkgs;
        [
          obs-studio
          streamlink
        ]
      ))
      (mkIf apps.gaming (
        with pkgs;
        [
          heroic
          ryujinx
          dolphin-emu
          osu-lazer-bin
          wowup-cf
        ]
      ))
      (mkIf apps.virtual (
        with pkgs;
        [
          quickemu
        ]
      ))
      (with pkgs; [
        bitwarden
        pulseaudio
        grim
        wl-clipboard-rs
        gparted
        qt6.qtwayland
        pciutils
        libmtp
      ])
    ];
  };
}

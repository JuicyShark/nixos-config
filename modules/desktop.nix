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
  };

  config = mkIf cfg.enable {
    qt = {
      enable = true;
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
    users.groups.libvirtd.members = [ username ];

    virtualisation = {
      libvirtd = {
        enable = true;

        qemu = {
          package = pkgs.qemu_kvm;
          ovmf = {
            enable = true;
            packages = [ pkgs.OVMFFull.fd ];
          };
          swtpm.enable = true;
        };
      };
    };
    #virtualisation.waydroid.enable = mkIf gaming true;
    #virtualisation.libvirtd.enable = true;
    #virtualisation.spiceUSBRedirection.enable = true;

    systemd.extraConfig = mkIf apps.gaming "DefaultLimitNOFILE=1048576";
    systemd.user.services.mqtt-listener = {
      description = "MQTT Command Listener";
      wantedBy = [ "default.target" ];
      serviceConfig = {
        ExecStart = ''

          ${pkgs.mosquitto}/bin/mosquitto_sub -h 192.168.1.59:8123 -t "hyprland/command" | \
          while read -r msg; do
            case "$msg" in
              lock) hyprctl dispatch lock ;;
              dpms_off) hyprctl dispatch dpms off ;;
              dpms_on) hyprctl dispatch dpms on ;;
              next_ws) hyprctl dispatch workspace e+1 ;;
              prev_ws) hyprctl dispatch workspace e-1 ;;
            esac
          done

        '';
      };
    };
    users.users.juicy.extraGroups = [ "libvirtd" ];

    services.xserver = mkIf (!isContainer) {
      enable = true;
      excludePackages = with pkgs; [ xterm ];
      displayManager.startx.enable = mkIf isContainer true;
      displayManager.gdm = {
        enable = true;
        wayland = true;
      };
      desktopManager.gnome.enable = true;
    };
    programs = {
      firefox.enable = true;
      #ladybird.enable = true; # Keep an eye on, independant web browser
      uwsm = {
        enable = mkIf (!isContainer) true;
        waylandCompositors = {
          sway = {
            prettyName = "Sway";
            comment = "Sway compositor managed by UWSM";
            binPath = "/run/current-system/sw/bin/sway";
          };
        };
      };

      hyprland = {
        enable = mkIf (!isContainer) true;
        # package = nix-config.inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
        # portalPackage = nix-config.inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
        withUWSM = true;
      };

      sway = {
        enable = mkIf (!isContainer) true;
        wrapperFeatures.gtk = true;
        extraOptions = [
          "--unsupported-gpu"
        ];
        extraPackages = with pkgs; [
          swayr
        ];
      };

      regreet = {
        enable = true;
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

      thunar = {
        enable = true;
        plugins = with pkgs.xfce; [ thunar-volman ];
      };
      appimage.binfmt = mkIf apps.bloat true;
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
      playerctld.enable = true;
      hardware.openrgb = {
        enable = true;
        motherboard = "intel";

      };
      ollama.enable = mkIf apps.llm true;
      nextjs-ollama-llm-ui.enable = mkIf apps.llm true;
      udisks2 = {
        enable = true;
        mountOnMedia = true;
      };

      libinput = {
        touchpad = {
          naturalScrolling = true;
          accelProfile = "flat";
          accelSpeed = "0.75";
        };

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

      greetd = mkIf (!isContainer) {
        enable = lib.mkForce false;
        restart = true;
        settings = {
          default_session = {
            command = "${lib.getExe config.programs.regreet.package}";
            # command = "${lib.getExe config.programs.uwsm.package} start hyprland-uwsm.desktop";
            user = "juicy";
          };
        };
      };

      dbus.implementation = lib.mkForce "dbus";
      tumbler.enable = true;
      gvfs.enable = true;
      upower.enable = true;
    };

    users.extraGroups.audio.members = [ username ];
    security.rtkit.enable = true;

    boot.kernel.sysctl."vm.swappiness" = 10;

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
          audacity
          moonlight-qt
          runelite
          iamb
          obsidian
          gimp
          element-desktop
          signal-desktop
          telegram-desktop
          clipboard-jh

          #bambu-studio
          pwvucontrol
          jellyfin-media-player
          discord
          youtube-music
          zathura
          pavucontrol
          appimage-run
          rpi-imager

          virt-manager
          input-leap
          sonobus
        ]
      ))

      (mkIf config.hardware.keyboard.zsa.enable (with pkgs; [ keymapp ]))
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

{ nix-config,
pkgs,
config,
lib,
...
}: let
  inherit (lib.types) float int;
  inherit (config.modules.system) username;
  inherit (config.boot) isContainer;
  inherit (builtins) attrValues;
  inherit (nix-config.inputs.hyprland.packages.${pkgs.system}) hyprland xdg-desktop-portal-hyprland;
  inherit (lib) mkEnableOption mkIf mkMerge mkOption;
  hypr-pkgs = nix-config.inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.system};

  inherit (cfg) apps opacity fontSize;


  cfg = config.modules.desktop;

  quantum = 32;
  rate = 48000;
  qr = "${toString quantum}/${toString rate}";
in {
  imports = [
    # nix-config.inputs.nixtheplanet.nixosModules.macos-ventura
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
  };
  };

  config = mkIf cfg.enable {
    qt = {
      enable = true;
      platformTheme = "qt5ct";
    };

    hardware.graphics = {
      package = hypr-pkgs.mesa.drivers;
      package32 = hypr-pkgs.pkgsi686Linux.mesa.drivers;
      enable32Bit = true;
    };
    environment.sessionVariables.NIXOS_OZONE_WL = "1";
    users.groups.libvirtd.members = [username];

    #virtualisation.waydroid.enable = mkIf gaming true;
    #virtualisation.libvirtd.enable = true;
    #virtualisation.spiceUSBRedirection.enable = true;
    hardware.xpadneo.enable = mkIf apps.gaming true;
    systemd.extraConfig = mkIf apps.gaming "DefaultLimitNOFILE=1048576";

    users.users.juicy.extraGroups = [ "libvirtd" ];
    programs = {
      firefox.enable = true;
      ladybird.enable = true;  # Keep an eye on, independant web browser
      uwsm.enable = mkIf (!isContainer) true;

      hyprland = {
        enable = mkIf (!isContainer) true;
        package = hyprland;
        portalPackage = xdg-desktop-portal-hyprland;
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

      cdemu.enable = true;
      steam = {
        enable = mkIf (apps.gaming && !isContainer) true;
        extest.enable = false;
        localNetworkGameTransfers.openFirewall = true;
        dedicatedServer.openFirewall = true;
        remotePlay.openFirewall = true;
        extraCompatPackages = with pkgs; [proton-ge-bin];
      };

      thunar = {
        enable =  true;
        plugins = with pkgs.xfce; [thunar-volman];
      };
      appimage.binfmt = mkIf apps.bloat true;
      gnupg = {
        agent = {
          enable = false;
          pinentryPackage = pkgs.pinentry-qt;
          enableSSHSupport = true;
        };
      };
    };
    xdg.portal = {
      enable = mkIf (!isContainer) true;
      wlr.enable = true;
      config = {
        common = {
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

      #extraPortals = with pkgs; [xdg-desktop-portal-wlr];
    };

    services = {
      ollama.enable = mkIf apps.llm true;
      udisks2 =  {
        enable = true;
        mountOnMedia = true;
      };

      libinput = {
        touchpad = {
          naturalScrolling = true;
          accelProfile = "flat";
          accelSpeed = "0.75";
        };

        mouse = {accelProfile = "flat";};
      };

      xserver = mkIf (!isContainer) {
        enable = true;
        excludePackages = with pkgs; [xterm];

        displayManager.startx.enable = mkIf (!isContainer) true;
      };

      pipewire =  {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
      };

      greetd = mkIf (!isContainer) {
        enable = true;
        restart = true;
        settings = {
          default_session = {
            command = "${pkgs.greetd.tuigreet}/bin/tuigreet";
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

    boot = {
      kernel.sysctl."vm.swappiness" = 10;
      kernelModules = [ "snd-seq" "snd-rawmidi" ];
      kernelParams = [ "threadirqs" ];
      postBootCommands = ''
        echo 2048 > /sys/class/rtc/rtc0/max_user_freq
        echo 2048 > /proc/sys/dev/hpet/max-user-freq
        setpci -v -d *:* latency_timer=b0
      '';
    };

    security.pam.loginLimits = [
      { domain = "@audio"; item = "memlock"; type = "-"; value = "unlimited"; }
      { domain = "@audio"; item = "rtprio"; type = "-"; value = "99"; }
      { domain = "@audio"; item = "nofile"; type = "soft"; value = "99999"; }
      { domain = "@audio"; item = "nofile"; type = "hard"; value = "99999"; }
      { domain = "@users"; item = "rtprio"; type = "-"; value = 1;  }
    ];

    services.udev.extraRules = ''
      KERNEL=="rtc0", GROUP="audio"
      KERNEL=="hpet", GROUP="audio"
    '';


    environment.systemPackages = mkMerge [
      (mkIf apps.bloat (with pkgs; [
        audacity
        moonlight-qt
        iamb
        obsidian
        gimp
        element-desktop
        signal-desktop
        telegram-desktop
        keepassxc
        keepass-keeagent

        #bambu-studio
        pwvucontrol
        discord
        youtube-music
        zathura
        pavucontrol
        appimage-run
        #virt-manager
      ]))

      (mkIf config.hardware.keyboard.zsa.enable (with pkgs; [keymapp]))
      (mkIf apps.streaming (with pkgs; [obs-studio streamlink]))
      (mkIf apps.gaming (with pkgs; [heroic ryujinx dolphin-emu osu-lazer-bin wowup-cf]))
      (with pkgs; [pulseaudio grim wl-clipboard-rs gparted qt6.qtwayland pciutils libmtp])

    ];
  };
}

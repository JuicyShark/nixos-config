{
  nix-config,
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib.types) float int;
  inherit (config.modules.system) username;
  inherit (config.boot) isContainer;
  inherit (builtins) attrValues;
  inherit (nix-config.inputs.sakaya.packages.${pkgs.system}) sakaya;
  inherit (nix-config.inputs.hyprland.packages.${pkgs.system}) hyprland xdg-desktop-portal-hyprland;
  inherit (lib) mkEnableOption mkIf mkMerge mkOption;
  hypr-pkgs = nix-config.inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.system};

  inherit (cfg) bloat gaming streaming opacity fontSize;

  isPhone = config.programs.calls.enable;

  cfg = config.modules.desktop;

  quantum = 32;
  rate = 48000;
  qr = "${toString quantum}/${toString rate}";
in {

  options.modules.desktop = {
    opacity = mkOption {
      type = float;
      default = 0.95;
    };

    fontSize = mkOption {
      type = int;
      default = 13;
    };

    bloat = mkEnableOption "GUI applications";
    streaming = mkEnableOption "Streaming Apps";
    gaming = mkEnableOption "Steam + Proton";
  };

  config = {
    hardware.graphics = {
      package = hypr-pkgs.mesa.drivers;
      package32 = hypr-pkgs.pkgsi686Linux.mesa.drivers;
      enable32Bit = !isPhone;


    };
   # hardware.xpadneo.enable = mkIf gaming true;
    systemd.extraConfig = mkIf gaming "DefaultLimitNOFILE=1048576";

    programs = {
    uwsm.enable = mkIf (!isContainer) true;

      hyprland = {
        enable = mkIf (!isContainer) true;
        package = hyprland;
        portalPackage = xdg-desktop-portal-hyprland;
        withUWSM = true;
      };

      cdemu.enable = mkIf (!isPhone) true;
      steam = {
        enable = mkIf (gaming && !isContainer) true;
        extest.enable = false;
        localNetworkGameTransfers.openFirewall = true;
        dedicatedServer.openFirewall = true;
        remotePlay.openFirewall = true;
        extraCompatPackages = with pkgs; [proton-ge-bin sakaya];
      };

      thunar = {
        enable = mkIf (!isPhone) true;

        plugins = with pkgs.xfce; [thunar-volman];
      };
      gnupg = {
        agent = {
          enable = true;
          pinentryPackage = pkgs.pinentry-curses;
          enableSSHSupport = true;
        };
      };
    };
    xdg.portal = {
      enable = mkIf (!isContainer) true;
      extraPortals = with pkgs; [xdg-desktop-portal-gtk];
    };

    services = {
      udisks2 = mkIf (!isPhone) {
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

      pipewire = mkIf (!isPhone) {
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
            command = "${lib.getExe config.programs.uwsm.package} start hyprland-uwsm.desktop";
            user = "juicy";
          };
        };
      };
      dbus.implementation = lib.mkForce "dbus";
      tumbler.enable = true;
      gvfs.enable = true;
      gnome.gnome-keyring.enable = true;
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
      (mkIf bloat (with pkgs; [
        audacity
        obsidian
        gimp
        element-desktop
        signal-desktop
        telegram-desktop
        pwvucontrol
        discord
        youtube-music
        zathura
        xournal
      ]))

      (mkIf (pkgs.system == "x86_64-linux") [sakaya])
      (mkIf config.hardware.keyboard.zsa.enable (with pkgs; [keymapp]))
      (mkIf streaming (with pkgs; [obs-studio chatterino2 streamlink]))
      (mkIf gaming (with pkgs; [heroic ryujinx]))
      (with pkgs; [pulseaudio grim wl-clipboard-rs])
    ];
  };
}

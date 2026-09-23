{
  lib,
  config,
  pkgs,
  ...
}:
lib.mkIf config.modules.desktop.enable {
  # The Maxwell's IEC958 route exposes only a software volume to PipeWire,
  # leaving two independent USB PCM controls at whatever level they last
  # held. Pin those hidden controls to unity whenever the dongle appears so
  # PipeWire/Noctalia remains the only user-facing volume control.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="sound", KERNEL=="card[0-9]*", ATTRS{idVendor}=="3329", ATTRS{idProduct}=="4b18", TAG+="systemd", ENV{SYSTEMD_WANTS}+="audeze-maxwell-gain@%k.service"
  '';

  systemd.services."audeze-maxwell-gain@" = let
    audezeMaxwellGain = pkgs.writeShellApplication {
      name = "audeze-maxwell-gain";
      runtimeInputs = [
        pkgs.alsa-utils
        pkgs.coreutils
      ];
      text = ''
        card_name="''${1:?missing ALSA card name}"
        card_number="$(cat "/sys/class/sound/$card_name/number")"

        amixer -c "$card_number" sset 'PCM',0 100%
        amixer -c "$card_number" sset 'PCM',1 100%
      '';
    };
  in {
    description = "Set Audeze Maxwell hardware playback gain";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${lib.getExe audezeMaxwellGain} %i";
    };
  };

  services.pipewire = {
    extraConfig.pipewire."10-clock" = {
      "context.properties" = {
        "default.clock.rate" = 96000;
        "default.clock.allowed-rates" = [
          44100
          48000
          88200
          96000
        ];
        "default.clock.quantum" = 512;
        "default.clock.min-quantum" = 256;
        "default.clock.max-quantum" = 2048;
        "link.max-buffers" = 64;
      };
    };
    extraConfig.pipewire-pulse."10-downmix-headroom" = {
      "stream.properties" = {
        # Proton titles commonly expose surround streams; normalize downmixes
        # to avoid clipping when PipeWire folds them back into stereo.
        "channelmix.normalize" = true;
        "channelmix.max-volume" = 1.0;
      };
    };
    wireplumber.extraConfig."10-audeze-maxwell" = {
      "monitor.alsa.rules" = [
        {
          matches = [
            {"node.name" = "~alsa_output.usb-Audeze_LLC_Audeze_Maxwell.*";}
          ];
          actions.update-props = {
            "audio.rate" = 96000;
            "clock.rate" = 96000;
            "clock.allowed-rates" = "[ 96000 ]";
            "resample.quality" = 7;
            "node.latency" = "512/96000";
            "session.suspend-timeout-seconds" = 0;
          };
        }
      ];
    };
    # Promote the Maxwell to default sink whenever it's connected; otherwise
    # PipeWire's default-policy lets the AMD GPU's HDMI/DP audio win the
    # priority race and the 96 kHz tuning above goes unused.
    wireplumber.extraConfig."51-audeze-default" = {
      "monitor.alsa.rules" = [
        {
          matches = [
            {"node.name" = "~alsa_output.usb-Audeze_LLC_Audeze_Maxwell.*";}
          ];
          actions.update-props = {
            "priority.session" = 9999;
            "priority.driver" = 9999;
          };
        }
      ];
    };
  };
}

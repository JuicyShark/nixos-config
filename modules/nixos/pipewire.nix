{
  lib,
  config,
  ...
}:
lib.mkIf config.modules.desktop.enable {
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

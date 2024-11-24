{
  services.hypridle = {
    enable = false;

    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };

      listener = [
        {
          timeout = 900;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 1280;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        {
          timeout = 4800;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
}

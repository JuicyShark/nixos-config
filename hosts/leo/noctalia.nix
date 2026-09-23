{...}: {
  programs.noctalia.settings.lockscreen_widgets = {
    enabled = true;
    schema_version = 2;
    widget_order = [
      "lockscreen-login-box@DP-2"
      "lockscreen-widget-0000000000000001"
      "lockscreen-widget-0000000000000002"
      "lockscreen-widget-0000000000000003"
      "lockscreen-widget-0000000000000004"
      "lockscreen-widget-0000000000000005"
    ];

    widget = {
      "lockscreen-login-box@DP-2" = {
        box_height = 196.0;
        box_width = 810.0;
        cx = 2560.0;
        cy = 1200.0;
        output = "DP-2";
        placement_height = 1440.0;
        placement_width = 5120.0;
        rotation = 0.0;
        type = "login_box";
        settings = {
          background_color = "surface_variant";
          background_opacity = 0.79;
          background_radius = 12.0;
          center_password_text = true;
          input_opacity = 1.0;
          input_radius = 6.0;
          layout = "regular";
          show_caps_lock = true;
          show_keyboard_layout = true;
          show_login_button = true;
          show_media = true;
          show_session_buttons = true;
          show_unlock_hint = true;
          show_weather = false;
        };
      };

      lockscreen-widget-0000000000000001 = {
        box_height = 528.0;
        box_width = 752.0;
        cx = 4704.0;
        cy = 296.0;
        output = "DP-2";
        placement_height = 1440.0;
        placement_width = 5120.0;
        rotation = 0.0;
        type = "fancy_audio_visualizer";
        settings = {
          background = false;
          bloom_intensity = 0.35;
          fade_when_idle = true;
          primary_color = "hover";
          visualization_mode = "bars_rings";
        };
      };

      lockscreen-widget-0000000000000002 = {
        box_height = 240.0;
        box_width = 400.0;
        cx = 4856.0;
        cy = 1256.0;
        output = "DP-2";
        placement_height = 1440.0;
        placement_width = 5120.0;
        rotation = 0.0;
        type = "sysmon";
        settings = {
          color2 = "error";
          stat = "cpu_usage";
          stat2 = "cpu_temp";
        };
      };

      lockscreen-widget-0000000000000003 = {
        box_height = 240.0;
        box_width = 400.0;
        cx = 4856.0;
        cy = 1016.0;
        output = "DP-2";
        placement_height = 1440.0;
        placement_width = 5120.0;
        rotation = 0.0;
        type = "sysmon";
        settings = {
          background = false;
          background_color = "on_primary";
          background_opacity = 0.54;
          background_radius = 10;
          display = "graph";
          gauge_layout = "horizontal";
          shadow = true;
          show_label = true;
          stat = "gpu_usage";
          stat2 = "gpu_vram";
        };
      };

      lockscreen-widget-0000000000000004 = {
        box_height = 240.0;
        box_width = 400.0;
        cx = 4456.0;
        cy = 1256.0;
        output = "DP-2";
        placement_height = 1440.0;
        placement_width = 5120.0;
        rotation = 0.0;
        type = "sysmon";
        settings = {
          background = false;
          background_color = "on_primary";
          background_opacity = 0.54;
          background_radius = 10;
          color = "tertiary";
          display = "gauge";
          gauge_layout = "horizontal";
          shadow = true;
          show_label = true;
          stat = "ram_pct";
          stat2 = "gpu_vram";
        };
      };

      lockscreen-widget-0000000000000005 = {
        box_height = 288.0;
        box_width = 400.0;
        cx = 2088.0;
        cy = 1168.0;
        output = "DP-2";
        placement_height = 1440.0;
        placement_width = 5120.0;
        rotation = 0.0;
        type = "weather";
        settings = {
          background = false;
          color = "secondary";
          forecast_days = 2;
          show_forecast = true;
        };
      };
    };
  };
}

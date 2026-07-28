{
  cfg,
  config,
}: let
  colors = config.lib.stylix.colors;
  rgb = color: "rgb(${color})";
in {
  monitor = cfg.desktop.monitors;

  config = {
    cursor = {
      default_monitor = cfg.desktop.primary.output;
      inactive_timeout = 10;
      no_hardware_cursors = false;
      no_break_fs_vrr = 2;
    };

    general = {
      gaps_in = 12;
      gaps_out = 24;
      border_size = 4;
      col = {
        active_border = rgb colors.base0B;
        inactive_border = rgb colors.base02;
      };
      resize_on_border = true;
      extend_border_grab_area = 3;
      layout = "scrolling";
      allow_tearing = true;
      snap = {
        enabled = true;
        window_gap = 15;
        monitor_gap = 10;
        border_overlap = false;
        respect_gaps = true;
      };
    };

    decoration = {
      rounding = 25;
      rounding_power = 1.0;
      dim_strength = 0.18;
      dim_special = 0.25;
      shadow = {
        enabled = true;
        range = 30;
        render_power = 3;
        color = "rgba(0A1F0E88)";
      };
      blur = {
        enabled = true;
        size = 5;
        passes = 2;
      };
    };

    group = {
      merge_groups_on_drag = false;
      merge_groups_on_groupbar = true;
      drag_into_group = 2;
      col = {
        border_active = rgb colors.base0B;
        border_inactive = rgb colors.base01;
      };
      groupbar = {
        enabled = true;
        indicator_height = 0;
        disable_when_only = true;
        font_size = 14;
        font_weight_active = "bold";
        font_weight_inactive = "book";
        height = 24;
        text_offset = -3;
        text_padding = 3;
        text_color = "0xFF${colors.base07}";
        text_color_inactive = "0xFF${colors.base05}";
        col = {
          active = rgb colors.base02;
          inactive = rgb colors.base02;
        };
        rounding_power = 1.0;
        rounding = 16;
        gradient_rounding = 16;
        gaps_out = 0;
        gaps_in = 0;
        keep_upper_gap = false;
      };
    };

    xwayland = {
      create_abstract_socket = true;
    };
    render = {
      direct_scanout = 2;
      cm_enabled = true;
    };

    dwindle = {
      preserve_split = true;
      default_split_ratio = 1.0;
      split_width_multiplier = 1.25;
      special_scale_factor = 0.7;
    };

    master = {
      mfact = 0.45;
      special_scale_factor = 0.8;
      new_status = "slave";
      orientation = "center";
      center_ignores_reserved = true;
      slave_count_for_center_master = 0;
      center_master_fallback = "right";
      always_keep_position = true;
    };

    scrolling = {
      fullscreen_on_one_column = false;
      column_width = 0.35;
      focus_fit_method = 1;
      follow_min_visible = 0.9;
      explicit_column_widths = "0.15, 0.3,  0.5, 0.65625, 1.0";
      direction = "right";
    };

    binds = {
      pass_mouse_when_bound = false;
      scroll_event_delay = 0;
    };

    misc = {
      disable_hyprland_logo = true;
      focus_on_activate = true;
      animate_manual_resizes = true;
      animate_mouse_windowdragging = true;
      disable_autoreload = true;
      font_family = "IosevkaTerm Nerd Font";
      enable_swallow = true;
      swallow_regex = "^(com.mitchellh.ghostty|kitty)$";
      session_lock_xray = true;
      vrr = 1;
      size_limits_tiled = false; # Enabling ruins scrolling layout -- https://github.com/hyprwm/Hyprland/pull/13445
      mouse_move_enables_dpms = false;
    };

    ecosystem = {
      no_update_news = true;
      no_donation_nag = true;
    };
    animations = {
      enabled = true;
      workspace_wraparound = true;
    };

    input = {
      kb_layout = "us";
      repeat_rate = 50;
      repeat_delay = 300;
      accel_profile = "flat";
      follow_mouse = 1;
      sensitivity = -0.3;
      mouse_refocus = false;
    };

    gestures = {
      workspace_swipe_distance = 650;
      workspace_swipe_cancel_ratio = 0.4;
    };
  };

  curve = [
    {
      _args = [
        "ease_quick"
        {
          type = "bezier";
          points = [
            [
              0.16
              1.0
            ]
            [
              0.3
              1.0
            ]
          ];
        }
      ];
    }
    {
      _args = [
        "ease_overshoot"
        {
          type = "bezier";
          points = [
            [
              0.05
              0.9
            ]
            [
              0.1
              1.12
            ]
          ];
        }
      ];
    }
    {
      _args = [
        "spring_snappy"
        {
          type = "spring";
          mass = 1;
          stiffness = 150;
          dampening = 16;
        }
      ];
    }
    {
      _args = [
        "spring_window"
        {
          type = "spring";
          mass = 1;
          stiffness = 105;
          dampening = 12;
        }
      ];
    }
    {
      _args = [
        "spring_workspace"
        {
          type = "spring";
          mass = 1;
          stiffness = 95;
          dampening = 14;
        }
      ];
    }
    {
      _args = [
        "spring_drawer"
        {
          type = "spring";
          mass = 1;
          stiffness = 110;
          dampening = 12;
        }
      ];
    }
  ];

  animation = [
    {
      leaf = "windows";
      enabled = true;
      speed = 6;
      spring = "spring_window";
      style = "slide";
    }
    {
      leaf = "windowsIn";
      enabled = true;
      speed = 6;
      spring = "spring_window";
      style = "popin 74%";
    }
    {
      leaf = "windowsMove";
      enabled = true;
      speed = 5;
      spring = "spring_snappy";
    }
    {
      leaf = "windowsOut";
      enabled = true;
      speed = 4;
      bezier = "ease_overshoot";
      style = "popin 70%";
    }
    {
      leaf = "layersIn";
      enabled = true;
      speed = 6;
      spring = "spring_drawer";
      style = "slide top";
    }
    {
      leaf = "layersOut";
      enabled = true;
      speed = 4;
      bezier = "ease_quick";
      style = "slide top";
    }
    {
      leaf = "fade";
      enabled = true;
      speed = 5;
      bezier = "ease_quick";
    }
    {
      leaf = "fadeSwitch";
      enabled = true;
      speed = 5;
      bezier = "ease_quick";
    }
    {
      leaf = "fadePopups";
      enabled = true;
      speed = 4;
      bezier = "ease_quick";
    }
    {
      leaf = "fadeLayers";
      enabled = true;
      speed = 4;
      bezier = "ease_quick";
    }
    {
      leaf = "workspaces";
      enabled = true;
      speed = 7;
      spring = "spring_workspace";
      style = "slidefadevert 28%";
    }
    {
      leaf = "specialWorkspace";
      enabled = true;
      speed = 6;
      spring = "spring_drawer";
      style = "slidefadevert 32%";
    }
  ];

  gesture = [
    {
      fingers = 3;
      direction = "horizontal";
      action = "workspace";
    }
    {
      fingers = 2;
      direction = "pinchin";
      action = "float";
      mods = "SUPER";
      arg = "tile";
    }
    {
      fingers = 2;
      direction = "pinchout";
      action = "float";
      mods = "SUPER";
    }
    {
      fingers = 3;
      direction = "up";
      action = "fullscreen";
    }
  ];

  window_rule = [
    {
      match = {
        tag = "marked";
      };
      border_size = 12;
      rounding = 0;
      border_color = rgb colors.base0B;
    }
    {
      match = {
        pin = true;
      };
      border_color = rgb colors.base0B;
    }
  ];
}

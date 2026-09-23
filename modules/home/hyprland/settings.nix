{
  config,
  osConfig,
  lib,
}: let
  ultrawide = config.modules.desktop.hyprland.sizing == "ultrawide";
  colors = config.lib.stylix.colors;
  focusAccent = colors.base0D;
  groupAccent = colors.base0C;
  rgb = color: "rgb(${color})";
  rgba = alpha: color: "rgba(${color}${alpha})";
in {
  monitor =
    [
      {
        output = "";
        mode = "preferred";
        position = "auto";
        scale = 1;
      }
    ]
    ++ config.modules.desktop.hyprland.monitors;

  config = {
    cursor = {
      default_monitor = config.modules.desktop.hyprland.primaryMonitor;
      inactive_timeout = 10;
      no_hardware_cursors = false;
      no_break_fs_vrr = 2;
      zoom_detached_camera = false;
      zoom_rigid = false;
    };

    general = {
      gaps_in =
        if ultrawide
        then 12
        else 5;
      gaps_out =
        if ultrawide
        then 24
        else 10;
      border_size =
        if ultrawide
        then 4
        else 2;
      col = {
        active_border = rgb focusAccent;
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
      rounding = 14;
      rounding_power = 1.0;
      dim_strength = 0.18;
      dim_special = 0.25;
      shadow = {
        enabled = true;
        range = 20;
        render_power = 2;
        color = rgba "aa" colors.base00;
        color_inactive = rgba "55" colors.base00;
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
        # Normal-window borders remain under general.col; groups and locked
        # groups each get a distinct state colour here.
        border_active = rgb groupAccent;
        border_inactive = rgb colors.base01;
        border_locked_active = rgb colors.base0A;
        border_locked_inactive = rgb colors.base03;
      };
      groupbar = {
        enabled = true;
        gradients = true;
        indicator_height = 0;
        disable_when_only = true;
        font_size = 14;
        font_weight_active = "bold";
        font_weight_inactive = "book";
        height = 28;
        text_offset = 0;
        text_padding = 0;
        text_color = "0xFF${colors.base00}";
        text_color_inactive = "0xFF${colors.base05}";
        col = {
          active = rgba "e6" groupAccent;
          inactive = rgba "e6" colors.base01;
          locked_active = rgba "e6" colors.base0A;
          locked_inactive = rgba "e6" colors.base02;
        };
        rounding_power = 1.0;
        rounding = 0;
        gradient_rounding = 0;
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
    };

    master = {
      mfact = 0.45;
      new_status = "slave";
      orientation = "center";
      center_ignores_reserved = true;
      slave_count_for_center_master = 0;
      center_master_fallback = "right";
      always_keep_position = true;
    };

    scrolling = {
      # Keep a lone terminal or file manager as a column rather than silently
      # turning it into a fullscreen workspace on the 32:9 panel.
      fullscreen_on_one_column = false;
      # Keep newly created columns compact, including windows promoted out of
      # an existing stack.
      # App rules below specialize from this ladder where their content needs
      # either a denser or wider working surface.
      column_width =
        if ultrawide
        then 0.25
        else 0.65;
      focus_fit_method = 1;
      follow_focus = true;
      follow_min_visible = 0.9;
      # These are the useful 5120x1440 working widths for colresize +/-conf:
      # tiny, compact terminal/utility, general, editor, browser, video,
      # ultrawide, full.
      explicit_column_widths =
        if ultrawide
        then "0.2, 0.3, 0.35, 0.4, 0.45, 0.5, 0.65625, 1.0"
        else "0.5, 0.65, 0.8, 1.0";
      direction = "right";
    };

    binds = {
      pass_mouse_when_bound = false;
      scroll_event_delay = 0;
      drag_center_window = false;
    };

    misc = {
      allow_session_lock_restore = true;
      disable_hyprland_logo = true;
      focus_on_activate = true;
      animate_manual_resizes = true;
      animate_mouse_windowdragging = true;
      disable_autoreload = true;
      font_family = config.stylix.fonts.monospace.name;
      enable_swallow = true;
      swallow_regex = "^com.mitchellh.ghostty$";
      session_lock_xray = false;
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
      # Keep the pointer where the user left it after scrolling columns.
      scrolling.move_snap_cursor = false;
      scrolling.move_snap_to_grid = false;
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
      style = "popin 94%";
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
      style = "popin 94%";
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
      fingers = 2;
      direction = "pinch";
      action = "cursor_zoom";
      mode = "live";
      zoom_level = 1;
    }
    {
      fingers = 3;
      direction = "horizontal";
      # Continuous, momentum-aware column scrolling instead of changing workspaces.
      action = "scroll_move";
      scale = 1.5;
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

  # USB exposes two interfaces; give either one the same trackpad policy.
  # Adaptive acceleration is a macOS-like starting point, not Apple's curve.
  device =
    map (name: {
      inherit name;
      accel_profile = "adaptive";
      sensitivity = 0.0;
      natural_scroll = true;
      scroll_method = "2fg";
      scroll_factor = 1.0;
      clickfinger_behavior = true;
      tap_to_click = false;
      tap_and_drag = false;
      drag_lock = false;
      middle_button_emulation = false;
    }) [
      "apple-inc.-magic-trackpad"
      "apple-inc.-magic-trackpad-1"
    ];

  window_rule = [
    {
      match = {
        pin = true;
      };
      border_color = rgb colors.base0B;
    }
  ];
}

{
  cfg,
  config,
  lib,
}: let
  inherit (lib) optionals;
  inherit (lib.generators) mkLuaInline;

  colors = config.lib.stylix.colors;
  rgb = color: "rgb(${color})";

  theme = {
    gaps_in = 12;
    gaps_out = 24;
    rounding = 25;
  };

  primary = {
    selector = "DP-2";
  };

  curve = name: type: points: {
    _args = [
      name
      {
        inherit type points;
      }
    ];
  };

  spring = name: mass: stiffness: dampening: {
    _args = [
      name
      {
        type = "spring";
        inherit mass stiffness dampening;
      }
    ];
  };

  animation = attrs: attrs;
in {
  monitor =
    [
      {
        output = primary.selector;
        mode = "preferred";
        position = "0x0";
        scale = 1;
      }
      {
        output = "HDMI-A-2";
        mode = "preferred";
        position = "auto-center-right";
        scale = 1;
      }
    ]
    ++ optionals (cfg.sunshine.enable or false) [
      {
        output = cfg.sunshine.virtualMonitor;
        disabled = true;
      }
    ];

  config = {
    cursor = {
      default_monitor = primary.selector;
      inactive_timeout = 10;
      enable_hyprcursor = true;
      no_hardware_cursors = false;
      no_break_fs_vrr = 2;
    };

    general = {
      inherit (theme) gaps_in;
      inherit (theme) gaps_out;
      border_size = 4;
      col = {
        active_border = {
          colors = [(rgb colors.base0D) (rgb colors.base0E)];
          angle = 45;
        };
        inactive_border = rgb colors.base02;
      };
      resize_on_border = true;
      extend_border_grab_area = 3;
      layout = "master";
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
      inherit (theme) rounding;
      rounding_power = 1.0;
      dim_inactive = false;
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
        border_active = {
          colors = [(rgb colors.base0C) (rgb colors.base0E)];
          angle = 45;
        };
        border_inactive = rgb colors.base01;
      };
      groupbar = {
        enabled = true;
        indicator_height = 0;
        font_size = 17;
        font_weight_active = "heavy";
        height = 32;
        text_offset = -3;
        text_padding = 3;
        text_color = "0xFF${colors.base07}";
        text_color_inactive = "0xFF${colors.base04}";
        col = {
          active = {
            colors = [(rgb colors.base0C) (rgb colors.base02)];
            angle = 45;
          };
          inactive = rgb colors.base01;
        };
        rounding_power = 1.0;
        gradients = true;
        gradient_rounding = 16;
        gaps_out = 0;
        gaps_in = 4;
        keep_upper_gap = false;
        blur = false;
      };
    };

    xwayland = {
      enabled = true;
      create_abstract_socket = true;
      force_zero_scaling = true;
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
      allow_small_split = false;
      new_status = "slave";
      new_on_top = false;
      orientation = "center";
      center_ignores_reserved = true;
      slave_count_for_center_master = 0;
      center_master_fallback = "right";
      always_keep_position = true;
    };

    scrolling = {
      fullscreen_on_one_column = true;
      column_width = 0.5;
      focus_fit_method = 1;
      follow_focus = true;
      follow_min_visible = 0.4;
      explicit_column_widths = "0.333, 0.5, 0.667, 1.0";
      direction = "right";
    };

    binds = {
      allow_workspace_cycles = false;
      workspace_back_and_forth = false;
    };

    misc = {
      disable_hyprland_logo = true;
      focus_on_activate = true;
      animate_manual_resizes = true;
      animate_mouse_windowdragging = true;
      disable_autoreload = true;
      initial_workspace_tracking = 0;
      font_family = "IosevkaTerm Nerd Font";
      enable_swallow = true;
      swallow_regex = "^(com.mitchellh.ghostty|kitty)$";
      session_lock_xray = true;
      vrr = 2;
      size_limits_tiled = true;
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

    plugin.hyprbars = {
      enabled = true;
      bar_height = 28;
      bar_color = "rgba(${colors.base01}ee)";
      col.text = rgb colors.base05;
      bar_text_font = "IosevkaTerm Nerd Font";
      bar_text_size = 12;
      bar_text_align = "left";
      bar_buttons_alignment = "right";
      bar_padding = 9;
      bar_button_padding = 6;
      bar_part_of_window = true;
      bar_precedence_over_border = true;
      on_double_click = "${cfg.hyprctl} dispatch fullscreen 1";
    };
  };

  curve = [
    (curve "ease_snap" "bezier" [[0.05 0.9] [0.1 1.0]])
    (curve "ease_quick" "bezier" [[0.16 1.0] [0.3 1.0]])
    (spring "spring_snappy" 1 125 18)
    (spring "spring_window" 1 95 15)
    (spring "spring_workspace" 1 80 18)
    (spring "spring_drawer" 1 90 13)
  ];

  animation = [
    (animation {
      leaf = "windows";
      enabled = true;
      speed = 5;
      spring = "spring_window";
      style = "slide";
    })
    (animation {
      leaf = "windowsIn";
      enabled = true;
      speed = 5;
      spring = "spring_window";
      style = "popin 88%";
    })
    (animation {
      leaf = "windowsMove";
      enabled = true;
      speed = 4;
      spring = "spring_snappy";
    })
    (animation {
      leaf = "windowsOut";
      enabled = true;
      speed = 4;
      bezier = "ease_quick";
      style = "popin 82%";
    })
    (animation {
      leaf = "layersIn";
      enabled = true;
      speed = 5;
      spring = "spring_drawer";
      style = "slide";
    })
    (animation {
      leaf = "layersOut";
      enabled = true;
      speed = 4;
      bezier = "ease_quick";
      style = "slide";
    })
    (animation {
      leaf = "border";
      enabled = true;
      speed = 8;
      bezier = "ease_snap";
    })
    (animation {
      leaf = "borderangle";
      enabled = true;
      speed = 25;
      bezier = "ease_snap";
      style = "once";
    })
    (animation {
      leaf = "fade";
      enabled = true;
      speed = 4;
      bezier = "ease_quick";
    })
    (animation {
      leaf = "fadePopups";
      enabled = true;
      speed = 3;
      bezier = "ease_quick";
    })
    (animation {
      leaf = "fadeLayers";
      enabled = true;
      speed = 3;
      bezier = "ease_quick";
    })
    (animation {
      leaf = "workspaces";
      enabled = true;
      speed = 6;
      spring = "spring_workspace";
      style = "slidefade 18%";
    })
    (animation {
      leaf = "specialWorkspace";
      enabled = true;
      speed = 5;
      spring = "spring_drawer";
      style = "slidefadevert 22%";
    })
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
      match = {tag = "marked";};
      border_size = 12;
      rounding = 0;
      border_color = "${rgb colors.base09} ${rgb colors.base09}";
    }
    {
      match = {pin = true;};
      border_color = {
        colors = [(rgb colors.base09) (rgb colors.base0A)];
        angle = 45;
      };
    }
  ];

  on = {
    _args = [
      "hyprland.start"
      (mkLuaInline ''
        function()
          if not (hl.plugin and hl.plugin.hyprbars) then
            return
          end
          hl.plugin.hyprbars.add_button({
            bg_color = "rgb(${colors.base08})",
            fg_color = "rgb(${colors.base00})",
            size = 10,
            icon = "x",
            action = "${cfg.hyprctl} dispatch killactive",
          })
        end
      '')
    ];
  };
}

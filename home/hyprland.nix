{
  nixosConfig,
  osConfig,
  config,
  pkgs,
  lib,
  ...
}:
with pkgs; let
  inherit (nixosConfig._module.specialArgs) nix-config;
  inherit (nixosConfig._module.specialArgs.nix-config.inputs) hyprsunset hyprpicker hyprland-hy3 hyprland-plugins quickshell;
  stylix = config.lib.stylix.colors;
  inherit (nix-config.packages.${pkgs.system}) vim-hy3-nav;
  opacity = "0.95";

  mod = "SUPER";

  toggle = program: let
    prog = builtins.substring 0 14 program;
  in "pkill ${prog} || uwsm app -- ${program}";

  runOnce = program: "pgrep ${program} || uwsm app -- ${program}";

  workspaces = ["1" "2" "3" "4" "5" "6" "7" "8" "9"];
  # Map keys (arrows and hjkl) to hyprland directions (l, r, u, d)
  directions = rec {
    left = "l";
    right = "r";
    up = "u";
    down = "d";
    h = left;
    l = right;
    k = up;
    j = down;
  };
in {
  imports = [
    ../quickshell
  ];
  home.packages = with pkgs; [
    hyprpicker.packages.${pkgs.system}.hyprpicker
    hyprsunset.packages.${pkgs.system}.hyprsunset
    quickshell.packages.${pkgs.system}.quickshell
    hyprpolkitagent
    mpvpaper
    wf-recorder
    playerctl
    socat
    inotify-tools
    grimblast
  ];
  #

  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;

    plugins = [
      hyprland-plugins.packages.${pkgs.system}.hyprbars
      hyprland-hy3.packages.${pkgs.system}.hy3
    ];

    settings = {
      env = [
        "BROWSER,firefox"
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_DESKTOP,Hyprland"
      ];

      monitor = [
        "DP-1,5120x1440@120,auto,1"
        #"DP-2,1920x1080,auto-left,1"
      ];

      exec = [
        "xrandr --output DP-1 --primary"
      ];

      exec-once = [
        "uwsm finalize"
        "mullvad connect"

        "systemctl --user start hyprpolkitagent"
        "wpctl set-volume @DEFAULT_SINK@ 40%"
        "quickshell"
        "[workspace 1 silent; float] youtube-music"
        "[workspace 1 silent; float] bitwarden"

        "[workspace 2 silent] firefox"

        "[workspace 3 silent] emacs --fg-daemon"
        "[workspace 3 silent] kitty"

        "[workspace 4 silent; float ] steam"
        "[workspace 4 silent; float] discord"
        "[workspace 4 silent; float] signal-desktop"
        "[workspace 4 silent; float] telegram-desktop"
        "hyprctl dispatch workspace 2"
      ];

      input = {
        kb_layout = "us";
        repeat_rate = 50;
        repeat_delay = 300;

        accel_profile = "flat";
        follow_mouse = 1;
        sensitivity = 0;
        mouse_refocus = false;

        touchpad = {
          natural_scroll = true;
          disable_while_typing = false;
        };
      };

      cursor = {
        inactive_timeout = 10;
        default_monitor = "DP-1";
        no_hardware_cursors = true;
        enable_hyprcursor = false;
        no_break_fs_vrr = true;
      };

      general = {
        gaps_in = 0;
        gaps_out = "-4";
        border_size = 4;
        layout = "hy3";

        snap = {
          enabled = true;
          window_gap = 50;
          monitor_gap = 20;
          border_overlap = true;
        };
      };

      render = {
        direct_scanout = false;
      };

      decoration = {
        rounding = 0;
        dim_special = "0.0";

        shadow = {
          enabled = true;
          range = 30;
          render_power = 3;
        };

        blur = {
          enabled = true;
          size = 5;
          passes = 2;
        };
      };

      animations = {
        enabled = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";

        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 8, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default, slidevert"
          "specialWorkspace, 1, 6, default, slidevert"
        ];
      };

      dwindle = {
        preserve_split = false;
        default_split_ratio = "1";
        split_width_multiplier = "1";
        special_scale_factor = 1;
        split_bias = 1;
      };

      master = {
        mfact = 0.44;
        special_scale_factor = 0.8;
        allow_small_split = false;
        new_status = "inherit";
        new_on_top = true;
        inherit_fullscreen = false;
        orientation = "center";
        #always_center_master = true;
        slave_count_for_center_master = 2;
        center_master_slaves_on_right = false;
        center_ignores_reserved = true;
      };

      plugin = {
        hyprbars = {
          bar_height = 30;
          bar_text_size = 13;
          bar_color = "rgb(${stylix.base01})";
          bar_text_font = config.wayland.windowManager.hyprland.settings.misc.font_family;

          hyprbars-button = [
            "rgb(ff4040), 10, 󰖭, hyprctl dispatch killactive"
            "rgb(eeee11), 10, , hyprctl dispatch float 1"
          ];
        };

        hy3 = {
          no_gaps_when_only = 1;
          node_collapse_policy = 1;
          group_inset = 0;
          tab_first_window = false;

          tabs = {
            height = 38;
            padding = 0;
            text_height = 13;
            radius = config.wayland.windowManager.hyprland.settings.decoration.rounding;
            border_width = config.wayland.windowManager.hyprland.settings.general.border_size;
            text_font = config.wayland.windowManager.hyprland.settings.misc.font_family;
            opacity = "0.9";
            # TODO use stylix
            "col.active" = "rgba(${stylix.base02}ff)"; # default: rgba(50a0e0ff)
            "col.active.border" = config.wayland.windowManager.hyprland.settings.group."col.border_active";
            "col.active.text" = "rgba(${stylix.base0B}ff)"; # default: rgba(ffffffff)

            # focused tab bar segment colors (focused node in unfocused container)
            "col.focused" = "rgba(${stylix.base00}f2)";
            "col.focused.border" = config.wayland.windowManager.hyprland.settings.group."col.border_active";
            "col.focused.text" = "rgba(${stylix.base0B}ff)"; # default: rgba(ffffffff)

            # inactive tab bar segment colors
            "col.inactive" = "rgba(${stylix.base00}f2)"; # default: rgba(30303050)
            "col.inactive.border" = config.wayland.windowManager.hyprland.settings.group."col.border_inactive";
            "col.inactive.text" = "rgba(${stylix.base04}ff)"; # default: rgba(ffffffff)

            # urgent tab bar segment colors
            "col.urgent" = "rgba(${stylix.base0E}f2)"; # default: rgba(ff4f4fff)
            "col.urgent.border" = "rgba(${stylix.base0E}ff)"; # default: rgba(ff8080ff)
            "col.urgent.text" = "rgba(${stylix.base02}ff)"; # default: rgba(ffffffff)
          };
          # Based on a 5120x1440, 32:9 display
          autotile = {
            enable = true;
            epherhemeral_groups = true;
            trigger_width = 1150;
            trigger_height = 525;
          };
        };
      };

      gestures = {workspace_swipe = true;};

      binds = {allow_workspace_cycles = true;};

      layerrule = ["blur,wofi" "blur,notifications"];

      windowrulev2 = [
        "plugin:hyprbars:nobar, floating:0"
        "tag +terminal, class:kitty"

        # Specific Game / Launcher Rules
        "content game, class:^(steam_app.*|Waydroid|osu!|RimWorldLinux)$"
        "content game, title:^(UNDERTALE)$"

        #"nomaxsize,class:^(winecfg.exe|osu.exe)$"
        "nodim,content:game"
        "nodim,content:video"
        #"nodim,workspace:m[DP-2]"
        #"nodim,workspace:s[true]"

        # Classify Video content and picture in picture tags
        "content video, class:mpv"
        "content video, title:Picture-in-Picture"
        "tag +pip, title:Picture-in-Picture"

        # Video Content Rules
        "idleinhibit always, content:video"
        "noborder, content:video"

        # Picture in picture specific rules
        "suppressevent activatefocus, content:video, tag:pip"
        "float, content:video, tag:pip"
        "pin, content:video, tag:pip"
        "noinitialfocus, content:video, tag:pip"
        "move 100%-99%, content:video, tag:pip"

        # Tag Launchers
        "tag +launcher, initialTitle:Battle.net"

        # Launchers
        "float, tag:launcher"
        "size 1680 1080, tag:launcher"
        "workspace unset, tag:launcher"

        # Game Content Rules
        "monitor DP-1, content:game"
        "workspace 5, content:game"
        "noborder 1, content:game"
        "noblur 1, content:game"
        "xray 1, content:game"
        "noanim 1, content:game"
        "group deny, content:game"
        "idleinhibit always, content:game"

        # Game Specific Rules
        "fullscreenstate 1 2, initialTitle:(World of Warcraft)"

        # Misc Windows
        "float, title:^(Extension: (Bitwarden - Free Password Manager).*)$"
        "float, title:^(KeePassXC -  Access Request)$"
        "float, title:^(Unlock Database - KeePassXC)$"
        "float, class:^(thunar|com.saivert.pwvucontrol|RimPy)$"
        "float, class:(org.keepassxc.KeePassXC)"
        "float, title:^(Sign In - Google Accounts.*)$"

        "move onscreen 100% 0%, class:^(com.saivert.pwvucontrol)$"
        "tile,class:^(.qemu-system-x86_64-wrapped)$"
        "opacity ${opacity} ${opacity},class:^(thunar)$"
      ];

      workspace = [
        "1, monitor:DP-1, layoutopt:orientation:center"
        "2, monitor:DP-1, layoutopt:orientation:center, default:true"
        "3, monitor:DP-1, layoutopt:orientation:center"
        "4, monitor:DP-1, layoutopt:orientation:right"
        "5, monitor:DP-1, layoutopt:orientation:left"

        "m[DP-2], layoutopt:orientation:left, decorate:false, shadow:false"
        "6, monitor:DP-2, default:true"
        "7, monitor:DP-2"
        "8, monitor:DP-2"
        "9, monitor:DP-2"
        "0, monitor:DP-2"
        "special:scratchpad, on-created-empty:[monitor DP-1;float;size 25% 35%; move 37.5% 100%;]kitty"
      ];

      ecosystem = {
        no_update_news = true;
        no_donation_nag = true;
      };

      misc = {
        disable_hyprland_logo = true;
        focus_on_activate = true;
        animate_manual_resizes = true;
        animate_mouse_windowdragging = true;
        disable_autoreload = true;
        new_window_takes_over_fullscreen = 1;
        initial_workspace_tracking = 0;
        font_family = "IosevkaTerm Nerd Font";
      };

      bind =
        [
          # Hy3 Groups
          "${mod}CONTROL, G, hy3:changegroup, toggletab"
          "${mod}, tab, hy3:focustab, r, wrap"
          "${mod}SHIFT, tab, hy3:focustab, l, wrap"

          "${mod}CONTROL, left, hy3:makegroup, h"
          "${mod}CONTROL, right, hy3:makegroup, h"
          "${mod}CONTROL, down, hy3:makegroup, v"
          "${mod}CONTROL, up, hy3:makegroup, v"

          # Bar
          #"${mod}CONTROL, B, exec, ${toggle "waybar"}"

          ##window management
          "${mod}SHIFT, Q, killactive,"

          "${mod}CONTROL, F, togglefloating"
          "${mod}CONTROL, P, pin"
          "${mod}CONTROL, M, fullscreen"

          # Search
          "${mod}, d, exec, ${wofi}/bin/wofi  --show drun"
          "${mod}, p, exec, ${wofi-pass}/bin/wofi-pass"
          "${mod}, e, exec, ${wofi-emoji}/bin/wofi-emoji"

          "${mod}, Space, exec, quickshell ipc call launcher toggle"
          #"${mod}, Space, exec, ${wofi}/bin/wofi  --show drun"
          "${mod}, Return, exec, uwsm app -- kitty"

          #"${mod}, c, exec, ${cliphist}/bin/cliphist list | ${toggle "${wofi}/bin/wofi --show dmenu"} | ${cliphist}/bin/cliphist decode | ${wl-clipboard}/bin/wl-copy"
        ]
        ++
        # Change focused workspace
        (map (n: "${mod},${n},workspace,${n}") workspaces)
        ++
        # Move window to workspace
        (map (n: "${mod}SHIFT,${n},hy3:movetoworkspace,${n}, silent")
          workspaces)
        ++
        # Move focus to Hy3 Tab
        (map (n: "${mod}ALT,${n},hy3:focustab, index, ${n}")
          workspaces)
        ++
        # Move focus in a direction
        (lib.mapAttrsToList (key: direction: "${mod},${key},exec,vim-hy3-nav ${direction}") directions)
        #(lib.mapAttrsToList (key: direction: "${mod},${key},hy3:movefocus,${direction}, visible") directions)
        ++
        # Move windows between visible nodes
        (lib.mapAttrsToList (key: direction: "${mod}SHIFT,${key},hy3:movewindow,${direction},once,visible") directions)
        ++
        # Move windows between invisible nodes (tabs)
        (lib.mapAttrsToList (key: direction: "${mod}SHIFTCONTROL,${key},hy3:movewindow,${direction},once") directions)
        ++
        # Open next window in given direction
        (lib.mapAttrsToList (key: direction: "${mod}CONTROL,${key},layoutmsg,preselect ${direction}")
          directions);
      /*

      bind =
        [
          # Group Settings
          "${mod}CONTROL, G, togglegroup"
          # Dwindle Layout Messages
          "${mod}CONTROL, S, layoutmsg, togglesplit"
          "${mod}CONTROL, Space, layoutmsg, swapsplit"
          "${mod}CONTROL, R, layoutmsg, movetoroot active"
          # Master Layout Messages
          "${mod}CONTROL, R, layoutmsg, mfact exact 0.5"
          "${mod}CONTROL, U, layoutmsg, mfact exact 0.65"
          "${mod}CONTROL, L, layoutmsg, orientationleft"
          "${mod}CONTROL, C, layoutmsg, orientationcenter"

          "${mod}, tab, changegroupactive, f"
          "${mod}SHIFT, tab, changegroupactive, b"

          # Bar
          "${mod}CONTROL, B, exec, ${toggle "waybar"}"
          ##window management
          "${mod}SHIFT, Q, killactive,"
          "${mod}SHIFT, L, lockactivegroup, toggle"

          "${mod}CONTROL, M, fullscreen"
          "${mod}CONTROL, F, togglefloating"
          "${mod}CONTROL, P, pin"

          # Swap Layouts
          "${mod}CONTROL, D, exec, hyprctl keyword general:layout dwindle"
          "${mod}CONTROL, M, exec, hyprctl keyword general:layout master"

          # Search
          "${mod}, d, exec, ${wofi}/bin/wofi  --show drun"
          "${mod}, p, exec, ${wofi-pass}/bin/wofi-pass"
          "${mod}, e, exec, ${wofi-emoji}/bin/wofi-emoji"

          "${mod}, Space, exec, ${wofi}/bin/wofi  --show drun"
          "${mod}, Return, exec, uwsm app -- kitty"
        ]
        ++
        # Change workspace//
        (map (n: "${mod},${n},workspace,${n}") workspaces)
        ++
        # Move window to workspace
        (map (n: "${mod}SHIFT,${n},movetoworkspacesilent,${n}")
          workspaces)
        ++
        # Move focus, changes focus of nvim windows too
        (lib.mapAttrsToList (key: direction: "${mod},${key},exec, ${vim-hypr-nav}/bin/vim-hypr-nav ${direction}")
          directions)
        ++
        # Move windows
        (lib.mapAttrsToList (key: direction: "${mod}SHIFT,${key},movewindoworgroup,${direction}") directions)
        ++
        # Open next window in given direction in dwindle
        (lib.mapAttrsToList (key: direction: "${mod}CONTROL,${key},layoutmsg,preselect ${direction}")
          directions);
      */
      bindm = ["SUPER, mouse:272, movewindow" "SUPER, mouse:273, resizewindow"];

      binde = [
        # Change Split Ratio for new splits
        "${mod},minus,splitratio,-0.05"
        "${mod}SHIFT,minus,splitratio,-0.125"
        "${mod},plus,splitratio,0.05"
        "${mod}SHIFT,plus,splitratio,0.125"

        # Resize windows with mainMod + SUPER + arrow keys
        "${mod}ALT, left, resizeactive, 75 0"
        "${mod}ALT, right, resizeactive, -75 0"
        "${mod}ALT, up, resizeactive, 0 -75"
        "${mod}ALT, down, resizeactive, 0 75"
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_SINK@ 5%-"
        ", XF86AudioForward, exec, playerctl -p playerctld position 10+"
        ", XF86AudioRewind, exec, playerctl -p playerctld position 10-"
      ];

      bindl = [
        ", XF86AudioPrev, exec, playerctl -p playerctld previous"
        ", XF86AudioNext, exec, playerctl -p playerctld next"
        ", XF86AudioPlay, exec, playerctl -p playerctld play"
        ", XF86AudioPause, exec, playerctl -p playerctld pause"
        ", XF86Messenger, togglespecialworkspace"
      ];
    };

    extraConfig =
      # hyprlang
      ''
        bind = ${mod}ALT, BackSpace, submap, passthrough
        submap = passthrough
        bind = ${mod}ALT, BackSpace, submap, reset
        submap = reset

          bind = ${mod}, A, submap, openApps
        submap = openApps
          bind = , Return, exec, uwsm app -- kitty
          bind = , Return ,submap, reset
          bind = , W, exec, uwsm app -- firefox
          bind = , W,submap, reset
          bind = , D, exec, uwsm app -- discord
          bind = , D,submap, reset
          bind = , S, exec, grimblast copy area
          bind = , S,submap, reset
          bind = , Space, exec, quickshell ipc call launcher toggle
          bind = , Space ,submap, reset
          bind = , V, exec, uwsm app -- pwvucontrol
          bind = , V,submap, reset
          bind = , T, submap, openTerminal
          bind = , catchall, submap, reset
          submap = reset
        bind = ${mod}, T, submap, openTerminal
        submap = openTerminal
          bind = , Return, exec, uwsm app -- kitty
          bind = , Return ,submap, reset
          bind = , T, exec, uwsm app -- kitty
          bind = , T,submap, reset
          bind = , E, exec, uwsm app -- kitty nvim
          bind = , E,submap, reset
          bind = , ., exec, uwsm app -- kitty yazi
          bind = , .,submap, reset
          bind = , F, exec, uwsm app -- kitty yazi
          bind = , F,submap, reset
          bind = , ?, exec, uwsm app -- kitty zenith
          bind = , ?,submap, reset
          bind = , catchall, submap, reset
          submap = reset
      '';
  };

  services = {
    hyprpaper = {
      enable = true;
      settings = {
        ipc = "on";
        splash = false;
        splash_offset = 2.0;

        preload = ["${config.xdg.userDirs.pictures}/wallpaper/32:9/pixel-horizon.png"];

        wallpaper = [
          "DP-1, ~/media/pictures/wallpaper/32:9/pixel-horizon.png"
          "DP-2,${config.xdg.userDirs.pictures}/wallpaper/32:9/pixel-horizon.png"
        ];
      };
    };
  };
  services.hypridle = {
    enable = true;

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
  systemd.user.services.hypridle.Unit.After = lib.mkForce "graphical-session.target";
  programs.hyprlock = {
    enable = true;

    settings = {
      general = {
        hide_cursor = true;
        grace = 2;
      };

      background = {
        #color = "rgba(25, 20, 20, 1.0)";
        #path = "screenshot";
        blur_passes = 2;
        brightness = 0.5;
      };

      label = {
        text = "Welcome";
        #color = "rgba(222, 222, 222, 1.0)";
        font_size = 50;
        font_family = "Noto Sans";
        position = "0, 70";
        halign = "center";
        valign = "center";
      };

      input-field = {
        size = "50, 50";
        dots_size = 0.33;
        dots_spacing = 0.15;
        #outer_color = "rgba(25, 20, 20, 0)";
        #inner_color = "rgba(25, 20, 20, 0)";
        #font_color = "rgba(222, 222, 222, 1.0)";
      };
    };
  };
}

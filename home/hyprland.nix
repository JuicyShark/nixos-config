{
  nixosConfig,
  osConfig,
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkForce;
  inherit (nixosConfig._module.specialArgs) nix-config;
  inherit (nix-config.packages.${pkgs.system}) osu-backgrounds dunst-scripts  vim-hypr-nav;
  inherit (nix-config.inputs.hyprland.packages.${pkgs.system}) hyprland;
  opacity = "0.95";

  dynamicGapsScript = "hypr/dynamicGapsScript.zsh";
  gapsScript = "hypr/gaps.zsh";
  randomBackgroundScript = "hypr/random-bg.zsh";
  swapBackgroundScript = "hypr/swap-bg.zsh";
  setBackgroundScript = "hypr/set-bg.zsh";

  super = "SUPER";
  appLaunchBind =
    if osConfig.hardware.keyboard.zsa.enable
    then "ALT SHIFT CTRL"
    else "SUPER";

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
  home.packages = with pkgs; [
    hyprsunset
    hyprpolkitagent
    hyprpicker
    vesktop
    swww
    grimblast
    mpvpaper
    wf-recorder
    playerctl
    socat
  ];
  home.programs.ags.enable = true;
  wayland.windowManager.hyprland = {
    enable = true;
    package = hyprland;
    systemd = {
      enable = false;
      variables = ["--all"];

      extraCommands = [
        "systemctl --user stop graphical-session.target"
        "systemctl --user start hyprland-session.target"
      ];
    };
    settings = {
      env = [
        "BROWSER,firefox"
        "SWWW_TRANSITION,grow"
        "SWWW_TRANSITION_STEP,200"
        "SWWW_TRANSITION_DURATION,1.5"
        "SWWW_TRANSITION_FPS,120"
        "SWWW_TRANSITION_WAVE,80,40"
        "QT_QPA_PLATFORMTHEME,qt5ct"
        "QT_STYLE_OVERRIDE,kvantum"
      ];

      monitor = [",highrr,auto,1" "HDMI-A-1,highrr,auto-left,1"];
      exec = [
        "xrandr --output DP-1 --primary"
      ];
      exec-once = [
        "uwsm finalize"
        "sleep 0.1; swww-daemon"
        "waybar"
        "wpctl set-volume 88 40%"
        "hyprctl dispatch workspace 2"
        "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent"
        "~/.config/${randomBackgroundScript}"
        "steam"
        "vesktop"
        "firefox"
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
        no_break_fs_vrr = true;
      };

      general = {
        gaps_in = 0;
        gaps_out = 0;
        border_size = 2;
        layout = "master";

        snap = {
          enabled = true;
          window_gap = 50;
          monitor_gap = 20;
          border_overlap = true;
        };
      };

      render = {
        direct_scanout = true;
      };

      group = {
        auto_group = false;
        drag_into_group = 2;
        merge_groups_on_drag = false;
        merge_groups_on_groupbar = true;
        groupbar = {
          font_size = 13;
          gradients = true;
          scrolling = false;
        };
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
        preserve_split = true;
        default_split_ratio = "1.25";
        split_width_multiplier = "1.1";
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
        always_center_master = true;
        center_ignores_reserved = true;
      };

      gestures = {workspace_swipe = true;};

      binds = {allow_workspace_cycles = true;};

      layerrule = ["blur,ironbar" "blur,rofi" "blur,notifications"];

      windowrulev2 = [

        "tag +terminal, class:terminal"

        "tag media, class:mpv"
        "tag media, title:Picture-in-Picture"
        "tag games, class:^(steam_app.*|Waydroid|osu!|RimWorldLinux)$"
        "tag games, title:^(UNDERTALE)$"


        #"nomaxsize,class:^(winecfg.exe|osu.exe)$"
        "opaque,class:^(terminal)$"
        "noblur,class:^(terminal)$"
        "nodim,tag:games"
        "nodim,tag:media"
        "nodim,tag:games"
        "nodim,workspace:m[HDMI-A-1]"
        "nodim,workspace:s[true]"

        "float,title:Picture-in-Picture"
        "noinitialfocus,title:Picture-in-Picture"
        "move 100%-99%,title:Picture-in-Picture"

        "idleinhibit always, tag:media"
        "noborder, tag:media"
        "monitor DP-1, class:^(steam_app.*|Waydroid|osu!|RimWorldLinux)$"
        "workspace 5, class:^(steam_app.*|Waydroid|osu!|RimWorldLinux)$"
        "tile, class:^(steam_app.*|Waydroid|osu!|RimWorldLinux)$"
        "noborder 1, tag:games"
        "noblur 1, tag:games"
        "xray 1, tag:games"
        "noanim 1, tag:games"
        "group deny, tag:games"
        "idleinhibit always, tag:games"
        "float, class:^(thunar|com.saivert.pwvucontrol|RimPy)$"
        "float, title:^(Extension: (Bitwarden - Free Password Manager).*)$"

        "move onscreen 100% 0%, class:^(com.saivert.pwvucontrol)$"
        "tile,class:^(.qemu-system-x86_64-wrapped)$"
        "opacity ${opacity} ${opacity},class:^(thunar)$"
        "pin,floating:1"
      ];

      workspace = [
        "1, monitor:DP-1, layoutopt:orientation:center"
        "2, monitor:DP-1, layoutopt:orientation:center, default:true"
        "3, monitor:DP-1, layoutopt:orientation:center"
        "4, monitor:DP-1, layoutopt:orientation:right"
        "5, monitor:DP-1, layoutopt:orientation:left"

        "m[HDMI-A-1], layoutopt:orientation:left, decorate:false, shadow:false"
        "6, monitor:HDMI-A-1, default:true"
        "7, monitor:HDMI-A-1"
        "8, monitor:HDMI-A-1"
        "9, monitor:HDMI-A-1"
        "0, monitor:HDMI-A-1"
        "special:scratchpad, on-created-empty:[monitor DP-1;float;size 25% 35%; move 37.5% 100%;]foot"
      ];

      misc = {
        disable_hyprland_logo = true;
        focus_on_activate = true;
        animate_manual_resizes = true;
        animate_mouse_windowdragging = true;
        disable_autoreload = true;
        new_window_takes_over_fullscreen = 1;
        initial_workspace_tracking = 0;
      };

      bind =
        [
          # Group Settings
          "${super}CONTROL, G, togglegroup"
          "${super}CONTROL, S, layoutmsg, togglesplit"
          "${super}CONTROL, R, layoutmsg, swapsplit"
          "${super}CONTROL, R, layoutmsg, mfact exact 0.5"
          "${super}CONTROL, U, layoutmsg, mfact exact 0.65"
          "${super}CONTROL, L, layoutmsg, orientationleft"
          "${super}CONTROL, C, layoutmsg, orientationcenter"
          "${super}CONTROL, T, layoutmsg, movetoroot active"
          "${super}CONTROL, D, exec, hyprctl keyword general:layout dwindle"
          "${super}CONTROL, M, exec, hyprctl keyword general:layout master"
          "${super}, tab, changegroupactive, f"
          "${super}SHIFT, tab, changegroupactive, b"

          # Discord
          "${super}SHIFT, M, sendshortcut, CONTROLSHIFT, M, ^(discord)$"
          "${super}SHIFT, D, sendshortcut, CONTROLSHIFT, D, ^(discord)$"
          "${super}CONTROL, Q, pass, ^(discord)$"
          "${super}, V, pass, ^(discord)$"

          ##window management
          "${super}SHIFT, Q, killactive,"
          "${super}SHIFT, L, lockactivegroup, toggle"

          "${super}SHIFT, F, togglefloating"
          "${super}CONTROL, F, fullscreen"
          "${super}, space, togglespecialworkspace, scratchpad"
          "${super}SHIFT, P, pin"

          # Default Apps
          "${appLaunchBind}, Return, exec, uwsm app -- foot"
          "${appLaunchBind}SHIFT, Return, togglespecialworkspace, scratchpad"
          "${appLaunchBind}, W, exec, uwsm app -- firefox"
          "${appLaunchBind}, D, exec, uwsm app -- discord"
          "${appLaunchBind}, M, exec, uwsm app -- tidal-hifi"
          "${appLaunchBind}, S, exec, ${runOnce "grimblast"} --notify copysave area"
        ] ++
        # Launcher
        (["${appLaunchBind}, Space,  exec, ${toggle "rofi"} -show drun"]
          ++ (let
            cliphist = lib.getExe config.services.cliphist.package;
          in
            lib.optionals config.services.cliphist.enable [
              "${appLaunchBind}, C, exec, ${cliphist} list | rofi -dmenu | ${cliphist} decode | wl-copy"
            ]))
        ++
        # Change workspace//
        (map (n: "${super},${n},workspace,name:${n}") workspaces)
        ++
        # Move window to workspace
        (map (n: "$Hu{super}SHIFT,${n},movetoworkspacesilent,name:${n}")
          workspaces)
        ++
        # Move focus
        (lib.mapAttrsToList (key: direction: "${super},${key},exec, ${vim-hypr-nav}/bin/vim-hypr-nav ${direction}")
          directions)
        ++
        # Move windows
        (lib.mapAttrsToList (key: direction: "${super}SHIFT,${key},movewindoworgroup,${direction}") directions)
        ++
        # Open next window in given direction
        (lib.mapAttrsToList (key: direction: "${super}CONTROL,${key},layoutmsg,preselect ${direction}")
          directions);

      bindm = ["SUPER, mouse:272, movewindow" "SUPER, mouse:273, resizewindow"];

      binde = [
        # Change Split Ratio for new splits
        "${super},minus,splitratio,-0.05"
        "${super}SHIFT,minus,splitratio,-0.125"
        "${super},equal,splitratio,0.05"
        "${super}SHIFT,equal,splitratio,0.125"
        # Resize windows with mainMod + SUPER + arrow keys
        "${super}ALTSHIFT, left, resizeactive, 75 0"
        "${super}ALTSHIFT, right, resizeactive, -75 0"
        "${super}ALTSHIFT, up, resizeactive, 0 -75"
        "${super}ALTSHIFT, down, resizeactive, 0 75"
        ", XF86AudioRaiseVolume, exec, ${dunst-scripts}/bin/mv-up"
        ", XF86AudioLowerVolume, exec, ${dunst-scripts}/bin/mv-down"
        ", XF86AudioForward, exec, playerctl -p playerctld position 10+"
        ", XF86AudioRewind, exec, playerctl -p playerctld position 10-"
      ];

      bindl = [
        ", XF86AudioMute, exec, ${dunst-scripts}/bin/mv-mute"
        ", XF86AudioMicMute, exec, ${dunst-scripts}/bin/mv-mic"
        ", XF86MonBrightnessDown, exec, ${dunst-scripts}/bin/mb-down"
        ", XF86MonBrightnessUp, exec, ${dunst-scripts}/bin/mb-up"
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
        bind = ${super}ALT, BackSpace, submap, passthrough
        submap = passthrough
        bind = ${super}ALT, BackSpace, submap, reset
        submap = reset

        bind = ${appLaunchBind}, T, submap, openTerminal
        submap = openTerminal
          bind = , Return, exec, uwsm app -- foot
          bind = , T, exec, uwsm app -- foot
          bind = , E, exec, uwsm app -- foot nvim
          bind = , ., exec, uwsm app -- foot yazi
          bind = , f, exec, uwsm app -- foot yazi
          bind = , ?, exec, uwsm app -- foot zenith
        bind = , catchall, submap, reset
        submap = reset
      '';
  };

  xdg.configFile = {
    "${dynamicGapsScript}" = {
      executable = true;
      text = ''
        #!/usr/bin/env zsh
        function handle() {
          if [[ ''${1:0:10} == "focusedmon" ]]; then
            if [[ ''${1:12:4} == "DP-1" ]]; then
              hyprctl keyword general:gaps_in 0
            else
              hyprctl keyword general:gaps_in 45
            fi
          fi
        }
        socat - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
          handle "$line"
        done
      '';
    };

    "${gapsScript}" = {
      executable = true;
      text = ''
        #!/usr/bin/env zsh

        # Function to toggle gaps and border settings
        toggle_settings() {
          local current_gaps_out=$(hyprctl getoption general:gaps_out -j | jq -r ".custom" | awk '{print $1}')
          local current_gaps_in=$(hyprctl getoption general:gaps_in -j | jq -r ".custom" | awk '{print $1}')
          local current_border_size=$(hyprctl getoption general:border_size -j | jq -r ".int")
          local current_rounding=$(hyprctl getoption decoration:rounding -j | jq -r ".int")

          # Toggle gaps_out
          local new_gaps_out=$((10 - current_gaps_out))
          hyprctl keyword general:gaps_out "$new_gaps_out"

          # Toggle gaps_in
          local new_gaps_in=$((5 - current_gaps_in))
          hyprctl keyword general:gaps_in "$new_gaps_in"

          # Toggle border_size
          local new_border_size=$((2 - current_border_size))
          hyprctl keyword general:border_size "$new_border_size"

          # Toggle rounding
          local new_rounding=$((8 - current_rounding))
          hyprctl keyword decoration:rounding "$new_rounding"
        }

        toggle_settings
      '';
    };

    "${setBackgroundScript}" = {
      executable = true;
      text = ''
        #!/usr/bin/env zsh

        # Check if animations are enabled
        local animations_enabled=$(hyprctl getoption animations:enabled -j | jq -r ".int")

        # Array of transition types for animated transitions
        local animated_transitions=(grow wave outer)
        local transition_angles=(45 90 135 225 270 315)
        local transition_positions=(center top left right bottom top-left top-right bottom-left bottom-right)

        # Function to get a random array element
        random_element() {
          local arr=("$@")
          echo "''${arr[RANDOM % ''${#arr[@]} + 1]}"
        }

        # Set background with transitions
        if [[ "$animations_enabled" == "1" ]]; then
          swww img \
            --transition-type "$(random_element "''${animated_transitions[@]}")" \
            --transition-wave 80,40 \
            --transition-angle "$(random_element "''${transition_angles[@]}")" \
            --transition-pos "$(random_element "''${transition_positions[@]}")" \
            --transition-step 200 \
            --transition-duration 1.5 \
            --transition-fps 240 \
            --outputs "$1" \
            "$2"
        else
          swww img \
            --transition-type simple \
            --transition-step 255 \
            --outputs "$1" \
            "$2"
        fi
      '';
    };

    "${randomBackgroundScript}" = {
      executable = true;
      text = ''
        #!/usr/bin/env zsh

        # Get list of monitors
        local monitors=($(hyprctl monitors -j | jq -r '.[].name'))

        # Get list of background images
        local backgrounds=($(fd . ${osu-backgrounds}/2024-10-09-Autumn-2024-Fanart-Contest-All-Entries --follow -e jpg -e png))

        # Iterate through monitors and set random backgrounds
        for monitor in "''${monitors[@]}"; do
          local random_bg=$(echo "''${backgrounds[RANDOM % ''${#backgrounds[@]} + 1]}")
          ~/.config/${setBackgroundScript} "$monitor" "$random_bg"
        done
      '';
    };

    "${swapBackgroundScript}" = {
      executable = true;
      text = ''
        #!/usr/bin/env zsh

        # Get current backgrounds
        local backgrounds=($(swww query | cut -d ':' -f 5))
        local M1="$(echo "''${backgrounds[1]}" | awk '{$1=$1};1')"
        local M2="$(echo "''${backgrounds[2]}" | awk '{$1=$1};1')"

        # Swap backgrounds
        ~/.config/${setBackgroundScript} "$(swww query | choose 0 | choose -c 0..-1 | tail -n 1)" "$M1"
        ~/.config/${setBackgroundScript} "$(swww query | choose 0 | choose -c 0..-1 | head -n 1)" "$M2"
      '';
    };
  };

  systemd.user = {
    services = {
      hyprland-dynamic-gaps = {
        Unit = {
          Description = "Hyprland Dynamic Gaps Script";
          PartOf = [ "hyprland-session.target" ];
        };

        Service = {
          ExecStart = "${pkgs.zsh}/bin/zsh ${config.home.homeDirectory}/.config/hypr/dynamic-gaps.zsh";
          Restart = "on-failure";
        };

        Install = {
          WantedBy = [ "hyprland-session.target" ];
        };
      };

      hyprsunset = {
        Unit = {
          Description = "Hyprsunset - nighttime";
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${lib.getExe pkgs.hyprsunset} -t 4750";
        };
      };
    };

    timers = {
      # if after 8pm Hypersunset is active
      hyprsunset= {
        Unit = {
          Description = "Hyprsunset - a blue-light filter";
          PartOf = [ "hyprland-session.target" ];
          After = [ "hyprland-session.target" ];
        };
        Timer = {
          OnCalendar = "*-*-* 20:00:00";
          Unit = "hyprsunset.service";
          Persistent = true;
        };
        Install = {
          WantedBy = [ "hyprland-session.target" ];
        };
      };
    };
  };
  services = {hyprpaper.enable = mkForce false;};
}

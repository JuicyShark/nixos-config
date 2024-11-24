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
  inherit (nix-config.packages.${pkgs.system}) osu-backgrounds dunst-scripts;
  inherit (nix-config.packages.${pkgs.system}) vim-hypr-nav;
  inherit (nix-config.inputs.hyprland.packages.${pkgs.system}) hyprland;
  opacity = "0.95";

  gapsScript = "hypr/gaps.fish";
  randomBackgroundScript = "hypr/random-bg.fish";
  swapBackgroundScript = "hypr/swap-bg.fish";
  setBackgroundScript = "hypr/set-bg.fish";

  super = "SUPER";
  appLaunchBind =
    if osConfig.hardware.keyboard.zsa.enable
    then "ALT SHIFT CTRL"
    else "SUPER";

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
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    package = hyprland;
    systemd = {
      variables = ["--all"];

      extraCommands = [
        "systemctl --user stop graphical-session.target"
        "systemctl --user start hyprland-session.target"
      ];
    };
    settings = {
      env = [
        "BROWSER,firefox"
        "GLFW_IM_MODULE,ibus"
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
        "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "xrandr --output DP-1 --primary"
      ];
      exec-once = [
        "sleep 0.1; swww-daemon"
        "wpctl set-volume @DEFAULT_AUDIO_SINK@ 20%"
        "waybar"
        "hyprctl dispatch workspace 2"
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
        "hyprdim --no-dim-when-only --persist --ignore-leaving-special --dialog-dim"
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
          window_gap = 25;
          monitor_gap = 35;
          border_overlap = true;
        };
      };

      group = {
        auto_group = false;
        drag_into_group = 2;
        merge_groups_on_drag = false;
        merge_groups_on_groupbar = true;
        groupbar = {
          font_size = 13;
          gradients = false;
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
        mfact = 0.55;
        special_scale_factor = 0.8;
        allow_small_split = false;
        new_status = "master";
        new_on_top = true;
        inherit_fullscreen = false;
        orientation = "center";
        always_center_master = true;
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
          "${appLaunchBind}, Return, exec, foot"
          "${appLaunchBind}, T, exec, foot"
          "${appLaunchBind}, E, exec, foot -c nvim"
          "${appLaunchBind}, W, exec, firefox"
          "${appLaunchBind}, Q, exec, qutebrowser"
          "${appLaunchBind}, D, exec, vesktop"
          "${appLaunchBind}, M, exec, tidal-hifi"
          "${appLaunchBind}, S, exec, grimblast copy area"

        ]
        ++
        # Launcher
        (["${appLaunchBind}, Space,  exec, killall rofi || rofi -show drun"]
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

        bind = ${super}, o, submap, openApps
        submap = openApps
          bind = , Return, exec, foot
          bind = , T, exec, foot
          bind = , E, exec, foot -c nvim
          bind = , W, exec, firefox
          bind = , Q, exec, qutebrowser
          bind = , D, exec, discord
          bind = , M, exec, tidal-hifi
          bind = , S, exec, steam
        bind = , catchall, submap, reset
        submap = reset
      '';
  };

  xdg.configFile = {
    ${gapsScript} = {
      executable = true;
      text =
        # fish
        ''
          #!/usr/bin/env fish

          hyprctl keyword general:gaps_out $(math 10 - $(hyprctl getoption general:gaps_out -j | jq -r ".custom" | choose 1))
          hyprctl keyword general:gaps_in $(math 5 - $(hyprctl getoption general:gaps_in -j | jq -r ".custom" | choose 1))
          hyprctl keyword general:border_size $(math 2 - $(hyprctl getoption general:border_size -j | jq -r ".int"))
          hyprctl keyword decoration:rounding $(math 8 - $(hyprctl getoption decoration:rounding -j | jq -r ".int"))
        '';
    };

    ${setBackgroundScript} = {
      executable = true;
      text =
        # fish
        ''
          #!/usr/bin/env fish

          if [ (hyprctl getoption animations:enabled -j | jq -r ".int") = "1" ]
            swww img \
              --transition-type $(random choice grow wave outer) \
              --transition-wave 80,40 \
              --transition-angle $(random choice 45 90 135 225 270 315) \
              --transition-pos $(random choice center top left right bottom top-left top-right bottom-left bottom-right) \
              --transition-step 200 \
              --transition-duration 1.5 \
              --transition-fps 240 \
              --outputs "$argv[1]" \
              "$argv[2]"
          else
            swww img \
              --transition-type simple \
              --transition-step 255 \
              --outputs "$argv[1]" \
              "$argv[2]"
          end
        '';
    };

    ${randomBackgroundScript} = {
      executable = true;
      text =
        # fish
        ''
          #!/usr/bin/env fish

          for monitor in (hyprctl monitors -j | jq -r '.[].name')
            ~/.config/${setBackgroundScript} "$monitor" "$(random choice $(fd . ${osu-backgrounds}/2024-10-09-Autumn-2024-Fanart-Contest-All-Entries --follow -e jpg -e png))"
          end
        '';
    };

    ${swapBackgroundScript} = {
      executable = true;
      text =
        # fish
        ''
          #!/usr/bin/env fish

          set M "$(swww query | cut -d ':' -f 5)"
          set M1 "$(echo "$M" | head -n 1 | awk '{$1=$1};1')"
          set M2 "$(echo "$M" | tail -n 1 | awk '{$1=$1};1')"

          ~/.config/${setBackgroundScript} "$(swww query | choose 0 | choose -c 0..-1 | tail -n 1)" "$M1"
          ~/.config/${setBackgroundScript} "$(swww query | choose 0 | choose -c 0..-1 | head -n 1)" "$M2"
        '';
    };
  };

  services = {hyprpaper.enable = mkForce false;};
}

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
  inherit (nix-config.packages.${pkgs.system})  vim-hypr-nav;
  inherit (nix-config.inputs.hyprland.packages.${pkgs.system}) hyprland;
  inherit (nix-config.inputs.quickshell.packages.${pkgs.system}) quickshell;
  opacity = "0.95";

  super = "SUPER";
  appLaunchBind =
    if osConfig.hardware.keyboard.zsa.enable
    then "ALT SHIFT CTRL"
    else super;

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
  imports = [ nix-config.inputs.ags.homeManagerModules.default ];
  home.packages = with pkgs; [
    hyprsunset
    hyprpolkitagent
    hyprpicker
    grimblast
    mpvpaper
    wf-recorder
    playerctl
    socat
    inotify-tools
    sassc
    gnome-bluetooth
    qt6.qtimageformats # amog
    qt6.qt5compat # shader fx
  ] ++ [ quickshell ];
  programs.ags.enable = true;
  wayland.windowManager.hyprland = {
    enable = true;
    package = hyprland;
    /*plugins = [
      nix-config.inputs.hyprland-plugins.packages.${pkgs.system}.hyprbars
      nix-config.inputs.hyprland-plugins.packages.${pkgs.system}.xtra-dispatchers
    ];*/
    settings = {
      env = [
        "BROWSER,firefox"
        "PULSE_LATENCY_MSEC,60" # fix audio static in xwayland games
      ];

      monitor = ["DP-1,5120x1440@120,auto,1" "DP-2,1920x1080,auto-left,1"];
      exec = [
        "${toggle "ags"}"
        "hyprctl dispatch workspace 2"
        "xrandr --output DP-1 --primary"
      ];
      exec-once = [
        "uwsm finalize"
        "systemctl --user start hyprpolkitagent"
        "wpctl set-volume @DEFAULT_SINK@ 40%"
        "steam [workspace 1 silent]"
        "firefox [workspace 3 silent"
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
        gaps_out = "-3";
        border_size = 3;
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
          height = 20;
          font_size = 15;
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

      gestures = {workspace_swipe = true;};

      binds = {allow_workspace_cycles = true;};

      layerrule = ["blur,ironbar" "blur,rofi" "blur,notifications"];

      windowrulev2 = [
        "noborder, fullscreenstate:0 1"
        "tag +terminal, class:terminal"

        "tag media, class:mpv"
        "tag media, title:Picture-in-Picture"
        "suppressevent activatefocus, title:Picture-in-Picture"

        # Specific Game / Launcher Rules
        "tag games, class:^(steam_app.*|Waydroid|osu!|RimWorldLinux)$"
        "tag games, title:^(UNDERTALE)$"
        "tag launcher, initialTitle:Battle.net"



        #"nomaxsize,class:^(winecfg.exe|osu.exe)$"
        "opaque,class:^(terminal)$"
        "noblur,class:^(terminal)$"
        "nodim,tag:games"
        "nodim,tag:media"
        "nodim,tag:games"
        "nodim,workspace:m[DP-2]"
        "nodim,workspace:s[true]"

        "float,title:Picture-in-Picture"
        "pin,title:Picture-in-Picture"
        "noinitialfocus,title:Picture-in-Picture"
        "move 100%-99%,title:Picture-in-Picture"

        "idleinhibit always, tag:media"
        "noborder, tag:media"
        "monitor DP-1, class:^(steam_app.*|Waydroid|osu!|RimWorldLinux)$"
        "workspace 5, class:^(steam_app.*|Waydroid|osu!|RimWorldLinux)$"
        "tile, class:^(steam_app.*)$, floating:1, workspace:5"
        "float, tag:launcher"
        "size 1680 1080, tag:launcher"
        "workspace unset, tag:launcher"
        "fullscreenstate 1 2, initialTitle:(World of Warcraft)"

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
      /*  "${super}SHIFT, M, sendshortcut, CONTROLSHIFT, M, ^(discord)$"
          "${super}SHIFT, D, sendshortcut, CONTROLSHIFT, D, ^(discord)$"
          "${super}CONTROL, Q, pass, ^(discord)$"
          "${super}, V, pass, ^(discord)$"  */

          # Bar
          "${super}CONTROL, B, exec, ${toggle "ags"}"
          ##window management
          "${super}SHIFT, Q, killactive,"
          "${super}SHIFT, L, lockactivegroup, toggle"

          "${super}SHIFT, F, togglefloating"
          "${super}CONTROL, F, fullscreen"

          "${super}SHIFT, P, pin"
        ] ++
        # Launcher
        /* (["${appLaunchBind}, Space,  exec, ${toggle "rofi"} -show drun"]
          ++ (let
            cliphist = lib.getExe config.services.cliphist.package;
          in
            lib.optionals config.services.cliphist.enable [
              "${appLaunchBind}, C, exec, ${cliphist} list | rofi -dmenu | ${cliphist} decode | wl-copy"
            ]))
        ++ */
        # Change workspace//
        (map (n: "${super},${n},workspace,${n}") workspaces)
        ++
        # Move window to workspace
        (map (n: "${super}SHIFT,${n},movetoworkspacesilent,${n}")
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
        "${super},plus,splitratio,0.05"
        "${super}SHIFT,plus,splitratio,0.125"

        # Resize windows with mainMod + SUPER + arrow keys
        "${super}ALTSHIFT, left, resizeactive, 75 0"
        "${super}ALTSHIFT, right, resizeactive, -75 0"
        "${super}ALTSHIFT, up, resizeactive, 0 -75"
        "${super}ALTSHIFT, down, resizeactive, 0 75"
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
        bind = ${super}ALT, BackSpace, submap, passthrough
        submap = passthrough
        bind = ${super}ALT, BackSpace, submap, reset
        submap = reset

          bind = ${super}, A, submap, openApps
        submap = openApps
          bind = , Return, exec, uwsm app -- foot
          bind = , Return ,submap, reset
          bind = , W, exec, uwsm app -- firefox
          bind = , W,submap, reset
          bind = , D, exec, uwsm app -- discord
          bind = , D,submap, reset
          bind = , S, exec, ${runOnce "grimblast"} --notify copysave area
          bind = , S,submap, reset
          bind = , Space, exec, ${runOnce "ags -t launcher"}
          bind = , Space ,submap, reset
          bind = , N, exec, ${runOnce "ags -t panel"}
          bind = , N,submap, reset
          bind = , C, exec, ${runOnce "ags -t calendarbox"}
          bind = , C,submap, reset
          bind = , B, exec, ${runOnce "ags -t bar"}
          bind = , B,submap, reset
          bind = , V, exec, uwsm app -- pwvucontrol-qt
          bind = , V,submap, reset
          bind = , T, submap, openTerminal
          bind = , catchall, submap, reset
          submap = reset
        bind = ${super}, T, submap, openTerminal
        submap = openTerminal
          bind = , Return, exec, uwsm app -- foot
          bind = , Return ,submap, reset
          bind = , T, exec, uwsm app -- foot
          bind = , T,submap, reset
          bind = , E, exec, uwsm app -- foot nvim
          bind = , E,submap, reset
          bind = , ., exec, uwsm app -- foot yazi
          bind = , .,submap, reset
          bind = , F, exec, uwsm app -- foot yazi
          bind = , F,submap, reset
          bind = , ?, exec, uwsm app -- foot zenith
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

        preload = [ "${config.xdg.userDirs.pictures}/wallpaper/32:9/pixel-horizon.png" ];

        wallpaper = [
          "DP-1, ~/media/pictures/wallpaper/32:9/pixel-horizon.png"
          "DP-2,${config.xdg.userDirs.pictures}/wallpaper/32:9/pixel-horizon.png"
          ];
        };
       };
    };

    # Make Monitor default sink as defaults to TV
    home.file.".config/wireplumber/main.lua.d/51-default-sink.lua".text = ''
      default_sink = {
        matches = {
          {
            { "node.name", "matches", "alsa_output.pci-0000_01_00.1.hdmi-stereo-extra1" },
          },
        },
        apply_properties = {
          ["default.sink"] = true,
        },
      }
      table.insert(alsa_monitor.rules, default_sink)
    '';
}

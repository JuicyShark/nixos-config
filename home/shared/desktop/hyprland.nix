{
  nixosConfig,
  osConfig,
  config,
  pkgs,
  lib,
  ...
}:
with pkgs;
let
  inherit (nixosConfig._module.specialArgs) nix-config;
  inherit (nixosConfig._module.specialArgs.nix-config.inputs) caelestia-shell caelestia-cli;
  stylix = config.lib.stylix.colors;
  desktop = osConfig.modules.desktop.enable;
  inherit (nix-config.packages.${pkgs.system}) vim-hypr-nav;
  opacity = "0.9";

  mod = "SUPER";

  toggle =
    program:
    let
      prog = builtins.substring 0 14 program;
    in
    "pkill ${prog} || uwsm app -- ${program}";

  runOnce = program: "pgrep ${program} || uwsm app -- ${program}";

  workspaces = [
    "1"
    "2"
    "3"
    "4"
    "5"
    "6"
    "7"
    "8"
    "9"
  ];
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
in
{
  imports = [
    #   ../quickshell

  ];
  home.file = {
    ".config/caelestia/shell.json".text = ''
        {
          "background": {
          "enabled": true
      },
      "bar": {
          "dragThreshold": 20,
          "persistent": true,
          "showOnHover": true,
          "workspaces": {
              "activeIndicator": true,
              "activeLabel": "󰮯 ",
              "activeTrail": false,
              "label": "  ",
              "occupiedBg": true,
              "occupiedLabel": "󰮯 ",
              "rounded": true,
              "showWindows": true,
              "shown": 5
          }
      },
      "border": {
          "rounding": 25,
          "thickness": 10
      },
      "dashboard": {
          "mediaUpdateInterval": 300,
          "visualiserBars": 45
      },
      "launcher": {
          "actionPrefix": ">",
          "dragThreshold": 50,
          "enableDangerousActions": false,
          "maxShown": 8,
          "maxWallpapers": 9,
          "useFuzzy": {
              "apps": true,
              "actions": true,
              "schemes": true,
              "variants": true,
              "wallpapers": true
          }
      },
      "lock": {
          "maxNotifs": 5
      },
      "notifs": {
          "actionOnClick": true,
          "clearThreshold": 0.3,
          "defaultExpireTimeout": 5000,
          "expandThreshold": 20,
          "expire": false
      },
      "osd": {
          "hideDelay": 2000
      },
      "paths": {
          "mediaGif": "root:/assets/bongocat.gif",
          "sessionGif": "root:/assets/kurukuru.gif",
          "wallpaperDir": "~/media/pictures/wallpaper/"
      },
      "services": {
        "weatherLocation": "-28,153",
        "useFahrenheit": false
      },
      "session": {
          "dragThreshold": 30
      }
        }
    '';
  };
  home.packages =
    with pkgs;
    lib.mkIf desktop [
      runelite
      wf-recorder
      socat
      caelestia-shell.packages.${pkgs.system}.default
      caelestia-cli.packages.${pkgs.system}.default
    ];
  #

  wayland.windowManager.hyprland = lib.mkIf desktop {
    enable = true;
    package = osConfig.programs.hyprland.package;
    portalPackage = osConfig.programs.hyprland.portalPackage;

    plugins = with pkgs.hyprlandPlugins; [
      #hyprbars
    ];

    settings = {
      env = [
        "BROWSER,firefox"
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_DESKTOP,Hyprland"
      ];

      monitor = [
        "DP-1,highres,auto,1"
        #"DP-2,1920x1080@60,auto-left,1"
        "headless,2420x1668@120,0x0,1"
      ];

      exec = [
        "xrandr --output DP-1 --primary"
        "caelestia-shell -n"
      ];

      exec-once = [

        #"emacs --daemon"

        # "systemctl --user start hyprpolkitagent"
        # "wpctl set-volume @DEFAULT_SINK@ 40%"

        # "[workspace 1 silent; float; move 100%-w-75; size 900 500] youtube-music"
        "[workspace 1 silent; float; move 0%-w-75; size 900 500] bitwarden"
        "[workspace 2 silent] firefox"
        "[workspace 3 silent] discord"
        "[workspace 5 silent] steam"
        # "[move 100%-w-75] telegram-desktop"
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
        gaps_in = 10;
        gaps_out = 15;
        border_size = 4;
        layout = "dwindle";

        snap = {
          enabled = true;
          window_gap = 15;
          monitor_gap = 10;
          border_overlap = false;
          respect_gaps = true;
        };
      };

      decoration = {
        rounding = 5;
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

      xwayland = {
        enabled = true;
        create_abstract_socket = true;
      };

      animations = {
        enabled = true;
        workspace_wraparound = true;
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
        default_split_ratio = "1";
        split_width_multiplier = "1.75";
        special_scale_factor = 0.7;
        single_window_aspect_ratio = "16 9";
        single_window_aspect_ratio_tolerance = 0;
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
        #center_master_slaves_on_right = true;
        center_ignores_reserved = true;
      };

      plugin = {

        /*
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
        */
      };

      gestures = {
        workspace_swipe = true;
      };

      binds = {
        allow_workspace_cycles = true;
      };

      layerrule = [
        "blur,launcher"
        "blur,notifications"
      ];

      windowrulev2 = [
        "plugin:hyprbars:nobar, floating:0"
        #"suppressevent maximize, class:.*"
        #"float, workspace:1"

        "tag +terminal, class:ghostty"
        "tag +video, class:mpv"
        "tag +video, title:Picture-in-Picture"
        "tag +pip, title:Picture-in-Picture"
        "tag +game, class:^(steam_app.*|Waydroid|osu!|RimWorldLinux|UNDERTALE)$"
        "tag +social, class:^(discord|signal|org.telegram.desktop)$"
        "tag +private, class:^(org.keepassxc.KeePassXC|bitwarden|discord)$"
        "tag +utility, title:^(Extension: (Bitwarden - Free Password Manager).*|KeePassXC -  Access Request)|Unlock Database - KeePassXC|Sign In - Google Accounts.*)$"
        "tag +utility, class:^(thunar|com.saivert.pwvucontrol|RimPy|org.keepassxc.KeePassXC|Tk|xdg-desktop-portal-gtk)$"

        "float, tag:utility"
        "noscreenshare, tag:private"

        "content video, tag:video"
        "idleinhibit always, tag:video"
        "noborder, tag:video"

        # Picture in picture specific rules
        "suppressevent activatefocus, tag:video"
        "float, tag:pip"
        "pin, tag:pip"
        "noinitialfocus, tag:video"
        "move 100%-w-20, tag:pip"

        "float, tag:social"

        # Game Content Rules
        "idleinhibit always, tag:game"
        "nodim,tag:game"
        "plugin:hyprbars:nobar, tag:game"

        "nodim,tag:video"

        # Game Specific Rules
        #"fullscreenstate 0 2, initialTitle:(World of Warcraft)"
        "suppressevent fullscreen, initialTitle:(World of Warcraft)"

        #"workspace 9, class:steam, title:Steam Big Picture Mode"

        "move onscreen 100% 0%, class:^(com.saivert.pwvucontrol)$"
        "tile,class:^(.qemu-system-x86_64-wrapped)$"
        "opacity ${opacity} ${opacity},class:^(thunar)$"

        "bordersize 0, floating:0, onworkspace:w[tv1]"
        "rounding 0, floating:0, onworkspace:w[tv1]"
        "bordersize 0, floating:0, onworkspace:f[1]"
        "rounding 0, floating:0, onworkspace:f[1]"
      ];

      workspace = [
        "1, monitor:DP-1, rounding:true, layoutopt:orientation:center"
        "2, monitor:DP-1, layoutopt:orientation:center, default:true"
        "3, monitor:DP-1, layoutopt:orientation:center"
        "4, monitor:DP-1, layoutopt:orientation:right"
        "5, monitor:DP-1, decorate:0, shadow:0, border:0, layoutopt:orientation:left"

        "m[DP-2], layoutopt:orientation:left, decorate:false, shadow:false"
        "6, monitor:DP-2, default:true"
        "7, monitor:DP-2"
        "8, monitor:DP-2"
        "9, monitor:DP-2"
        "0, monitor:DP-2"
        #  "s[true], gapsout:0,400,0,400"
        "special:scratchpad, on-created-empty:ghostty"
        "special:terminal, on-created-empty:ghostty"
        "special:test, on-created-empty:firefox"

        #No Gaps if only
        #"w[tv1], gapsout:0, gapsin:0"
        #"workspace = f[1], gapsout:0, gapsin:0"
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
      bind = [
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

        "${mod}CONTROL, N, exec, hyprctl --batch 'keyword general:gaps_out 0 ; keyword general:gaps_in 0 ; keyword decoration:rounding 0'"
        "${mod}SHIFTCONTROL, N, exec, hyprctl --batch 'keyword general:gaps_out 25 ; keyword general:gaps_in 10 ; keyword decoration:rounding 10'"

        ##window management
        "${mod}SHIFT, Q, killactive,"
        "${mod}SHIFT, L, lockactivegroup, toggle"

        "${mod}CONTROL, M, fullscreen"
        "${mod}CONTROL, F, togglefloating"
        "${mod}CONTROL, P, pin"

        "${mod}CONTROL, L, exec, caelestia-shell ipc call lock lock"

        "${mod}, t, togglespecialworkspace, scratchpad"

        #TODO Replace clipboard history
        #"${mod}, V, exec, [float] kitty --class clipse -e 'clipse'"
        #"${mod}, C, exec,  kitty --class clipse -e 'clipse'"
        "${mod}, Space, exec, caelestia-shell ipc call drawers toggle launcher"
        "${mod}, Return, exec, uwsm app -- ghostty"

      ]
      ++
        # Change workspace//
        (map (n: "${mod},${n},workspace,${n}") workspaces)
      ++
        # Move window to workspace
        (map (n: "${mod}SHIFT,${n},movetoworkspacesilent,${n}") workspaces)
      ++
        # Move focus, changes focus of nvim windows too
        (lib.mapAttrsToList (
          key: direction: "${mod},${key},exec, ${vim-hypr-nav}/bin/vim-hypr-nav ${direction}"
        ) directions)
      ++
        # Move windows
        (lib.mapAttrsToList (
          key: direction: "${mod}SHIFT,${key},movewindoworgroup,${direction}"
        ) directions)
      ++
        # Open next window in given direction in dwindle
        (lib.mapAttrsToList (
          key: direction: "${mod}CONTROL,${key},layoutmsg,preselect ${direction}"
        ) directions);

      bindm = [
        "SUPER, mouse:272, movewindow"
        "SUPER, mouse:273, resizewindow"
      ];

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
          bind = , Return, exec, uwsm app -- ghostty
          bind = , Return ,submap, reset
          bind = , W, exec, uwsm app -- firefox
          bind = , W,submap, reset
          bind = , P, exec, uwsm app -- firefox --private-window
          bind = , P, submap, reset
          bind = , B, exec, bambu-studio
          bind = , B, submap, reset
          bind = , D, exec, uwsm app -- discord
          bind = , D,submap, reset
          bind = , S, exec, caelestia-shell ipc call picker openFreeze
          bind = , S,submap, reset
          bind = , Space, exec, caelestia-shell ipc call drawers toggle launcher
          bind = , Space ,submap, reset
          bind = , V, exec, uwsm app -- pwvucontrol
          bind = , V,submap, reset
          bind = , T, submap, openTerminal

          bind = , E, submap, emacs
          bind = , catchall, submap, reset
          submap = reset

        submap = emacs
          bind = , E, exec, emacsclient -r
          bind = , E, focuswindow, class:(emacs)
          bind = , E, submap, reset
          bind = , N, exec, emacsclient -c
          bind = , N, submap, reset
          bind = , dot, exec, emacsclient -r .
          bind = , dot, submap, reset
          bind = , D, exec, emacsclient -c --eval "(call-interactively org-dailies-goto-today)"
          bind = , D, submap, reset,
          bind = , catchall, submap, reset
        submap = reset

        bind = ${mod}, T, submap, openTerminal
        submap = openTerminal
          bind = , Return, exec, uwsm app -- ghostty
          bind = , Return ,submap, reset
          bind = , T, exec, uwsm app -- ghostty
          bind = , T,submap, reset
          bind = , E, exec, uwsm app -- ghostty nvim
          bind = , E,submap, reset
          bind = , ., exec, uwsm app -- ghostty yazi
          bind = , .,submap, reset
          bind = , F, exec, uwsm app -- ghostty yazi
          bind = , F,submap, reset
          bind = , ?, exec, uwsm app -- ghostty zenith
          bind = , ?,submap, reset
          bind = , catchall, submap, reset
          submap = reset
      '';
  };

  services = lib.mkIf desktop {
    hypridle = {
      enable = true;

      settings = {
        general = {
          lock_cmd = "caelestia-shell ipc call lock lock";
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
        };

        listener = [
          {
            timeout = 900;
            on-timeout = "loginctl lock-session";
          }
          {
            timeout = 4800;
            on-timeout = "systemctl suspend";
          }
        ];
      };
    };
  };
}

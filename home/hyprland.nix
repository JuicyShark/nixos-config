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
  style = config.lib.stylix.colors.withHashtag;
  inherit (lib) mkForce;
  inherit (nixosConfig._module.specialArgs) nix-config;
  inherit (nix-config.packages.${pkgs.system})  vim-hypr-nav;
  inherit (nix-config.inputs.quickshell.packages.${pkgs.system}) quickshell;
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
    gowall

  ] ++ [ quickshell ];
  programs.ags.enable = true;
  wayland.windowManager.hyprland = {
    enable = true;
    package = osConfig.programs.hyprland.package;
    portalPackage = osConfig.programs.hyprland.portalPackage;
    plugins = [
 #     nix-config.inputs.hyprland-plugins.packages.${pkgs.system}.hyprbars
      #nix-config.inputs.hy3.packages.${pkgs.system}.hy3
    ];
    settings = {
      env = [
        "BROWSER,firefox"
        "PULSE_LATENCY_MSEC,60" # fix audio static in xwayland games
        # Wayland
  	"GDK_BACKEND,wayland,x11,*"
  	"QT_QPA_PLATFORM,wayland;xcb"
  	"SDL_VIDEODRIVER,wayland"

  	# XDG
  	"XDG_CURRENT_DESKTOP,Hyprland"
  	"XDG_SESSION_TYPE,wayland"
  	"XDG_SESSION_DESKTOP,Hyprland"

  	"HYPRSHOT_DIR,/home/${config.home.username}/pictures/screenshots"
      ];

      monitor = [
        "DP-1,5120x1440@120,auto,1"
        #"DP-2,1920x1080,auto-left,1"
      ];

      exec = [
        "xrandr --output DP-1 --primary"
        "hyprctl reload"
      ];

      exec-once = [
        "uwsm finalize"
        "systemctl --user start hyprpolkitagent"
        "${toggle "ags"}"
        "wpctl set-volume @DEFAULT_SINK@ 40%"
        "[workspace 1 silent] keepassxc"
        "[workspace 1 silent] steam"
        "[workspace 2 silent] firefox"
        "[workspace 3 silent] emacs --fg-daemon"
        "[workspace 3 silent] kitty"
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
        gaps_out = "-3";
        border_size = 3;
        layout = "dwindle";

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

      plugin = {
  /*      hyprbars = {
          bar_height = 25;
          bar_text_size = 13;

          hyprbars-button = [
            "rgb(ff4040), 10, 󰖭, hyprctl dispatch killactive"
            "rgb(eeee11), 10, , hyprctl dispatch float 1"
          ];
        };

     /*   hy3 = {
          no_gaps_when_only = 1;
          node_collapse_policy = 1;
          group_inset = 0;
          tab_first_window = false;

          tabs = {
            height = 45;
            text_height = 14;
            radius = 0; # config.windowManger.hyprland.settings.decoration.rounding;
            border_width =  6; #config.windowManger.hyprland.settings.general.border_size;
            text_font = "IosevkaTerm Nerd Font"; # config.windowManager.hyprland.settings.misc.font_family;

          };
          # Based on a 5120x1440, 32:9 display
          autotile = {
            enable = true;
            epherhemeral_groups = true;
            trigger_width = 1150;
            trigger_height = 525;
          };
        };*/
      };

      gestures = {workspace_swipe = true;};

      binds = {allow_workspace_cycles = true;};

      layerrule = ["blur,wofi" "blur,notifications"];

      windowrulev2 = [
        "plugin:hyprbars:nobar, floating:0"
        "noborder, fullscreenstate:0 1"
        "tag +terminal, class:terminal"


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
        #"nodim,workspace:m[DP-2]"
        #"nodim,workspace:s[true]"

        "tag media, class:mpv"
        "tag media, title:Picture-in-Picture"
        "suppressevent activatefocus, title:Picture-in-Picture"
        "float,title:Picture-in-Picture"
        "pin,title:Picture-in-Picture"
        "noinitialfocus,title:Picture-in-Picture"
        "move 100%-99%,title:Picture-in-Picture"

        "idleinhibit always, tag:media"
        "noborder, tag:media"
        "monitor DP-1, class:^(steam_app.*|Waydroid|osu!|RimWorldLinux)$"
        "workspace 5, class:^(steam_app.*|Waydroid|osu!|RimWorldLinux)$"
        "tile, class:^(steam_app.*)$, floating:0, workspace:5"
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

      /*bind =
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
          "${mod}CONTROL, B, exec, ${toggle "ags"}"
          ##window management
          "${mod}SHIFT, Q, killactive,"

          "${mod}SHIFT, F, togglefloating"
          "${mod}CONTROL, F, fullscreen"

          "${mod}SHIFT, P, pin"

          "${mod}, d, exec, ${toggle "${wofi}/bin/wofi  --show drun"}"
          "${mod}, Space, exec, ${toggle "${wofi}/bin/wofi  --show drun"}"
          "${mod}, c, exec, ${cliphist}/bin/cliphist list | ${toggle "${wofi}/bin/wofi --show dmenu"} | ${cliphist}/bin/cliphist decode | ${wl-clipboard}/bin/wl-copy"
          "${mod}, p, exec, ${toggle "${wofi-pass}/bin/wofi-pass"}"
          "${mod}, e, exec, ${toggle "${wofi-emoji}/bin/wofi-emoji"}"

        ] ++
        # Change workspace//
        (map (n: "${mod},${n},workspace,${n}") workspaces)
        ++
        # Move window to workspace
        (map (n: "${mod}SHIFT,${n},hy3:movetoworkspace,${n}, silent")
          workspaces)
        ++
        # Move focus
        (lib.mapAttrsToList (key: direction: "${mod},${key},hy3:movefocus,${direction}, visible")
          directions)
        ++
        # Move windows
        (lib.mapAttrsToList (key: direction: "${mod}SHIFT,${key},hy3:movewindow,${direction},once,visible") directions)
        ++
        # Open next window in given direction
        (lib.mapAttrsToList (key: direction: "${mod}CONTROL,${key},layoutmsg,preselect ${direction}")
        directions);*/


      bind =
        [
          # Group Settings
          "${mod}CONTROL, G, togglegroup"
          "${mod}CONTROL, S, layoutmsg, togglesplit"
          "${mod}CONTROL, R, layoutmsg, swapsplit"
          "${mod}CONTROL, R, layoutmsg, mfact exact 0.5"
          "${mod}CONTROL, U, layoutmsg, mfact exact 0.65"
          "${mod}CONTROL, L, layoutmsg, orientationleft"
          "${mod}CONTROL, C, layoutmsg, orientationcenter"
          "${mod}CONTROL, T, layoutmsg, movetoroot active"
          #"${mod}CONTROL, D, exec, hyprctl keyword general:layout dwindle"
          #"${mod}CONTROL, M, exec, hyprctl keyword general:layout master"
          "${mod}, tab, changegroupactive, f"
          "${mod}SHIFT, tab, changegroupactive, b"

          # Bar
          "${mod}CONTROL, B, exec, ${toggle "ags"}"
          ##window management
          "${mod}SHIFT, Q, killactive,"
          "${mod}SHIFT, L, lockactivegroup, toggle"

          "${mod}CONTROL, F, togglefloating"
          "${mod}CONTROL, M, fullscreen"

          "${mod}CONTROL, P, pin"
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
        (map (n: "${mod},${n},workspace,${n}") workspaces)
        ++
        # Move window to workspace
        (map (n: "${mod}SHIFT,${n},movetoworkspacesilent,${n}")
          workspaces)
        ++
        # Move focus
        (lib.mapAttrsToList (key: direction: "${mod},${key},exec, ${vim-hypr-nav}/bin/vim-hypr-nav ${direction}")
          directions)
        ++
        # Move windows
        (lib.mapAttrsToList (key: direction: "${mod}SHIFT,${key},movewindoworgroup,${direction}") directions)
        ++
        # Open next window in given direction
        (lib.mapAttrsToList (key: direction: "${mod}CONTROL,${key},layoutmsg,preselect ${direction}")
          directions);

      bindm = ["SUPER, mouse:272, movewindow" "SUPER, mouse:273, resizewindow"];

      binde = [
        # Change Split Ratio for new splits
        "${mod},minus,splitratio,-0.05"
        "${mod}SHIFT,minus,splitratio,-0.125"
        "${mod},plus,splitratio,0.05"
        "${mod}SHIFT,plus,splitratio,0.125"

        # Resize windows with mainMod + SUPER + arrow keys
        "${mod}ALTSHIFT, left, resizeactive, 75 0"
        "${mod}ALTSHIFT, right, resizeactive, -75 0"
        "${mod}ALTSHIFT, up, resizeactive, 0 -75"
        "${mod}ALTSHIFT, down, resizeactive, 0 75"
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
          bind = , S, exec, ${runOnce "grimblast"} --notify copysave area
          bind = , S,submap, reset
          bind = , Space, exec, ${toggle "${wofi}/bin/wofi --show drun"}
          bind = , Space ,submap, reset
          bind = , N, exec, ${runOnce "ags -t panel"}
          bind = , N,submap, reset
          bind = , C, exec, ${runOnce "ags -t calendarbox"}
          bind = , C,submap, reset
          bind = , B, exec, ${runOnce "ags -t bar"}
          bind = , B,submap, reset
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

        preload = [ "${config.xdg.userDirs.pictures}/wallpaper/32:9/pixel-horizon.png" ];

        wallpaper = [
          "DP-1, ~/media/pictures/wallpaper/32:9/pixel-horizon.png"
          "DP-2,${config.xdg.userDirs.pictures}/wallpaper/32:9/pixel-horizon.png"
          ];
        };
       };
    };

    # Make Monitor default sink as defaults to TV
    home.file.".config/gowall/config.yml".text = ''
    themes:
      - name: "stylix"
        colors:
          - "${style.base00}"
          - "${style.base01}"
          - "${style.base02}"
          - "${style.base03}"
          - "${style.base04}"
          - "${style.base05}"
          - "${style.base06}"
          - "${style.base07}"
          - "${style.base08}"
          - "${style.base09}"
          - "${style.base0A}"
          - "${style.base0B}"
          - "${style.base0C}"
          - "${style.base0D}"
          - "${style.base0E}"
          - "${style.base0F}"
    '';
}

{ config, lib, pkgs, ... }:
with pkgs;
let
  mod = "Mod4";
  appMod = "Mod1+Shift+Control";


  # Define workspaces dynamically
  workspaces = map toString (lib.range 1 9);

  # Define movement directions
  directions = {
    "Left" = "left";
    "Down" = "down";
    "Up" = "up";
    "Right" = "right";
  };

  # Generate dynamic keybindings
  commonKeybindings = lib.listToAttrs (
    # Change workspace
    (map (n: {
      name = "${mod}+${n}";
      value = "workspace number ${n}";
    }) workspaces)
    ++
    # Move window to workspace
    (map (n: {
      name = "${mod}+Shift+${n}";
      value = "move container to workspace number ${n}";
    }) workspaces)
    ++
    # Move focus
    (lib.mapAttrsToList (key: direction: {
      name = "${mod}+${key}";
      value = "focus ${direction}";
    }) directions)
    ++
    # Move windows
    (lib.mapAttrsToList (key: direction: {
      name = "${mod}+Shift+${key}";
      value = "move ${direction}";
    }) directions)
  );
in  {
  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    MOZ_USE_XINPUT2 = "1";
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "sway";
    SDL_VIDEODRIVER = "wayland";
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    _JAVA_AWT_WM_NONREPARENTING = 1;
    GDK_BACKEND = "wayland";
    PULSE_LATENCY_MSEC = "60";
  };


  programs = {
    swayr = {
      enable = true;
      settings = {
        menu = {
            executable = "${wofi}/bin/wofi";
  args = [
    "--show=dmenu"
    "--allow-markup"
    "--allow-images"
    "--insensitive"
    "--cache-file=/dev/null"
    "--parse-search"
    "--height=40%"
    "--prompt={prompt}"
  ];
        };


      layout = {
        auto_tile = true;
        auto_tile_min_window_width_per_output_width = [
          [ 1920 920 ]
          [ 3440 1200 ]
          [ 5120 920 ]
        ];
      };
    };
    };

    swaylock = {
      enable = true;
    };
  };
  services = {
    swayidle = {
      enable = false;
      timeouts = [
          { timeout = 900; command = "${pkgs.swaylock}/bin/swaylock -fF"; }
          { timeout = 960; command = "${pkgs.systemd}/bin/systemctl suspend"; resumeCommand = ''swaymsg "output * dpms on" ; xrandr --output $(xrandr | grep "XWAYLAND.*5120" | awk "\"'{ print $1 }'\'") --primary'';}
        ];
        events = [
          { event = "before-sleep"; command = "${pkgs.swaylock}/bin/swaylock -fF"; }
          { event = "lock"; command = "lock"; }
        ];
    };

    swayosd = {
      enable = true;
      display = "DP-1";
    };
  };
  wayland.windowManager.sway = {
      enable = true;
      xwayland = true;
      systemd.enable = true;

      # can't discover my custom layout
      checkConfig = false;
      extraOptions = [
        "--unsupported-gpu"
      ];

      config = {
        output = {
          DP-1 = {
            resolution = "5120x1440@119.970Hz";
            scale = "1";
            allow_tearing = "yes";
          };
          DP-2 = {
            resolution = "1920x1080";
          };
        };
        seat."*".hide_cursor = "10000";

        gaps = {
          inner = 0;
          smartGaps = true;
        };

        window = {
          hideEdgeBorders = "smart";
          titlebar = false;
          border = 3;

        };

        focus = {
          wrapping = "workspace";
          mouseWarping = false;
          followMouse = true;
          newWindow = "smart";
        };
        bars = [ ];
        defaultWorkspace = "2";
        workspaceLayout = "default";
        workspaceOutputAssign = [
          {
            output = "DP-1";
            workspace = "1";
          }
          {
            output = "DP-1";
            workspace = "2";
          }         {
            output = "DP-1";
            workspace = "3";
          }         {
            output = "DP-1";
            workspace = "4";
          }
          {
            output = "DP-1";
            workspace = "5";
          }         {
            output = "DP-2";
            workspace = "6";
          }         {
            output = "DP-2";
            workspace = "7";
          }         {
            output = "DP-2";
            workspace = "8";
          }         {
            output = "DP-2";
            workspace = "9";
          }
        ];


        floating = {
          modifier = "Mod4";
          titlebar = true;
          border = 8;
          # Apps to spawn floating
          criteria = [
            { window_role = "pop-up"; }
            {
              title = "Battle.net";
              class = "steam_app_0";
            }

            { title = "^(Extension: (Bitwarden - Free Password Manager).*)$"; }
            { app_id = "udiskie"; }
            { app_id = "dmenu.*"; }
            { app_id = "qalculate-gtk"; }
            { app_id = "mpv"; }
          ];
        };
        window.commands = [
          {
            command = "floating enable, sticky enable";
            criteria.title = "Picture-in-Picture";
          }
        ];

        # Workspace rules
        assigns = {
          "1" = [
              {
                class = "steam";
              }
            ];
            "5" = [
              {
                class = "^(steam_app.*)$";
              }
          ];
        };

        bindkeysToCode = true;

        keybindings =  lib.mkMerge [
          {
            # Window Management
            "${mod}+Shift+q" = "kill";
#"${mod}+m" = "output 'DP-2' enable ; output 'DP-2' disable";
            # wofi: menu
            "${mod}+d" = "exec ${wofi}/bin/wofi --show drun";
            "${mod}+Space" = "exec ${wofi}/bin/wofi --show drun";
            "${mod}+c" = "exec ${cliphist}/bin/cliphist list | ${wofi}/bin/wofi --show dmenu | ${cliphist}/bin/cliphist decode | ${wl-clipboard}/bin/wl-copy";
            "${mod}+p" = "exec ${wofi-pass}/bin/wofi-pass";
            "${mod}+e" = "exec ${wofi-emoji}/bin/wofi-emoji";
            "${mod}+n" = "exec ${wl-color-picker}/bin/wl-color-picker clipboard";
            "${mod}+o" = "exec ${wl-mirror}/bin/wl-present mirror";
            # Apps
            "${mod}+Return" = "exec uwsm app -- foot";
            "${mod}+Tab" = "exec swayr switch-workspace-or-window";
            "${mod}+Delete" = "exec swayr quit-window";

          #  "${mod}+d" = "exec swayr switch-to-matching-or-urgent-or-lru-window -skip-lru-if-current-doesnt-match emacs discord || discord";
            #"${mod}+a" = "mode app_launch_mode";

            # Next Window should open Horizontally or Vertically from focused
            "${mod}+Control+Up" = "split v";
            "${mod}+Control+Down" = "split v";
            "${mod}+Control+Left" = "split h";
            "${mod}+Control+Right" = "split h";


            # Toggle Fullscreen or Floating Windows
            "${mod}+Shift+f" = "floating toggle";
            "${mod}+Control+f" = "fullscreen toggle";

            # Resize Windows
            "${mod}+Alt+Shift+Up" = "resize grow height 5 px or 5 ppt";
            "${mod}+Alt+Shift+Down" = "resize shrink height 5 px or 5 ppt";
            "${mod}+Alt+Shift+Left" = "resize shrink width 5 px or 5 ppt";
            "${mod}+Alt+Shift+Right" = "resize grow width 5 px or 5 ppt";
            #"${mod}+r" = "mode resize_mode";

            "XF86AudioMute" = "exec ${wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
            "XF86AudioLowerVolume" = "exec ${wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- -l 1.2";
            "XF86AudioRaiseVolume" = "exec ${wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ -l 1.2";

          }
        commonKeybindings
      ];

     /* modes = {
        resize_mode = {
            "Up" = "resize grow height 5 px or 5 ppt";
            "Down" = "resize shrink height 5 px or 5 ppt";
            "Left" = "resize shrink width 5 px or 5 ppt";
            "Right" = "resize grow width 5 px or 5 ppt";
            "Shift+Up" = "resize grow height 10 px or 10 ppt";
            "Shift+Down" = "resize shrink height 10 px or 10 ppt";
            "Shift+Left" = "resize shrink width 10 px or 10 ppt";
            "Shift+Right" = "resize grow width 10 px or 10 ppt";

            "Escape" = "mode default";
        };
        app_launch_mode = {
            "Return" = "exec uwsm app -- foot";
            "t" = "mode terminal_launch_mode";

            "Escape" = "mode default";
        };
        terminal_launch_mode = {
            "Return" = "exec uwsm app -- foot";
            "t" = "exec uwsm app -- foot";
            "w" = "exec uwsm app -- firefox";
            "Space" = "exec fuzzel";

            "Escape" = "mode default";
        };
      }; */

      startup = [
          {
            command = "firefox";
          }
          {
            command = "foot";
          }
          {
            command = "steam";
            always = true;
          }
          {
            command = "xrandr --output DP-1 --primary";
            always = true;
          }
          {
            command = "env RUST_BACKTRACE=1 RUST_LOG=swayr=debug swayrd > /tmp/swayrd.log 2>&1";
            always = true;
          }
        ];
      };
    };
}

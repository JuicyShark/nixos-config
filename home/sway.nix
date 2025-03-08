{ config, lib, pkgs, osConfig, ... }:
with pkgs;
let

    mario64Rom = pkgs.fetchurl {
    url = "https://ipfs.io/ipfs/QmWGw3Qu72FYoPpBTKMDJqsmhBnieBsXGkimGRd5bRBUDe";
    hash = "sha256-F84Hc0PGEz+Mny1tbZpKtiyM0qpXxArqH0kLTIuyHZE=";
  };

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
    SDL_VIDEODRIVER = "wayland,x11";
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    GDK_BACKEND = "wayland";
    #WLR_NO_HARDWARE_CURSORS = "1"; Nvidia doesnt require no hadware cursors now
    PULSE_LATENCY_MSEC = "60";
  };
  home.packages = with pkgs; [
    vulkan-volk
    (sm64ex.overrideAttrs (attrs: {
      makeFlags = attrs.makeFlags ++ [ "BETTERCAMERA=1" ];
      preBuild = ''
        patchShebangs extract_assets.py
        ln -s ${mario64Rom} ./baserom.us.z64
      '';
    }))
  ];


  programs = {
    /*sm64ex = {
      enable = true;
      package =
      baserom = "/home/juicy/tmp/sm64.v64";
      region = "us";
    };*/
    /* swayr = {
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
    };*/

    swaylock = {
      enable = true;
    };
  };
  services = {
   /* swayidle = {
      enable = false;
      timeouts = [
        { timeout = 900; command = "${pkgs.swaylock}/bin/swaylock -fF"; }
        { timeout = 960; command = "${pkgs.systemd}/bin/systemctl suspend"; resumeCommand = ''swaymsg "output * dpms on" ; xrandr --output $(xrandr | grep "XWAYLAND.*5120" | awk "\"'{ print $1 }'\'") --primary'';}
      ];
      events = [
        { event = "before-sleep"; command = "${pkgs.swaylock}/bin/swaylock -fF"; }
        { event = "lock"; command = "lock"; }
      ];
    };*/
  };
  wayland.windowManager.sway = {
    enable = true;
    xwayland = true;
    systemd.enable = true;

    # can't discover my custom layout
    checkConfig = false;
    extraConfig = ''
      title_align center
      default_orientation horizontal

    '';
    extraOptions = [
      "--unsupported-gpu"
    ];

    config = {

      fonts = {
        names = [ "Isoveka Term Nerd Font" ];
        style = "Bold Semi-Condensed";
        size = lib.mkForce 11.0;
      };

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
        #smartGaps = true;
      };
      window = {
        hideEdgeBorders = "--i3 smart_no_gaps";
        titlebar = true;
        border = 3;
        commands = [
          # Start Firefox tabbed
          {
            command = "layout tabbed";
            criteria.class = "firefox";
          }
          {
            command = "border pixel";
            criteria.class = "^(steam_app.*)$";
          }
          {
          command = "floating enable, sticky enable, border pixel";
          criteria.title = "Picture-in-Picture";
          }
        ];
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
        border = 3;
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

          "${mod}+x" = "swap container with quickmark";
          #"${mod}+n" = "exec ${wl-color-picker}/bin/wl-color-picker clipboard";
          "${mod}+n" = "exec swaync-client -t -sw";
          "${mod}+o" = "exec ${wl-mirror}/bin/wl-present mirror";
          # Apps
          "${mod}+Return" = "exec uwsm app -- kitty";
          "${mod}+Tab" = "exec swayr switch-workspace-or-window";
          "${mod}+Delete" = "exec swayr quit-window";

          "${mod}+a" = "mode app_launch_mode";

          # Next Window should open Horizontally or Vertically from focused
          "${mod}+Control+Up" = "split v";
          "${mod}+Control+Down" = "split v";
          "${mod}+Control+Left" = "split h";
          "${mod}+Control+Right" = "split h";
          "${mod}+Control+Space" = "layout toggle split";
          "${mod}+Control+g" = "layout tabbed";

          "${mod}+Control+w" = "mode quick_swap_mode";
          "${mod}+Control+p" = "mode quick_move_mode";

          "${mod}+Control+a" = "mark --add quickmark";
          "${mod}+Control+1" = "mark --add 1";
          "${mod}+Control+2" = "mark --add 2";
          "${mod}+Control+3" = "mark --add 3";
          "${mod}+Control+4" = "mark --add 4";
          "${mod}+Control+5" = "mark --add 5";





          # Toggle Fullscreen or Floating Windows
          "${mod}+Control+f" = "floating toggle";
          "${mod}+Control+m" = "fullscreen toggle"; # maximized apps on 32:9 feels odd, may as well use fullscreen when wanting for games

          # Resize Windows
          "${mod}+Alt+Shift+Up" = "resize grow height 5 px or 5 ppt";
          "${mod}+Alt+Shift+Down" = "resize shrink height 5 px or 5 ppt";
          "${mod}+Alt+Shift+Left" = "resize shrink width 5 px or 5 ppt";
          "${mod}+Alt+Shift+Right" = "resize grow width 5 px or 5 ppt";
          "${mod}+r" = "mode resize_mode";

          "XF86AudioMute" = "exec ${wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          "XF86AudioLowerVolume" = "exec ${wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- -l 1.2";
          "XF86AudioRaiseVolume" = "exec ${wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ -l 1.2";

        }
        commonKeybindings
      ];

      modes = {
        resize_mode = {
          "Up" = "resize grow height 5 px or 5 ppt";
          "Down" = "resize shrink height 5 px or 5 ppt";
          "Left" = "resize shrink width 5 px or 5 ppt";
          "Right" = "resize grow width 5 px or 5 ppt";
          "Shift+Up" = "resize grow height 10 px or 10 ppt";
          "Shift+Down" = "resize shrink height 10 px or 10 ppt";
          "Shift+Left" = "resize shrink width 10 px or 10 ppt";
          "Shift+Right" = "resize grow width 10 px or 10 ppt";

          "Control+c" = "mode default";
          "Escape" = "mode default";
        };

        app_launch_mode = {
          "Return" = "exec uwsm app -- kitty & swaymsg mode default;";
          "D" = "exec uwsm app -- discord & swaymsg mode default;";
          "W" = "exec uwsm app -- firefox & swaymsg mode default;";
          "V" = "exec uwsm app -- pwvucontrol & swaymsg mode default;";
          "E" = "exec uwsm app -- emacs; swaymsg & mode default;";
          "S" = "exec grimblast copy area & swaymsg mode default;";
          "Control+S" = "exec grimblast copy screen & swaymsg mode default;";
          "M" = "exec uwsm app -- youtube-music & swaymsg mode default;";
          "t" = "mode terminal_launch_mode";

          "Control+c" = "mode default";
          "Escape" = "mode default";
        };
        terminal_launch_mode = {
          "Return" = "exec uwsm app -- kitty & swaymsg mode default";
          "t" = "exec uwsm app -- kitty & swaymsg mode default";
          "y" = "exec uwsm app -- kitty yazi & swaymsg mode default";

          "Control+c" = "mode default";
          "Escape" = "mode default";
        };
        quick_swap_mode ={
          "a" = "swap container with quickmark & swaymsg mode default";
          "1" = "swap container with 1 & swaymsg mode default";
          "2" = "swap container with 2 & swaymsg mode default";
          "3" = "swap container with 3 &swaymsg mode default";
          "4" = "swap container with 4 & swaymsg mode default";
          "5" = "swap container with 5 & swaymsg mode default";
          "Control+a" = "swap container with quickmark & swaymsg mode default";
          "Control+1" = "swap container with 1 & swaymsg mode default";
          "Control+2" = "swap container with 2 & swaymsg mode default";
          "Control+3" = "swap container with 3 & swaymsg mode default";
          "Control+4" = "swap container with 4 & swaymsg mode default";
          "Control+5" = "swap container with 5 & swaymsg mode default";

          "Control+c" = "mode default";
          "Escape" = "mode default";
        };

        quick_move_mode = {
          "a" = "move window with quickmark & swaymsg mode default";
          "1" = "move window with 1 & swaymsg mode default";
          "2" = "move window with 2 & swaymsg mode default";
          "3" = "move window with 3 & swaymsg mode default";
          "4" = "move window with 4 & swaymsg mode default";
          "5" = "move window with 5 & swaymsg mode default";
          "Control+a" = "move container with quickmark & swaymsg mode default";
          "Control+1" = "move container with 1 & swaymsg mode default";
          "Control+2" = "move container with 2 & swaymsg mode default";
          "Control+3" = "move container with 3 & swaymsg mode default";
          "Control+4" = "move container with 4 & swaymsg mode default";
          "Control+5" = "move container with 5 & swaymsg mode default";

          "Control+c" = "mode default";
          "Escape" = "mode default";
        };
      };

      startup = [

        {
          command = "xrandr --output DP-1 --primary";
          always = true;
        }
        {
          command = "waybar";
        }       {
          command = "swaync";
        }
        {
          command = "swaymsg workspace number 1";
        }
        {
          command = "steam && youtube-music";
        }
        {
          command = "swaymsg workspace number 2";
        }
        {
          command = "firefox";
        }
        {
          command = "swaymsg workspace number 3";
        }
        {
          command = "emacs";
        }
        {
          command = "cat ${osConfig.age.secrets.juicy-keepass-master.path} | keepassxc --pw-stdin --keyfile '/home/juicy/.ssh/keepass_juicy' '/home/juicy/documents/Passwords.kdbx'";
        }
        {
          command = "swaymsg workspace number 4";
        }
        {
          command = "signal-desktop";
        }
        {
          command = "telegram-desktop;";
        }
      ];
    };
  };
}

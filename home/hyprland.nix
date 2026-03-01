{
  osConfig,
  config,
  pkgs,
  lib,
  ...
}:
with pkgs; let
  stylix = config.lib.stylix.colors;
  hasRole = role: builtins.elem role osConfig.modules.system.roles;
  desktop = hasRole "desktop";
  desktopGaming = hasRole "desktop-gaming";
  desktopBloat = hasRole "desktop-bloat";
  desktopSunshine = hasRole "desktop-sunshine";
  desktopEmacs = hasRole "desktop-emacs";
  zsaEnabled = hasRole "keyboard-zsa";

  opacity = "0.95";

  mod = "SUPER";
  kbLayout = "us";

  primaryMonitorName = osConfig.modules.desktop.primaryMonitorName or "DP-2";
  primaryMonitorOutput = primaryMonitorName;
  primaryMonitorMode = osConfig.modules.desktop.primaryMonitorMode or "preferred";

  smartFocusAction = import ../lib/smart-focus-action.nix {inherit pkgs;};
  smartFocusActionExe = lib.getExe smartFocusAction;

  submapReset = ''
    bind = , escape, submap, reset
  '';

  directionName = d:
    if d == "l"
    then "left"
    else if d == "r"
    then "right"
    else if d == "u"
    then "up"
    else if d == "d"
    then "down"
    else d;

  workspaces = map toString (lib.range 1 9);

  # Map arrow keys to hyprland directions (l, r, u, d)
  directions = {
    left = "l";
    right = "r";
    up = "u";
    down = "d";
  };
  default-apps = {
    browser = "${pkgs.vivaldi}/bin/vivaldi";
    browser-private = "${pkgs.vivaldi}/bin/vivaldi --incognito";
    clipboard-manager = "caelestia clipboard";
    global-launcher = "caelestia:launcher";
    pass-manager = "${pkgs.bitwarden-desktop}/bin/bitwarden";
    volume-mixer = "${pkgs.pwvucontrol}/bin/pwvucontrol";
    terminal = "${pkgs.kitty}/bin/kitty";
  };
in {
  config = lib.mkIf desktop {
    home.packages = [
      pkgs.runelite
      pkgs.socat
      pkgs.wayscriber
    ];

    services = {
      hyprpolkitagent.enable = true;

      hyprsunset = {
        enable = true;
        settings = {
          max-gamma = 200;

          profile = [
            {
              time = "7:30";
              identity = true;
              gamma = 1;
            }
            {
              time = "18:30";
              temperature = 4000;
              gamma = 0.8;
            }
            {
              time = "21:00";
              temperature = 3000;
              gamma = 0.6;
            }
          ];
        };
      };

      hyprpaper.enable = lib.mkForce false;
    };

    programs.hyprlock.enable = true;

    wayland.windowManager.hyprland = {
      enable = true;
      package = osConfig.programs.hyprland.package;
      portalPackage = osConfig.programs.hyprland.portalPackage;
      systemd.enable = true;

      settings = {
        env = [
          "XDG_CURRENT_DESKTOP,Hyprland"
          "XDG_SESSION_DESKTOP,Hyprland"
          "LIBVA_DRIVER_NAME,radeonsi"
          "VDPAU_DRIVER,radeonsi"
        ];

        monitorv2 = [
          {
            output = primaryMonitorOutput;
            mode = primaryMonitorMode;
            position = "0x0";
            scale = 1;
          }
        ];

        exec-once =
          [
            "wayscriber -d --no-tray"
          ]
          ++ lib.optionals desktopGaming ["[workspace 1 silent] steam"]
          ++ [
            "[workspace 2 silent] ${default-apps.browser}"
          ]
          ++ [
            "[workspace 6 silent] bitwarden"
          ]
          ++ lib.optionals zsaEnabled ["[workspace 9 silent] keymapp"];

        input = {
          kb_layout = kbLayout;
          repeat_rate = 50;
          repeat_delay = 300;

          accel_profile = "flat";
          follow_mouse = 1;
          sensitivity = "-0.3";
          mouse_refocus = false;
          touchpad = {
            natural_scroll = true;
            disable_while_typing = false;
            scroll_factor = "0.9";
          };
        };
        device = [
          {
            name = "apple-inc.-magic-trackpad";
            accel_profile = "adaptive";
            sensitivity = "0.4";
          }
        ];

        gestures = {
          workspace_swipe_distance = 650;
          workspace_swipe_cancel_ratio = "0.4";
        };
        gesture = [
          "3, horizontal, workspace"
          "2, pinchin, mod: ${mod}, float, tile"
          "2, pinchout, mod: ${mod}, float"
          "3, up, fullscreen"
        ];

        cursor = {
          inactive_timeout = 10;
          default_monitor = primaryMonitorName;
          no_hardware_cursors = 0;
          enable_hyprcursor = true;
          no_break_fs_vrr = 2;
        };

        general = {
          gaps_in = 8;
          border_size = 4;
          resize_on_border = true;
          extend_border_grab_area = 3;
          layout = "master";

          snap = {
            enabled = true;
            window_gap = 15;
            monitor_gap = 10;
            border_overlap = false;
            respect_gaps = true;
          };
        };

        group = {
          drag_into_group = 2;
          groupbar = {
            enabled = true;
            indicator_height = 0;
            font_size = 14;
            height = 32;
            gradients = true;
            gradient_rounding = 16;
            gaps_out = 16;
            gaps_in = 4;
            keep_upper_gap = false;
          };
        };

        decoration = {
          rounding = 25;
          rounding_power = "1.0";
          dim_special = "0.25";

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
          force_zero_scaling = true;
        };
        render = {
          direct_scanout = 2;
          cm_fs_passthrough = 2;
          cm_enabled = true;
        };
        animations = {
          enabled = true;
          workspace_wraparound = true;
          bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";

          animation = [
            "windows, 1, 7, myBezier"
            "windowsOut, 1, 7, default, popin 80%"
            "border, 1, 10, default"
            "borderangle, 1, 30, default"
            "fade, 1, 7, default"
            "workspaces, 1, 6, default, slide"
            "specialWorkspace, 1, 6, default, slidevert"
          ];
        };

        #       layout = {
        #          single_window_aspect_ratio = "21 9";
        #single_window_aspect_ratio_tolerance = 0;
        #       };
        dwindle = {
          preserve_split = true;
          default_split_ratio = "1";
          split_width_multiplier = "1.25";
          special_scale_factor = 0.7;
        };

        master = {
          mfact = 0.45;
          special_scale_factor = 0.8;
          allow_small_split = false;
          new_status = "slave";
          new_on_top = false;
          orientation = "center";
          slave_count_for_center_master = 0; # TEST does more predefined zones help me
          center_master_fallback = "left";
          always_keep_position = true;
        };

        scrolling = {
          fullscreen_on_one_column = false;
          column_width = 0.35;
          focus_fit_method = 1;
          follow_focus = false;
          follow_min_visible = 0;
          explicit_column_widths = "0.28,0.36,0.42,0.50,0.66,1.0";
          direction = "right";
        };

        plugin = {
          hyprbars = {
            bar_height = 30;
            bar_text_size = 13;
            bar_color = "rgba(${stylix.base01}dd)";
            bar_text_font = config.wayland.windowManager.hyprland.settings.misc.font_family;
            hyprbars-button = let
              closeAction = "hyprctl dispatch killactive";

              isOnSpecial = ''hyprctl activewindow -j | jq -re 'select(.workspace.name == "minimized")' >/dev/null'';
              moveToSpecial = "hyprctl dispatch movetoworkspacesilent minimized";
              moveToActive = "hyprctl dispatch movetoworkspacesilent $(hyprctl -j activeworkspace | jq -re '.id')";
              minimizeAction = "${isOnSpecial} && ${moveToActive} || ${moveToSpecial}";

              maximizeAction = "hyprctl dispatch fullscreen 1";
            in [
              "rgb(ff4040),12,,${closeAction}"
              # Yellow "minimize" (send to special workspace) button
              "rgb(eeee11),12,,${minimizeAction}"
              # Green "maximize" (fullscreen) button
              "rgb(dddd11),12,,${maximizeAction}"
            ];
          };
        };

        binds = {
          allow_workspace_cycles = true;
        };

        windowrule = let
          steamGame = "match:class (steam_app_[0-9]*)";
          wineTray = "match:class explorer.exe";

          terminalClasses = "(kitty|com.mitchellh.ghostty)";
          chatClasses = "(discord|vesktop|signal|org.telegram.desktop)";
          utilityClasses = "(thunar|com.saivert.pwvucontrol|RimPy|org.keepassxc.KeePassXC|bitwarden|Tk|xdg-desktop-portal-gtk|nm-connection-editor|blueman-manager)";
          devClasses = "(emacs|code|codium)";
        in [
          # Don’t steal focus when launching
          "no_initial_focus on, match:class (steam|${chatClasses})"

          # Modal/file dialogs should stay central and predictable.
          "stay_focused on, match:title (Open|Save|Save As|Open File)"
          "float on, center on, size (monitor_w*0.34) (monitor_h*0.62), match:title (Open|Save|Save As|Open File|Choose File|Preferences|Settings)"

          # Tagging
          "tag +terminal, match:class ${terminalClasses}"
          "tag +chat, match:class ${chatClasses}"
          "tag +utility, match:class ${utilityClasses}"
          "tag +dev, match:class (${terminalClasses}|${devClasses})"
          "tag +video, match:class mpv"
          "tag +video, match:title (Picture-in-Picture|Picture in picture)"

          # Tiling-first layout: only utilities (and PiP below) stay floating.
          "workspace 3 silent, match:class ${chatClasses}"
          "tile on, match:tag chat"
          "float on, size (monitor_w*0.24) (monitor_h*0.70), move (monitor_w-window_w-(monitor_w*0.035)) ((monitor_h-window_h)/2), match:tag utility"

          # Screen share restrictions
          "no_screen_share on, match:class (org.keepassxc.KeePassXC|bitwarden)"
          "no_screen_share on, match:title (.*Private Browsing), match:class (chromium-browser|vivaldi-stable)"

          # Video behavior for tagged windows
          "content video, idle_inhibit always, border_size 0, no_dim on, match:tag video"
          "suppress_event fullscreen fullscreenoutput maximize, match:class (vivaldi-stable|chromium-browser)"

          # PiP and pinned windows: inset zones (not hard corners) for 32:9 ergonomics.
          "float on, pin on, no_initial_focus on, persistent_size on, suppress_event activatefocus, size (monitor_w*0.22) (monitor_h*0.26), move (monitor_w-window_w-(monitor_w*0.03)) (monitor_h*0.05), match:title (Picture-in-Picture|Picture in picture)"
          "float on, pin on, size (monitor_w*0.22) (monitor_h*0.28), move (monitor_w-window_w-(monitor_w*0.03)) (monitor_h-window_h-(monitor_h*0.06)), match:class (pinned)"

          # Game rules
          "workspace 1 silent, match:class steam"

          "border_size 0, idle_inhibit always, no_dim on, workspace 5 silent, match:xdg_tag proton-game"
          "border_size 0, idle_inhibit always, no_dim on, workspace 5 silent, ${steamGame}"
          "workspace minimized silent, ${wineTray}"
          "max_size 2000 1200, float on, center on, match:class battle.net.exe"
          "suppress_event fullscreen, fullscreen on, match:initial_title (World of Warcraft)"

          # VM windows tile
          "tile on, match:class (.qemu-system-x86_64-wrapped)"

          # Opacity
          "opacity ${opacity} ${opacity}, match:class thunar"
          "opacity 0.97 0.92, match:tag dev"
          "opacity 0.95 0.88, match:tag utility"
          "opacity 0.96 0.89, match:tag chat"

          # Workspace rules (TV, floating layouts)
          "border_size 0, match:float 0, match:workspace w[tv1]"
          "rounding 0, match:float 0, match:workspace w[tv1]"
          "border_size 0, match:float 0, match:workspace f[1]"
          "rounding 0, match:float 0, match:workspace f[1]"
        ];

        workspace = [
          "1, monitor:${primaryMonitorOutput}"
          "2, monitor:${primaryMonitorOutput}, default:true, layoutopt:direction:right"
          "3, monitor:${primaryMonitorOutput}"
          "4, monitor:${primaryMonitorOutput}, gapsin:0, gapsout:0, rounding:false, decoration:false"
          "5, monitor:${primaryMonitorOutput}, shadow:0, gapsin:0, gapsout:0, rounding:false, decoration:false"

          "0, monitor:Virtual"
          "special:minimized, monitor:${primaryMonitorOutput}"
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
          initial_workspace_tracking = 0;
          font_family = "IosevkaTerm Nerd Font";
          enable_swallow = true;
          swallow_regex = [
            "^(com.mitchellh.ghostty)$"
            "^(kitty)$"
          ];
          session_lock_xray = true;
          vfr = true;
          vrr = 1;
          size_limits_tiled = true;
          mouse_move_enables_dpms = false;
        };

        bindd =
          [
            "${mod}, W, Windows, submap, window"
            "${mod}, A, Apps, submap, openApps"
            "${mod}, T, Terminal Apps, submap, openTerminal"
            "${mod}, L, Layout, submap, layout"
            "${mod}, G, Groups, submap, group"
            "${mod}CONTROL, S, System, submap, system"
            "${mod}, M, Media, submap, media"

            "${mod}, tab, Group next, changegroupactive, f"
            "${mod}SHIFT, tab, Group previous, changegroupactive, b"

            "${mod}, Space, Launcher, global, ${default-apps.global-launcher}"
            "${mod}SHIFT, Q, Close window, killactive"
            "${mod}CONTROL, M, Toggle fullscreen, fullscreen, 0"
            "${mod}CONTROL, Enter, Toggle fullscreen, fullscreen, 0"
            "${mod}CONTROL, F, Toggle floating, togglefloating"
            "${mod}CONTROL, P, Toggle pin, pin"
            "${mod}SHIFT, slash, Submap options, global, submap-cheatsheet:toggle-submap-options"
            "${mod}CONTROL, Space, Swap split, layoutmsg, swapsplit"

            "${mod}, Return, terminal (tmux smart), exec, ${default-apps.terminal}"
            "${mod}SHIFT, Return, kitty pinned, exec, ${default-apps.terminal} --class pinned"
            #"${mod}, d, Toggle comms, exec, ${commsToggleCommand}"
          ]
          ++ lib.optionals desktopEmacs ["${mod}, E, Emacs, submap, emacs"]
          ++
          # Change workspace//
          (map (n: "${mod},${n},Workspace ${n},workspace,${n}") workspaces)
          ++
          # Move window to workspace
          (map (n: "${mod}SHIFT,${n},Move to ws ${n},movetoworkspacesilent,${n}") workspaces)
          ++
          # Move focus
          (lib.mapAttrsToList (
              key: direction: "${mod},${key},Focus ${directionName direction},exec,${smartFocusActionExe} ${direction} auto"
            )
            directions)
          ++
          # Move windows
          (lib.mapAttrsToList (
              key: direction: "${mod}SHIFT,${key},Move ${directionName direction},movewindoworgroup,${direction}"
            )
            directions)
          ++
          # Open next window in given direction in dwindle
          (lib.mapAttrsToList (
              key: direction: "${mod}CONTROL,${key},Preselect ${directionName direction},layoutmsg,preselect ${direction}"
            )
            directions)
          ++
          # Open next window in given direction in dwindle
          (lib.mapAttrsToList (
              key: direction: "${mod}CONTROL,${key},Move Focus ${directionName direction},layoutmsg,focus ${direction}"
            )
            directions);

        bindmd = [
          "SUPER, mouse:272, Move window, movewindow"
          "SUPER, mouse:273, Resize window, resizewindow"
        ];

        binded = [
          # Change master ratio
          "${mod},minus,Master ratio -,layoutmsg,mfact -0.05"
          "${mod}SHIFT,minus,Master ratio --,layoutmsg,mfact -0.125"
          "${mod},plus,Master ratio +,layoutmsg,mfact +0.05"
          "${mod}SHIFT,plus,Master ratio ++,layoutmsg,mfact +0.125"

          # Resize windows with mainMod + SUPER + arrow keys
          "${mod}ALT, left, Resize left,resizeactive,75 0"
          "${mod}ALT, right, Resize right,resizeactive,-75 0"
          "${mod}ALT, up, Resize up,resizeactive,0 -75"
          "${mod}ALT, down, Resize down,resizeactive,0 75"
          ", XF86AudioRaiseVolume, Volume up, exec, wpctl set-volume @DEFAULT_SINK@ 5%+"
          ", XF86AudioLowerVolume, Volume down, exec, wpctl set-volume @DEFAULT_SINK@ 5%-"
          ", XF86AudioForward, Seek +10s, exec, playerctl -p playerctld position 10+"
          ", XF86AudioRewind, Seek -10s, exec, playerctl -p playerctld position 10-"
        ];

        bindld = [
          ", XF86AudioPrev, Previous track, exec, playerctl -p playerctld previous"
          ", XF86AudioNext, Next track, exec, playerctl -p playerctld next"
          ", XF86AudioPlay, Play, exec, playerctl -p playerctld play"
          ", XF86AudioPause, Pause, exec, playerctl -p playerctld pause"
          ", XF86Messenger, Special workspace, togglespecialworkspace"
        ];
      };

      extraConfig =
        # hyprlang
        ''
                    bindd = ${mod}ALT, BackSpace, Passthrough, submap, passthrough
                    submap = passthrough
                      ${submapReset}
                    submap = reset

                    submap = openApps
                      bindd = , Return, Terminal, exec, ${default-apps.terminal}
                      bind = , Return, submap, reset
                      bindd = , W, Web Browser, exec, ${default-apps.browser}
                      bind = , W, submap, reset
                      bindd = , P, Web Browser Private, exec, ${default-apps.browser-private}
                      bind = , P, submap, reset
                      bindd = , B, Password Manager, exec, ${default-apps.pass-manager}
                      bind = , B, submap, reset

                      bindd = , S, Screenshot, global, caelestia:screenshotFreezeClip
                      bind = , B, submap, reset
                      bindd = , D, Discord, exec, discord
                      bind = , D, submap, reset
                      bindd = , C, Clipboard, exec, ${default-apps.clipboard-manager}
                      bind = , C, submap, reset
                      bindd = , Space, Launcher, global, ${default-apps.global-launcher}
                      bind = , Space, submap, reset
                      bindd = , V, Volume Mixer, exec, ${default-apps.volume-mixer}
                      bind = , V, submap, reset
                      bindd = , T, Terminals, submap, openTerminal
                      ${lib.optionalString desktopEmacs "bindd = , E, Emacs, submap, emacs"}
                      ${submapReset}
                    submap = reset

                    submap = window
                      bindd = , left, Focus left, movefocus, l
                      bindd = , right, Focus right, movefocus, r
                      bindd = , up, Focus up, movefocus, u
                      bindd = , down, Focus down, movefocus, d
                      bindd = , M, Move window, submap, windowMove
                      bindd = , R, Resize window, submap, windowResize

                      bindd = , F, Toggle fullscreen, fullscreen, 0
                      bind = , F, submap, reset
                      bindd = , T, Toggle floating, togglefloating
                      bind = , T, submap, reset
                      bindd = , P, Toggle pin, pin
                      bind = , P, submap, reset
                      bindd = , Q, Close window, killactive
                      bind = , Q, submap, reset
                      bindd = , S, Swap split, layoutmsg, swapsplit
                      bind = , S, submap, reset
                      bindd = , G, Groups, submap, group
                      ${submapReset}
                    submap = reset

                    submap = windowMove
                      bindd = , left, Move left, movewindoworgroup, l
                      bind = , left, submap, reset
                      bindd = , right, Move right, movewindoworgroup, r
                      bind = , right, submap, reset
                      bindd = , up, Move up, movewindoworgroup, u
                      bind = , up, submap, reset
                      bindd = , down, Move down, movewindoworgroup, d
                      bind = , down, submap, reset
                      ${submapReset}
                    submap = reset

                    submap = windowResize
                      bindd = , left, Resize left, resizeactive, 75 0
                      bindd = , right, Resize right, resizeactive, -75 0
                      bindd = , up, Resize up, resizeactive, 0 -75
                      bindd = , down, Resize down, resizeactive, 0 75
                      ${submapReset}
                    submap = reset

                    submap = layout
                      bindd = , M, Master Layout, exec, hyprctl keyword general:layout master
                      bind = , M, submap, reset
                      bindd = , D, Dwindle Layout, exec, hyprctl keyword general:layout dwindle
                      bind = , D, submap, reset
                      bindd = , C, Scrolling Layout, exec, hyprctl keyword general:layout scrolling
                      bind = , C, submap, reset
                      bindd = , X, Monocle Layout, exec, hyprctl keyword general:layout monocle
                      bind = , X, submap, reset
                      bindd = , W, Window Actions, submap, window
                      bindd = , G, Group Actions, submap, group
                      bindd = , V, Move Window, submap, windowMove
                      bindd = , R, Resize Window, submap, windowResize
                      bindd = , T, Move to Root, layoutmsg, movetoroot active
                      bind = , T, submap, reset
                      bindd = , O, Master resize to 50%, layoutmsg, mfact exact 0.5
                      bind = , O, submap, reset
                      bindd = , S, Toggle split, layoutmsg, togglesplit
                      bind = , S, submap, reset
                      bindd = , U, Master resize to 65%, layoutmsg, mfact exact 0.65
                      bind = , U, submap, reset
                      bindd = , period, Scroll next column, layoutmsg, move +col
                      bindd = , comma, Scroll previous column, layoutmsg, move -col
                      bindd = , bracketright, Column wider, layoutmsg, colresize +0.05
                      bindd = , bracketleft, Column narrower, layoutmsg, colresize -0.05
                      bindd = , J, Swap column left, layoutmsg, swapcol l
                      bindd = , K, Swap column right, layoutmsg, swapcol r
                      bindd = , H, Scroll focus left, layoutmsg, focus l
                      bindd = , L, Scroll focus right, layoutmsg, focus r
                      bindd = , F, Fit visible columns, layoutmsg, fit visible
                      bindd = , Y, Toggle fit mode, layoutmsg, togglefit
                      bindd = , left, Master to the Left, layoutmsg, orientationleft
                      bind = , left, submap, reset
                      bindd = , up, Master Centered, layoutmsg, orientationcenter
                      bind = , up, submap, reset
                      bindd = , down, Master Centered, layoutmsg, orientationcenter
                      bind = , down, submap, reset
                      bindd = , N, Gapless preset, exec, hyprctl --batch 'keyword general:gaps_out 0 ; keyword general:gaps_in 0 ; keyword decoration:rounding 0'
                      bind = , N, submap, reset
                      bindd = , P, Default preset, exec, hyprctl --batch 'keyword general:gaps_out 16 ; keyword general:gaps_in 8 ; keyword decoration:rounding 25'
                      bind = , P, submap, reset


                        ${submapReset}
                    submap = reset

                    submap = group
                      bindd = , G, Toggle group, togglegroup
                      bind = , G, submap, reset
                      bindd = , L, Lock group, lockactivegroup, toggle
                      bind = , L, submap, reset
                      bindd = , U, Ungroup active, moveoutofgroup, active
                      bind = , U, submap, reset
                      bindd = , M, Move window, submap, windowMove
                      bindd = , R, Resize window, submap, windowResize
                      bindd = , 1, Focus Group Tab 1, changegroupactive, 1
                      bind = , 1, submap, reset
                      bindd = , 2, Focus Group Tab 2, changegroupactive, 2
                      bind = , 2, submap, reset
                      bindd = , 3, Focus Group Tab 3, changegroupactive, 3
                      bind = , 3, submap, reset
                      bindd = , 4, Focus Group Tab 4, changegroupactive, 4
                      bind = , 4, submap, reset
                      bindd = , 5, Focus Group Tab 5, changegroupactive, 5
          bind = , 5, submap, reset

                        ${submapReset}

                    submap = reset

                    ${lib.optionalString desktopEmacs ''
            submap = emacs
              bindd = , E, Emacs raise, exec, emacsclient -r
              bind = , E, submap, reset
              bindd = , F, Emacs focus, focuswindow, class:(emacs)
              bind = , F, submap, reset
              bindd = , N, Emacs new frame, exec, emacsclient -c
              bind = , N, submap, reset
              bindd = , C, Emacs cwd, exec, emacsclient -r .
              bind = , C, submap, reset
              bindd = , D, Emacs org today, exec, emacsclient -c --eval "(call-interactively org-dailies-goto-today)"
              bind = , D, submap, reset
              ${submapReset}
            submap = reset
          ''}

                    submap = system

                      bindd = , N, Clear notifs, global, caelestia:clearNotifs

                      bindd = , S, Screenshot, global, caelestia:screenshotFreezeClip
                      bindd = , A, Annotate, exec, pkill -SIGUSR1 wayscriber
                      bindd = , O, Logout, exec, loginctl terminate-user "$(whoami)"
                      bindd = , R, Reboot, exec, systemctl reboot
                      bindd = , H, Hibernate, exec, systemctl hibernate
                      bindd = , X, Shutdown, exec, systemctl poweroff
                      ${submapReset}
                    submap = reset

                    submap = media
                      bindd = , Space, Play pause, exec, playerctl -p playerctld play-pause
                      bind = , Space, submap, reset
                      bindd = , P, Previous track, exec, playerctl -p playerctld previous
                      bind = , P, submap, reset
                      bindd = , N, Next track, exec, playerctl -p playerctld next
                      bind = , N, submap, reset
                      bindd = , left, Seek -10s, exec, playerctl -p playerctld position 10-
                      bind = , left, submap, reset
                      bindd = , right, Seek +10s, exec, playerctl -p playerctld position 10+
                      bind = , right, submap, reset
                      bindd = , minus, Volume down, exec, wpctl set-volume @DEFAULT_SINK@ 5%-
                      bindd = , plus, Volume up, exec, wpctl set-volume @DEFAULT_SINK@ 5%+
                      bindd = , M, Toggle mute, exec, wpctl set-mute @DEFAULT_SINK@ toggle
                      bind = , M, submap, reset
                      bindd = , V, Volume Mixer, exec, ${default-apps.volume-mixer}
                      bind = , V, submap, reset
                      ${submapReset}
                    submap = reset
        '';
    };
  };
}

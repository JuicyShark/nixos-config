{
  nix-config,
  system,
  osConfig,
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (nix-config.lib.${system}.roles) mkHasRoleHome;
  hasRole = mkHasRoleHome osConfig;
  desktop = hasRole "desktop";
  niriEnabled = hasRole "desktop-niri";
  desktopGaming = hasRole "desktop-gaming";
  desktopBloat = hasRole "desktop-bloat";
  zsaEnabled = hasRole "keyboard-zsa";

  stylix = config.lib.stylix.colors;
  kbLayout = "us";
  primaryMonitorName = osConfig.modules.desktop.primaryMonitorName or "DP-1";
  primaryMonitorMode = osConfig.modules.desktop.primaryMonitorMode or "5120x1440@120";

  tmuxTerminalAction = import ../lib/tmux-terminal-action.nix { inherit pkgs; };

  tmuxTerminalActionExe = lib.getExe tmuxTerminalAction;
in
{
  config = lib.mkIf (desktop && niriEnabled) {
    home.packages = [
      pkgs.runelite
      pkgs.socat
      pkgs.wayscriber
    ];

    xdg.configFile."niri/config.kdl".text = ''
      input {
          keyboard {
              xkb {
                  layout "${kbLayout}"
              }
          }

          touchpad {
              natural-scroll
              accel-speed -0.3
          }

          mouse {
              accel-profile "flat"
              accel-speed -0.3
          }
      }

      output "${primaryMonitorName}" {
          mode "${primaryMonitorMode}"
          scale 1
      }

      layout {
          gaps 8
          center-focused-column "on-overflow"
          default-column-width { proportion 0.5; }

          preset-column-widths {
              proportion 0.25
              proportion 0.33
              proportion 0.4
              proportion 0.5
          }

          focus-ring {
              width 4
              active-color "#${stylix.base0D}"
              inactive-color "#${stylix.base03}"
          }

          border {
              off
          }

          shadow {
              on
              softness 30
              spread 5
              offset x=0 y=5
              color "#0007"
          }
      }

      screenshot-path "~/media/pictures/screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

      animations {
          workspace-switch {
              spring damping-ratio=1.0 stiffness=900 epsilon=0.0001
          }
      }

      spawn-sh-at-startup "wayscriber -d --no-tray"
      ${lib.optionalString desktopGaming ''spawn-sh-at-startup "steam"''}

      ${lib.optionalString desktopBloat ''spawn-sh-at-startup "discord"''}
      spawn-sh-at-startup "bitwarden"
      ${lib.optionalString zsaEnabled ''spawn-sh-at-startup "keymapp"''}

      window-rule {
          match app-id=r#"^(discord|vesktop|signal|org.telegram.desktop)$"#
          open-on-workspace "3"
          default-column-width { proportion 0.33; }
      }

      window-rule {
          match app-id=r#"^(emacs|code|codium|chromium-browser|vivaldi-stable)$"#
          open-on-workspace "2"
          default-column-width { proportion 0.5; }
      }

      window-rule {
          match app-id=r#"^(kitty|com.mitchellh.ghostty)$"#
          default-column-width { proportion 0.25; }
      }

      window-rule {
          match app-id=r#"^(pwvucontrol|com.saivert.pwvucontrol|nm-connection-editor|blueman-manager)$"#
          open-floating true
          default-column-width { proportion 0.2; }
          default-window-height { proportion 0.65; }
      }

      window-rule {
          match app-id=r#"^(steam_app_[0-9]+)$"#
          open-on-workspace "5"
          open-fullscreen true
      }

      window-rule {
          match app-id=r#"^(org\.keepassxc\.KeePassXC|bitwarden)$"#
          block-out-from "screen-capture"
      }

      window-rule {
          match title="^(Picture-in-Picture|Picture in picture)$"
          open-floating true
          default-column-width { proportion 0.2; }
          default-window-height { proportion 0.24; }
          default-floating-position x=24 y=24 relative-to="top-right"
      }

      binds {
          Mod+Return { spawn-sh "kitty -d=current -e tmux new-session"; }
          Mod+T { spawn-sh "${tmuxTerminalActionExe} attach"; }
          Mod+Ctrl+H { spawn-sh "${tmuxTerminalActionExe} split-h"; }
          Mod+Ctrl+V { spawn-sh "${tmuxTerminalActionExe} split-v"; }
          Mod+Ctrl+N { spawn-sh "${tmuxTerminalActionExe} new-window"; }
          Mod+Ctrl+Left { spawn-sh "${tmuxTerminalActionExe} prev-window"; }
          Mod+Ctrl+Right { spawn-sh "${tmuxTerminalActionExe} next-window"; }

          Mod+Space { spawn-sh "caelestia shell drawers toggle launcher"; }


          Mod+Shift+Q repeat=false { close-window; }
          Mod+Ctrl+Return { fullscreen-window; }
          Mod+Ctrl+M { maximize-window-to-edges; }
          Mod+Ctrl+F { toggle-window-floating; }

          Mod+Left { focus-column-left; }
          Mod+Down { focus-window-down; }
          Mod+Up { focus-window-up; }
          Mod+Right { focus-column-right; }
          Mod+H { focus-column-left; }
          Mod+J { focus-window-down; }
          Mod+K { focus-window-up; }
          Mod+L { focus-column-right; }

          Mod+Shift+Left { move-column-left; }
          Mod+Shift+Down { move-window-down; }
          Mod+Shift+Up { move-window-up; }
          Mod+Shift+Right { move-column-right; }
          Mod+Shift+H { move-column-left; }
          Mod+Shift+J { move-window-down; }
          Mod+Shift+K { move-window-up; }
          Mod+Shift+L { move-column-right; }

          Mod+Alt+Left { set-column-width "-5%"; }
          Mod+Alt+Right { set-column-width "+5%"; }
          Mod+Alt+Up { set-window-height "-5%"; }
          Mod+Alt+Down { set-window-height "+5%"; }

          Mod+1 { focus-workspace 1; }
          Mod+2 { focus-workspace 2; }
          Mod+3 { focus-workspace 3; }
          Mod+4 { focus-workspace 4; }
          Mod+5 { focus-workspace 5; }
          Mod+6 { focus-workspace 6; }
          Mod+7 { focus-workspace 7; }
          Mod+8 { focus-workspace 8; }
          Mod+9 { focus-workspace 9; }

          Mod+Shift+1 { move-window-to-workspace 1; }
          Mod+Shift+2 { move-window-to-workspace 2; }
          Mod+Shift+3 { move-window-to-workspace 3; }
          Mod+Shift+4 { move-window-to-workspace 4; }
          Mod+Shift+5 { move-window-to-workspace 5; }
          Mod+Shift+6 { move-window-to-workspace 6; }
          Mod+Shift+7 { move-window-to-workspace 7; }
          Mod+Shift+8 { move-window-to-workspace 8; }
          Mod+Shift+9 { move-window-to-workspace 9; }

          XF86AudioRaiseVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_SINK@ 5%+"; }
          XF86AudioLowerVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_SINK@ 5%-"; }
          XF86AudioPlay allow-when-locked=true { spawn-sh "playerctl -p playerctld play"; }
          XF86AudioPause allow-when-locked=true { spawn-sh "playerctl -p playerctld pause"; }
          XF86AudioPrev allow-when-locked=true { spawn-sh "playerctl -p playerctld previous"; }
          XF86AudioNext allow-when-locked=true { spawn-sh "playerctl -p playerctld next"; }
          XF86AudioForward allow-when-locked=true { spawn-sh "playerctl -p playerctld position 10+"; }
          XF86AudioRewind allow-when-locked=true { spawn-sh "playerctl -p playerctld position 10-"; }
      }
    '';
  };
}

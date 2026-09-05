{
  config,
  lib,
  pkgs,
  ...
}: let
  zide = import ../../packages/zide.nix {inherit lib pkgs;};
  zideEnabled =
    (config.programs.nixvim.enable or false)
    && (config.programs.yazi.enable or false);
in {
  programs.zellij = {
    enable = true;

    # Starting Zellij is intentional: ordinary shells stay ordinary shells.
    enableBashIntegration = false;
    enableFishIntegration = false;
    enableZshIntegration = false;
    attachExistingSession = false;
    exitShellOnExit = false;

    settings = {
      default_layout = "compact";
      # Keep Neovim/Yazi keymaps authoritative until Zellij is explicitly
      # unlocked with Ctrl-g. This is Zellij's non-colliding preset model.
      default_mode = "locked";
      on_force_close = "detach";

      mouse_mode = true;
      focus_follows_mouse = false;
      mouse_click_through = false;
      advanced_mouse_actions = true;
      mouse_hover_effects = true;

      pane_frames = true;
      auto_layout = true;
      stacked_resize = true;
      scroll_buffer_size = 50000;

      copy_clipboard = "system";
      copy_on_select = true;
      osc8_hyperlinks = true;
      styled_underlines = true;
      support_kitty_keyboard_protocol = true;
      visual_bell = true;

      session_serialization = true;
      serialize_pane_viewport = false;
      serialization_interval = 60;
      mirror_session = false;

      show_startup_tips = false;
      show_release_notes = false;
      simplified_ui = false;

      web_server = false;
      web_sharing = "disabled";
    };

    extraConfig = ''
      keybinds {
          normal clear-defaults=true {
              bind "Ctrl g" "Esc" { SwitchToMode "Locked"; }
              bind "p" { SwitchToMode "Pane"; }
              bind "r" { SwitchToMode "Resize"; }
              bind "m" { SwitchToMode "Move"; }
              bind "t" { SwitchToMode "Tab"; }
              bind "s" { SwitchToMode "Scroll"; }
              bind "o" { SwitchToMode "Session"; }
          }
          locked {
              bind "Ctrl g" { SwitchToMode "Normal"; }
          }
          pane {
              bind "Left" { MoveFocus "Left"; }
              bind "Down" { MoveFocus "Down"; }
              bind "Up" { MoveFocus "Up"; }
              bind "Right" { MoveFocus "Right"; }
              bind "n" { NewPane; SwitchToMode "Locked"; }
              bind "d" { NewPane "Down"; SwitchToMode "Locked"; }
              bind "r" { NewPane "Right"; SwitchToMode "Locked"; }
              bind "s" { NewPane "stacked"; SwitchToMode "Locked"; }
              bind "x" { CloseFocus; SwitchToMode "Locked"; }
              bind "f" { ToggleFocusFullscreen; SwitchToMode "Locked"; }
              bind "w" { ToggleFloatingPanes; SwitchToMode "Locked"; }
              bind "e" { TogglePaneEmbedOrFloating; SwitchToMode "Locked"; }
              bind "Esc" "Enter" { SwitchToMode "Locked"; }
          }
          resize {
              bind "Left" { Resize "Increase Left"; }
              bind "Down" { Resize "Increase Down"; }
              bind "Up" { Resize "Increase Up"; }
              bind "Right" { Resize "Increase Right"; }
              bind "Esc" "Enter" { SwitchToMode "Locked"; }
          }
          move {
              bind "Left" { MovePane "Left"; }
              bind "Down" { MovePane "Down"; }
              bind "Up" { MovePane "Up"; }
              bind "Right" { MovePane "Right"; }
              bind "Esc" "Enter" { SwitchToMode "Locked"; }
          }
          tab {
              bind "Left" "Up" { GoToPreviousTab; }
              bind "Right" "Down" { GoToNextTab; }
              bind "n" { NewTab; SwitchToMode "Locked"; }
              bind "x" { CloseTab; SwitchToMode "Locked"; }
              bind "b" { BreakPane; SwitchToMode "Locked"; }
              bind "Esc" "Enter" { SwitchToMode "Locked"; }
          }
          scroll {
              bind "Down" { ScrollDown; }
              bind "Up" { ScrollUp; }
              bind "PageDown" "Right" { PageScrollDown; }
              bind "PageUp" "Left" { PageScrollUp; }
              bind "e" { EditScrollback; SwitchToMode "Locked"; }
              bind "Esc" { ScrollToBottom; SwitchToMode "Locked"; }
          }
          search {
              bind "Down" { ScrollDown; }
              bind "Up" { ScrollUp; }
              bind "PageDown" "Right" { PageScrollDown; }
              bind "PageUp" "Left" { PageScrollUp; }
              bind "Esc" { ScrollToBottom; SwitchToMode "Locked"; }
          }
          renametab {
              bind "Ctrl c" "Enter" { SwitchToMode "Locked"; }
              bind "Esc" { UndoRenameTab; SwitchToMode "Locked"; }
          }
          renamepane {
              bind "Ctrl c" "Enter" { SwitchToMode "Locked"; }
              bind "Esc" { UndoRenamePane; SwitchToMode "Locked"; }
          }
          session {
              bind "w" {
                  LaunchOrFocusPlugin "session-manager" {
                      floating true
                      move_to_focused_tab true
                  };
                  SwitchToMode "Locked"
              }
              bind "c" {
                  LaunchOrFocusPlugin "configuration" {
                      floating true
                      move_to_focused_tab true
                  };
                  SwitchToMode "Locked"
              }
              bind "Esc" "Enter" { SwitchToMode "Locked"; }
          }
      }

      ui {
          pane_frames {
              rounded_corners true
              hide_session_name false
          }
      }
    '';
  };

  home = lib.mkIf zideEnabled {
    packages = [zide];
    sessionVariables = {
      ZIDE_ALWAYS_NAME = "true";
      ZIDE_DEFAULT_LAYOUT = "default_lazygit";
      ZIDE_FILE_PICKER = "yazi";
      ZIDE_LAYOUT_DIR = "${zide}/share/zide/layouts";
      # Preserve the repo-owned Yazi plugins, openers, previews, and keymap.
      ZIDE_USE_YAZI_CONFIG = "false";
    };
  };
}

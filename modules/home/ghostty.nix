{
  lib,
  pkgs,
  osConfig,
  ...
}: let
  terminal = import ../../lib/terminal.nix {inherit lib pkgs;};
in {
  programs.zsh.initContent = lib.mkIf (pkgs.stdenv.hostPlatform.isLinux && (osConfig.programs.hyprland.enable or false)) (lib.mkOrder 150 ''
    # After Atuin's PTY proxy (100), before Zellij's blocking auto-start.
    # Prove the containing window with a nonce written to this shell's own tty.
    # Nested Zellij panes register their editors independently.
    if [[ "$TERM_PROGRAM" == ghostty && -z "$ZELLIJ" && -n "$HYPRLAND_INSTANCE_SIGNATURE" ]]; then
      ${lib.getExe (pkgs.callPackage ../../packages/smart-focus {})} register-terminal $$
    fi
  '');
  stylix.targets.ghostty.enable = true;

  home = {
    packages = [terminal.launcher];
    sessionVariables.TERMINAL = terminal.command;
  };

  systemd.user.targets.graphical-session = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    Unit.Wants = ["app-com.mitchellh.ghostty.service"];
  };

  programs.ghostty = {
    enable = true;
    inherit (terminal) package;
    settings = {
      # Hyprland owns tiling, groups, and new-window placement.
      window-show-tab-bar = "never";
      window-decoration = "none";
      confirm-close-surface = false;
      working-directory = "home";
      window-inherit-working-directory = true;

      # Stylix owns the palette, font, size, and background opacity.
      adjust-cell-height = "15%";
      adjust-cell-width = "2%";
      adjust-icon-height = "20%";
      cursor-style-blink = false;
      mouse-hide-while-typing = true;
      minimum-contrast = 3;
      # Keep explicit TUI backgrounds (selections, status bars) solid.
      background-opacity-cells = false;

      window-padding-x = 4;
      window-padding-y = 2;
      window-padding-balance = true;
      scrollbar = "never";
      quit-after-last-window-closed = false;
      copy-on-select = true;
      clipboard-read = "ask";
      clipboard-write = "allow";
      clipboard-paste-protection = true;
      clipboard-paste-bracketed-safe = true;
      shell-integration = "zsh";
      shell-integration-features = "cursor,sudo,title,ssh-env,ssh-terminfo,path";

      keybind = [
        "ctrl+shift+t=unbind"
        "ctrl+shift+o=unbind"
        "ctrl+shift+e=unbind"
        "ctrl+shift+enter=unbind"
        "ctrl+shift+f3=toggle_command_palette"
        "ctrl+alt+slash=toggle_command_palette"
        "ctrl+alt+w=close_window"
        "ctrl+alt+enter=new_window"
        "ctrl+shift+c=copy_to_clipboard"
        "ctrl+v=paste_from_clipboard"
        "ctrl+shift+v=paste_from_clipboard"
        "page_up=unbind"
        "page_down=unbind"
        "shift+page_up=scroll_page_up"
        "shift+page_down=scroll_page_down"
      ];
    };
  };
}

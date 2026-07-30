{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}: let
  cfg = config.modules.terminal;
  terminalEnabled = (osConfig.modules.desktop.enable or false) || pkgs.stdenv.isDarwin;
  launcher = pkgs.writeShellApplication {
    name = "ghostty-launch";
    runtimeInputs = [cfg.package];
    text =
      if pkgs.stdenv.isDarwin
      then ''
        exec /usr/bin/open -na Ghostty.app --args "$@"
      ''
      else ''
        exec ghostty +new-window "$@"
      '';
  };
in {
  options.modules.terminal = {
    package = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default =
        if pkgs.stdenv.isDarwin
        then pkgs.ghostty-bin
        else pkgs.ghostty;
      description = "Ghostty package for the current platform.";
    };

    command = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = lib.getExe launcher;
      description = "Command used by launchers to create a new Ghostty window.";
    };
  };

  config = lib.mkIf terminalEnabled {
    # This module owns Ghostty's font policy. Leaving Stylix's Ghostty target
    # enabled adds a second, fractional font size on Darwin.
    stylix.targets.ghostty.enable = false;

    home = {
      packages = [launcher];
      sessionVariables.TERMINAL = cfg.command;
    };

    # Ghostty's package-provided service starts without a terminal surface.
    # Keeping the process resident makes D-Bus `ghostty +new-window` launches
    # nearly instantaneous from Hyprland and other desktop launchers.
    systemd.user.targets.graphical-session.Unit.Wants = lib.optional (!pkgs.stdenv.isDarwin) "app-com.mitchellh.ghostty.service";

    programs.ghostty = {
      enable = true;
      inherit (cfg) package;
      settings = {
        # Hyprland owns tiling, groups, and new-window placement. Ghostty is
        # deliberately a single-surface terminal rather than a second layout
        # manager.
        window-show-tab-bar = "never";
        window-decoration = "none";
        confirm-close-surface = false;

        # Match the shared desktop font policy while keeping Nerd Font
        # glyphs comfortably sized. Clearing Stylix's terminal font avoids
        # retaining Iosevka as Ghostty's first-priority fallback.
        font-family = [
          ""
          "Mononoki Nerd Font"
          "Noto Emoji"
        ];
        font-size = 13;
        adjust-cell-height = "15%";
        adjust-cell-width = "2%";
        adjust-icon-height = "20%";
        cursor-style-blink = false;
        mouse-hide-while-typing = true;

        window-padding-x = 3;
        window-padding-y = 0;
        window-padding-balance = true;
        scrollbar = "never";
        quit-after-last-window-closed = false;

        # Keep terminal-to-clipboard interaction predictable and guard
        # multiline paste from accidental execution.
        copy-on-select = true;
        clipboard-read = "ask";
        clipboard-write = "allow";
        clipboard-paste-protection = true;
        clipboard-paste-bracketed-safe = true;

        # Make remote shells work without manually copying terminfo. The
        # integration keeps `xterm-ghostty` where supported and falls back
        # safely on hosts that do not accept it.
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
  };
}

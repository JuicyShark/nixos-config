{
  osConfig,
  config,
  pkgs,
  lib,
  inputs,
  system,
}: let
  inherit (osConfig.modules) desktop;
  hasBloat = desktop.bloat.enable or false;
  hasGaming = desktop.gaming.enable or false;
  hasZsa = osConfig.modules.system.keyboard.zsa or false;
  hasTmux = config.programs.tmux.enable or false;
  smartFocus =
    config.modules.terminalMultiplexers.smartFocus or {
      keys = {
        left = "left";
        right = "right";
        up = "up";
        down = "down";
      };
      tmux.mod = "CTRL";
      zellij.mod = "ALT";
    };

  hyprctl = "${osConfig.programs.hyprland.package}/bin/hyprctl";
  quickshell = lib.getExe pkgs.quickshell;
  uwsmAppPrefix = "${lib.getExe pkgs.uwsm} app --";
  uwsmApp = command: "${uwsmAppPrefix} ${command}";
  noctalia = lib.getExe inputs.noctalia.packages.${system}.default;
  screenshotPath = ''dir="''${XDG_SCREENSHOTS_DIR:-$HOME/media/pictures/screenshots}"; mkdir -p "$dir"; tmp="$(mktemp /tmp/screenshot-XXXXXX.png)"'';
  screenshotFinish = ''if [ -s "$tmp" ]; then ${uwsmApp "${lib.getExe pkgs.satty} --filename \"$tmp\" --output-filename \"$dir/screenshot-$(date +%Y%m%d-%H%M%S).png\" --copy-command \"${pkgs.wl-clipboard-rs}/bin/wl-copy\""}; fi; rm -f "$tmp"'';
  submapCheatsheetStart = ''
    if [ -f "$HOME/projects/submap-cheatsheet/config/shell.qml" ]; then
      ${quickshell} --path "$HOME/projects/submap-cheatsheet/config/shell.qml" --no-duplicate --daemonize
    elif [ -x "$HOME/projects/submap-cheatsheet/result/bin/submap-widget" ]; then
      "$HOME/projects/submap-cheatsheet/result/bin/submap-widget" --no-duplicate --daemonize
    fi
  '';
  submapCheatsheetCallScript = ''
    ${submapCheatsheetStart}
    sleep 0.15
    if [ -f "$HOME/projects/submap-cheatsheet/config/shell.qml" ]; then
      ${quickshell} --path "$HOME/projects/submap-cheatsheet/config/shell.qml" ipc call submapCheatsheet "$@"
    else
      ${quickshell} ipc --newest call submapCheatsheet "$@"
    fi
  '';
  submapCheatsheetCommand = pkgs.writeShellScript "submap-cheatsheet-start" submapCheatsheetStart;
  submapCheatsheetCallCommand = pkgs.writeShellScript "submap-cheatsheet-call" submapCheatsheetCallScript;
in {
  inherit uwsmAppPrefix;

  apps = {
    terminal = lib.getExe pkgs.kitty;
    nvim = lib.getExe pkgs.neovim;
    tmux = lib.getExe pkgs.tmux;
    zellij = lib.getExe pkgs.zellij;
    timeout = "${pkgs.coreutils}/bin/timeout";
    yazi = lib.getExe pkgs.yazi;
    emacsclient = lib.getExe' osConfig.modules.emacs.package "emacsclient";
    thunar = lib.getExe pkgs.thunar;
    elephant = lib.getExe' inputs.elephant.packages.${system}.default "elephant";
    walker = lib.getExe inputs.walker.packages.${system}.default;
    inherit noctalia;
    qutebrowser = lib.getExe pkgs.qutebrowser;
    vivaldi =
      if hasBloat
      then lib.getExe pkgs.vivaldi
      else null;
    pwvucontrol = lib.getExe pkgs.pwvucontrol;
    hyprpicker = lib.getExe pkgs.hyprpicker;
    wayscriber = lib.getExe pkgs.wayscriber;
    jellyfinMpvShim = lib.getExe pkgs.jellyfin-mpv-shim;
  };

  inherit hyprctl;
  scripts = {
    submapCheatsheet = toString submapCheatsheetCommand;
    submapCheatsheetCall = toString submapCheatsheetCallCommand;
  };

  screenshot = {
    fullscreen = "${noctalia} msg screenshot-fullscreen";
    region = "${noctalia} msg screenshot-region";
    window = ''sh -c '${screenshotPath}; win="$(${hyprctl} activewindow -j)"; x="$(printf "%s" "$win" | ${lib.getExe pkgs.jq} -r ".at[0]")"; y="$(printf "%s" "$win" | ${lib.getExe pkgs.jq} -r ".at[1]")"; w="$(printf "%s" "$win" | ${lib.getExe pkgs.jq} -r ".size[0]")"; h="$(printf "%s" "$win" | ${lib.getExe pkgs.jq} -r ".size[1]")"; ${lib.getExe pkgs.grim} -g "$x,$y ''${w}x$h" "$tmp"; ${screenshotFinish}' '';
  };

  sunshine = {
    enable = desktop.sunshine.enable or false;
    virtualMonitor = desktop.sunshine.streamingMonitor.output or "HDMI-A-1";
    virtualMode = desktop.sunshine.streamingMonitor.mode or "1920x1080@120";
    virtualPosition = desktop.sunshine.streamingMonitor.position or "0x1440";
    virtualScale = desktop.sunshine.streamingMonitor.scale or "1";
    steamWorkspace = desktop.sunshine.streamingMonitor.steamWorkspace or "21";
    gameWorkspace = desktop.sunshine.streamingMonitor.gameWorkspace or "22";
  };

  features = {
    gaming = hasGaming;
    bloat = hasBloat;
    zsa = hasZsa;
    emacs = osConfig.modules.emacs.enable or false;
    neovim = config.programs.nixvim.enable or false;
    tmux = hasTmux;
  };

  smartFocus = {
    inherit (smartFocus) keys;
    multiplexers = {
      tmux = {
        mod = smartFocus.tmux.mod;
      };
      zellij = {
        mod = smartFocus.zellij.mod;
      };
    };
  };
}

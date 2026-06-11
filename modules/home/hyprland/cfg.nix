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
  hasHaPresence = osConfig.modules.haPresence.enable or false;
  hasTmux = config.programs.tmux.enable or false;

  hyprctl = "${osConfig.programs.hyprland.package}/bin/hyprctl";
  quickshell = lib.getExe pkgs.quickshell;
  uwsmAppPrefix = "${lib.getExe pkgs.uwsm} app --";
  uwsmApp = command: "${uwsmAppPrefix} ${command}";
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
    yazi = lib.getExe pkgs.yazi;
    elephant = lib.getExe' inputs.elephant.packages.${system}.default "elephant";
    walker = lib.getExe inputs.walker.packages.${system}.default;
    noctalia = lib.getExe inputs.noctalia.packages.${system}.default;
    qutebrowser = lib.getExe pkgs.qutebrowser;
    vivaldi =
      if hasBloat
      then lib.getExe pkgs.vivaldi
      else null;
    hyprlock = lib.getExe pkgs.hyprlock;
    pwvucontrol = lib.getExe pkgs.pwvucontrol;
    hyprpicker = lib.getExe pkgs.hyprpicker;
    wayscriber = lib.getExe pkgs.wayscriber;
  };

  inherit hyprctl;
  scripts = {
    submapCheatsheet = toString submapCheatsheetCommand;
    submapCheatsheetCall = toString submapCheatsheetCallCommand;
  };

  screenshot = {
    fullscreen = ''sh -c '${screenshotPath}; ${lib.getExe pkgs.grim} "$tmp"; ${screenshotFinish}' '';
    region = ''sh -c '${screenshotPath}; ${lib.getExe pkgs.grim} -g "$(${lib.getExe pkgs.slurp})" "$tmp"; ${screenshotFinish}' '';
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
    haPresence = hasHaPresence;
    tmux = hasTmux;
  };
}

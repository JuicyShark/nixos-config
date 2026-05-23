{
  osConfig,
  config,
  pkgs,
  lib,
  inputs,
  system,
}: let
  inherit (config.lib.stylix) colors;

  inherit (osConfig.modules) desktop;
  inherit (desktop) primaryMonitor;
  terminal = lib.getExe pkgs.kitty;
  primaryDesc = primaryMonitor.desc or null;
  primaryOutput = primaryMonitor.output or "DP-1";
  primarySelector =
    if primaryDesc != null && primaryDesc != ""
    then "desc:${primaryDesc}"
    else primaryOutput;
  hasBloat = desktop.bloat.enable or false;

  hyprctl = "${osConfig.programs.hyprland.package}/bin/hyprctl";
  screenshotPath = ''dir="''${XDG_SCREENSHOTS_DIR:-$HOME/media/pictures/screenshots}"; mkdir -p "$dir"; tmp="$(mktemp /tmp/screenshot-XXXXXX.png)"'';
  screenshotFinish = ''if [ -s "$tmp" ]; then ${lib.getExe pkgs.satty} --filename "$tmp" --output-filename "$dir/screenshot-$(date +%Y%m%d-%H%M%S).png" --copy-command "${pkgs.wl-clipboard-rs}/bin/wl-copy"; fi; rm -f "$tmp"'';
  submapCheatsheetStart = ''
    if [ -d "$HOME/projects/submap-cheatsheet" ]; then
      nix run "$HOME/projects/submap-cheatsheet" -- --no-duplicate --daemonize
    elif [ -x "$HOME/projects/submap-cheatsheet/result/bin/submap-widget" ]; then
      "$HOME/projects/submap-cheatsheet/result/bin/submap-widget" --no-duplicate --daemonize
    fi
  '';
in {
  terminalCommands = {
    main = "${terminal} --title terminal";
    dropdown = "${terminal} --class dropdown --title dropdown";
    pinned = "${terminal} --class pinned --title pinned";
  };
  browser =
    if hasBloat
    then lib.getExe pkgs.vivaldi
    else lib.getExe pkgs.qutebrowser;
  privateBrowser =
    if hasBloat
    then "${lib.getExe pkgs.vivaldi} --incognito"
    else "${lib.getExe pkgs.qutebrowser} --target private-window";
  passManager = "${pkgs.bitwarden-desktop}/bin/bitwarden";
  locker = lib.getExe pkgs.hyprlock;
  volumeMixer = lib.getExe pkgs.pwvucontrol;
  inherit hyprctl;
  hyprpicker = lib.getExe pkgs.hyprpicker;
  noctalia = lib.getExe inputs.noctalia.packages.${system}.default;
  submapCheatsheet = ''bash -lc '${submapCheatsheetStart}' '';
  submapCheatsheetToggle = ''bash -lc '${submapCheatsheetStart}; sleep 0.6; ${hyprctl} dispatch global submap-cheatsheet:toggle-submap-options >/dev/null' '';

  screenshot = {
    fullscreen = ''sh -c '${screenshotPath}; ${lib.getExe pkgs.grim} "$tmp"; ${screenshotFinish}' '';
    region = ''sh -c '${screenshotPath}; ${lib.getExe pkgs.grim} -g "$(${lib.getExe pkgs.slurp})" "$tmp"; ${screenshotFinish}' '';
    window = ''sh -c '${screenshotPath}; win="$(${hyprctl} activewindow -j)"; x="$(printf "%s" "$win" | ${lib.getExe pkgs.jq} -r ".at[0]")"; y="$(printf "%s" "$win" | ${lib.getExe pkgs.jq} -r ".at[1]")"; w="$(printf "%s" "$win" | ${lib.getExe pkgs.jq} -r ".size[0]")"; h="$(printf "%s" "$win" | ${lib.getExe pkgs.jq} -r ".size[1]")"; ${lib.getExe pkgs.grim} -g "$x,$y ''${w}x$h" "$tmp"; ${screenshotFinish}' '';
  };

  primary = {
    output = primaryOutput;
    selector = primarySelector;
    wideColor = primaryMonitor.wideColor or false;
  };

  monitorWorkspace = {
    enable = true;
    target = "HDMI-A-2";
    workspaces = ["6" "7" "8" "9" "10"];
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

  flags = {
    gaming = desktop.gaming.enable or false;
    bloat = hasBloat;
    zsa = osConfig.modules.system.keyboard.zsa or false;
    emacs = osConfig.modules.emacs.enable or false;
    haPresence = osConfig.modules.haPresence.enable or false;
  };

  theme = {
    gaps_in = 12;
    gaps_out = 24;
    rounding = 25;
  };

  # Stylix base16 palette: only bases referenced by the generated Lua config.
  colors = {
    inherit (colors) base00 base01 base02 base04 base05 base07 base08 base09 base0A base0B base0C base0D base0E;
  };
}

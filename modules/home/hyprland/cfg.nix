{
  osConfig,
  config,
  pkgs,
  lib,
  inputs,
  system,
}: let
  inherit (osConfig.modules) desktop;
  hasApplications = desktop.applications.enable or false;
  hasVivaldi = hasApplications && (desktop.applications.vivaldi.enable or false);
  hasGaming = desktop.gaming.enable or false;
  hasAnnotation = desktop.annotation.enable or false;
  hasJellyfinMpvShim = desktop.media.jellyfinMpvShim.enable or false;
  hasZsa = osConfig.modules.system.keyboard.zsa or false;
  hasTmux = config.programs.tmux.enable or false;
  terminalBackend = config.modules.terminal.backend;
  smartFocus =
    config.modules.terminalMultiplexers.smartFocus or {
      keys = {
        left = "left";
        right = "right";
        up = "up";
        down = "down";
      };
      tmux.mod = "CTRL";
    };

  hyprctl = "${osConfig.programs.hyprland.package}/bin/hyprctl";
  quickshell = lib.getExe pkgs.quickshell;
  uwsmAppPrefix = "${lib.getExe pkgs.uwsm} app --";
  noctalia = lib.getExe inputs.noctalia.packages.${system}.default;
  submapCheatsheetStart = ''
    if [ -f "$HOME/projects/submap-cheatsheet/config/shell.qml" ]; then
      exec ${quickshell} --path "$HOME/projects/submap-cheatsheet/config/shell.qml" --no-duplicate
    elif [ -x "$HOME/projects/submap-cheatsheet/result/bin/submap-widget" ]; then
      exec "$HOME/projects/submap-cheatsheet/result/bin/submap-widget" --no-duplicate
    fi
  '';
  hyprlandStatePublishScript = ''
    state="''${1:?usage: hyprland-state-publish <state>}"
    if command -v ha-presence-update >/dev/null 2>&1; then
      ha-presence-update "$state"
    fi
  '';
  desktopPolicy = rec {
    mod = "SUPER";
    defaultProfile = "solo";
    primary = {
      output = "DP-2";
      selector = "DP-2";
      mode = "preferred";
      position = "0x0";
      scale = 1;
      wideColor = true;
    };
    auxiliary = {
      output = "HDMI-A-2";
      selector = "HDMI-A-2";
      mode = "preferred";
      position = "auto-center-right";
      scale = 1;
    };
    workspaceGroups = {
      external = [
        "6"
        "7"
        "8"
        "9"
        "10"
      ];
      auxiliary = [
        "6"
        "7"
        "8"
      ];
      stream = [
        "9"
        "10"
      ];
    };
    monitorWorkspace = {
      enable = true;
      target = "virtual-screen";
      workspaces = workspaceGroups.external;
    };
    monitors = [
      (builtins.removeAttrs primary ["selector" "wideColor"])
      (builtins.removeAttrs auxiliary ["selector"])
      {
        output = "HDMI-A-1";
        disabled = true;
      }
      {
        output = "iPad";
        mode = "2420x1668@60";
        position = "auto";
        scale = 2;
      }
    ];
  };
  generatedScripts = {
    submapCheatsheet = pkgs.writeShellScript "submap-cheatsheet-start" submapCheatsheetStart;
    hyprlandStatePublish = pkgs.writeShellScript "hyprland-state-publish" hyprlandStatePublishScript;
  };
in {
  inherit terminalBackend uwsmAppPrefix;
  desktop = desktopPolicy;

  apps = {
    terminal = lib.getExe config.modules.terminal.package;
    kitty = lib.getExe pkgs.kitty;
    jq = lib.getExe pkgs.jq;
    nvim = lib.getExe (
      if config.programs.nixvim.enable or false
      then config.programs.nixvim.build.package
      else pkgs.neovim
    );
    tmux = lib.getExe pkgs.tmux;
    playerctl = lib.getExe pkgs.playerctl;
    pkill = "${pkgs.procps}/bin/pkill";
    timeout = "${pkgs.coreutils}/bin/timeout";
    yazi = lib.getExe pkgs.yazi;
    emacsclient = lib.getExe' osConfig.modules.emacs.package "emacsclient";
    thunar = lib.getExe pkgs.thunar;
    inherit noctalia;
    browser = lib.getExe pkgs.chromium;
    qutebrowser = lib.getExe pkgs.qutebrowser;
    vivaldi =
      if hasVivaldi
      then lib.getExe pkgs.vivaldi
      else null;
    pwvucontrol = lib.getExe pkgs.pwvucontrol;
    hyprpicker = lib.getExe pkgs.hyprpicker;
    wayscriber =
      if hasAnnotation
      then lib.getExe pkgs.wayscriber
      else null;
    jellyfinMpvShim =
      if hasJellyfinMpvShim
      then lib.getExe pkgs.jellyfin-mpv-shim
      else null;
    steam =
      if hasGaming
      then lib.getExe pkgs.steam
      else null;
    discord =
      if hasApplications
      then lib.getExe pkgs.discord
      else null;
    music =
      if hasApplications
      then lib.getExe pkgs.tidal-hifi
      else null;
    keymapp =
      if hasZsa
      then lib.getExe' pkgs.keymapp "keymapp"
      else null;
  };

  inherit hyprctl;
  scripts = {
    submapCheatsheetStart = toString generatedScripts.submapCheatsheet;
    hyprlandStatePublish = toString generatedScripts.hyprlandStatePublish;
  };

  screenshot = {
    fullscreen = "${noctalia} msg screenshot-fullscreen";
    region = "${noctalia} msg screenshot-region";
  };

  sunshine = {
    enable = osConfig.services.sunshine.enable or false;
    stream = {
      monitor = desktopPolicy.monitorWorkspace.target;
      position = "0x1440";
      width = 2560;
      height = 1440;
      refresh = 120;
      scale = 1.67;
    };
  };

  features = {
    gaming = hasGaming;
    applications = hasApplications;
    annotation = hasAnnotation;
    jellyfinMpvShim = hasJellyfinMpvShim;
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
    };
  };
}

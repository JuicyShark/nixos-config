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
  hasGaming = desktop.gaming.enable or false;
  hasZsa = osConfig.hardware.keyboard.zsa.enable or false;
  terminal = (import ../../../lib/terminal.nix {inherit lib pkgs;}).command;
  firefox = lib.getExe config.programs.firefox.finalPackage;
  noctalia = lib.getExe inputs.noctalia.packages.${system}.default;
  uwsm = "${lib.getExe pkgs.uwsm} app --";
  app = command: "${uwsm} ${command}";
  terminalExec = command: app "${terminal} -e ${command}";
  terminalExecWithTitle = title: command: app "${terminal} --title=${title} -e ${command}";
  noctaliaMsg = command: "${noctalia} msg ${command}";
  zellij = lib.getExe config.programs.zellij.finalPackage;
  hyprctl = "${osConfig.programs.hyprland.package}/bin/hyprctl";
  haCfg = osConfig.modules.haPresence or {};
  mqttPublisher =
    if haCfg.enable or false
    then
      lib.getExe (import ../../../lib/ha-mqtt-publisher.nix {
        inherit pkgs;
        host = haCfg.brokerHost;
        username = haCfg.username;
        passwordFile = osConfig.age.secrets.ha-mqtt-pass.path;
        port = haCfg.brokerPort;
      })
    else null;
  socialStartup = pkgs.writeShellApplication {
    name = "hypr-social-startup";
    text = ''
      ${app (lib.getExe pkgs.discord)} &

      for _ in {1..100}; do
        if ${lib.escapeShellArg hyprctl} -j clients | ${lib.escapeShellArg (lib.getExe pkgs.jq)} -e \
          'any(.[]; .class == "discord" and .initialTitle == "Discord" and .floating == false)' \
          >/dev/null 2>&1; then
          break
        fi
        ${pkgs.coreutils}/bin/sleep 0.1
      done

      ${app (lib.getExe pkgs.signal-desktop)} &
      ${app "${firefox} --new-window https://www.facebook.com/"} &
    '';
  };
  webStartup = pkgs.writeShellApplication {
    name = "hypr-web-startup";
    text = ''
      ${app firefox} &
      ${app "${firefox} --new-window https://www.youtube.com/"} &
    '';
  };
  couchMode =
    if hasGaming && config.modules.desktop.hyprland.primaryMonitor != "" && config.modules.desktop.hyprland.tvMonitor != ""
    then
      import ../couch-mode-package.nix {
        inherit pkgs hyprctl mqttPublisher;
        steam = lib.getExe osConfig.programs.steam.package;
        tvOutput = config.modules.desktop.hyprland.tvMonitor;
        topic = "homeassistant/couch/${osConfig.networking.hostName}/command";
      }
    else null;
in {
  commands = {
    # The Linux launcher calls `ghostty +new-window` through D-Bus, avoiding
    # a full GTK startup for every Hyprland launch.
    terminal = app terminal;
    browser = app firefox;
    privateBrowser = app "${firefox} --private-window";
    qutebrowser = lib.optionalString (config.programs.qutebrowser.enable or false) (app (lib.getExe config.programs.qutebrowser.package));
    yazi = terminalExecWithTitle "yazi" (lib.getExe pkgs.yazi);
    volumeMixer = app (lib.getExe pkgs.pwvucontrol);
    colorPicker = app "${lib.getExe pkgs.hyprpicker} -a";

    screenshotRegion = noctaliaMsg "screenshot-region";
    screenshotFullscreen = noctaliaMsg "screenshot-fullscreen";

    clearNotifications = noctaliaMsg "notification-clear-active";
    mediaToggle = noctaliaMsg "media toggle";
    mediaPrevious = noctaliaMsg "media previous";
    mediaNext = noctaliaMsg "media next";
    mediaSeekForward = "${lib.getExe pkgs.playerctl} -p playerctld position 10+";
    mediaSeekBackward = "${lib.getExe pkgs.playerctl} -p playerctld position 10-";
    volumeUp = noctaliaMsg "volume-up";
    volumeDown = noctaliaMsg "volume-down";
    volumeMute = noctaliaMsg "volume-mute";
    launcher = noctaliaMsg "panel-toggle launcher";
    clipboard = noctaliaMsg "launcher clipboard";
    dndToggle = noctaliaMsg "notification-dnd-toggle";
    lock = noctaliaMsg "session lock";
    logout = noctaliaMsg "session logout";
    reboot = noctaliaMsg "session reboot";
    shutdown = noctaliaMsg "session shutdown";

    zellijNewSession = terminalExec zellij;
    zellijAttachSession = terminalExec "${zellij} attach";

    steam = lib.optionalString hasGaming (app (lib.getExe osConfig.programs.steam.package));
    hdmiToggle = lib.optionalString (couchMode != null) (app "${lib.getExe couchMode} display-toggle");
    couchModeEnter = lib.optionalString (couchMode != null) (app "${lib.getExe couchMode} enter");
    couchModeExit = lib.optionalString (couchMode != null) (app "${lib.getExe couchMode} exit");
    discord = lib.optionalString hasApplications (app (lib.getExe pkgs.discord));
    social = lib.optionalString hasApplications (lib.getExe socialStartup);
    web = lib.getExe webStartup;
    music = lib.optionalString hasApplications (app (lib.getExe pkgs.tidal-hifi));
    keymapp = lib.optionalString hasZsa (app (lib.getExe' pkgs.keymapp "keymapp"));
  };

  inherit couchMode;
}

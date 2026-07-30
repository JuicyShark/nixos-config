{
  cfg,
  lib,
  pkgs,
}: let
  app = command: "${cfg.uwsmAppPrefix} ${command}";
  terminalExec = command: app "${cfg.apps.terminal} -e ${command}";
  terminalExecWithTitle = title: command: app "${cfg.apps.terminal} --title=${title} -e ${command}";
  noctaliaMsg = command: "${cfg.apps.noctalia} msg ${command}";
  emacs = command: app "${cfg.apps.emacsclient} ${command}";
  emacsEval = expr: emacs "-c --eval ${lib.escapeShellArg expr}";
in {
  commands = rec {
    # The Linux launcher calls `ghostty +new-window` through D-Bus, avoiding
    # a full GTK startup for every Hyprland launch.
    terminal = app cfg.apps.terminal;
    browser = app cfg.apps.browser;
    privateBrowser = app "${cfg.apps.browser} --incognito";
    qutebrowser = app cfg.apps.qutebrowser;
    thunar = app cfg.apps.thunar;
    yazi = terminalExecWithTitle "yazi" cfg.apps.yazi;
    volumeMixer = app cfg.apps.pwvucontrol;
    colorPicker = app "${cfg.apps.hyprpicker} -a";

    screenshotRegion = cfg.screenshot.region;
    screenshotFullscreen = cfg.screenshot.fullscreen;

    filesEmacs = emacsEval ''(if (fboundp 'my/open-file-manager) (my/open-file-manager "~") (dired "~"))'';
    emacsRaise = emacs "-r";
    emacsNewFrame = emacs "-c";
    emacsCwd = emacs "-r .";
    emacsCapture = emacsEval "(org-capture)";
    emacsToday = emacsEval "(org-roam-dailies-goto-today)";
    emacsAgenda = emacsEval ''(org-agenda nil "d")'';
    emacsProjects = emacsEval ''(org-agenda nil "p")'';
    emacsWeeklyReview = emacsEval ''(org-agenda nil "R")'';
    emacsRoamFind = emacsEval "(org-roam-node-find)";
    emacsRoamCapture = emacsEval "(org-roam-capture)";
    emacsRoamSearch = emacsEval "(consult-org-roam-search)";

    clearNotifications = noctaliaMsg "notification-clear-active";
    mediaToggle = noctaliaMsg "media toggle";
    mediaPrevious = noctaliaMsg "media previous";
    mediaNext = noctaliaMsg "media next";
    mediaSeekForward = "${cfg.apps.playerctl} -p playerctld position 10+";
    mediaSeekBackward = "${cfg.apps.playerctl} -p playerctld position 10-";
    volumeUp = noctaliaMsg "volume-up";
    volumeDown = noctaliaMsg "volume-down";
    volumeMute = noctaliaMsg "volume-mute";
    launcher = noctaliaMsg "panel-toggle launcher";
    clipboard = noctaliaMsg "launcher clipboard";
    annotationToggle =
      if cfg.features.annotation
      then "${cfg.apps.pkill} -SIGUSR1 wayscriber"
      else null;
    lock = noctaliaMsg "session lock";
    logout = noctaliaMsg "session logout";
    reboot = noctaliaMsg "session reboot";
    shutdown = noctaliaMsg "session shutdown";

    tmuxNewSession = "${cfg.apps.tmux} new-session";
    tmuxListSessions = "${cfg.apps.tmux} list-sessions";
    tmuxAttachSession = "${cfg.apps.tmux} attach-session";
    tmuxDetach = "${cfg.apps.tmux} detach-client";
    tmuxReload = "${cfg.apps.tmux} source-file \"$HOME/.tmux.conf\"";

    steam = lib.optionalString cfg.features.gaming (app cfg.apps.steam);
    discord = lib.optionalString cfg.features.applications (app cfg.apps.discord);
    music = lib.optionalString cfg.features.applications (app cfg.apps.music);
    keymapp = lib.optionalString cfg.features.zsa (app cfg.apps.keymapp);

    workspaceOne = toString (pkgs.writeShellScript "hypr-workspace-one" ''
      ${terminal} &
      ${lib.optionalString cfg.features.applications "${qutebrowser} &"}
    '');

    statePublish = cfg.scripts.hyprlandStatePublish;

    terminalBin = cfg.apps.terminal;
    inherit terminalExec;
    pgrepBin = cfg.apps.pgrep;
    readlinkBin = cfg.apps.readlink;
    nvimBin = cfg.apps.nvim;
    emacsclientBin = cfg.apps.emacsclient;
    timeoutBin = cfg.apps.timeout;
    tmuxBin = cfg.apps.tmux;
    hyprctlBin = cfg.hyprctl;
  };
}

{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}: let
  nvim = lib.getExe config.programs.nixvim.build.package;
  terminal = (import ../../lib/terminal.nix {inherit lib pkgs;}).command;
  launcher = lib.getExe pkgs.fuzzel;
  uwsm = lib.getExe pkgs.uwsm;
  workspaceBinds = builtins.concatLists (map (workspace: let
      key =
        if workspace == 10
        then "0"
        else toString workspace;
      target = toString workspace;
    in [
      "SUPER, ${key}, workspace, ${target}"
      "SUPER SHIFT, ${key}, movetoworkspacesilent, ${target}"
    ])
    (lib.range 1 10));
in {
  home.packages = [pkgs.fuzzel];

  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-medium.yaml";
    polarity = "dark";
    # The ISO shares the system package set with Home Manager, so per-user
    # package overlays cannot take effect and only trigger an HM warning.
    overlays.enable = false;
    targets.hyprland.enable = false;
  };

  services = {
    hyprpolkitagent.enable = true;
    udiskie = {
      enable = true;
      automount = false;
      tray = "never";
    };
  };

  xdg.configFile."fuzzel/fuzzel.ini".text = ''
    [main]
    terminal=${terminal}
    width=50
    lines=12
    horizontal-pad=20
    vertical-pad=12
  '';

  wayland.windowManager.hyprland = {
    enable = true;
    inherit (osConfig.programs.hyprland) package portalPackage;
    configType = "hyprlang";
    systemd.enable = false;
    settings = {
      monitor = [", preferred, auto, 1"];
      exec-once = [terminal];
      input = {
        kb_layout = "us";
        accel_profile = "flat";
        follow_mouse = 1;
        repeat_delay = 300;
        repeat_rate = 50;
      };
      general = {
        border_size = 2;
        gaps_in = 5;
        gaps_out = 10;
        layout = "dwindle";
        resize_on_border = true;
      };
      decoration = {
        blur.enabled = false;
        rounding = 6;
        shadow.enabled = false;
      };
      animations.enabled = false;
      misc = {
        disable_autoreload = true;
        disable_hyprland_logo = true;
        force_default_wallpaper = 0;
      };
      bind =
        [
          "SUPER, Return, exec, ${uwsm} app -- ${terminal}"
          "SUPER, A, exec, ${launcher}"
          "SUPER, E, exec, ${uwsm} app -- ${terminal} -e yazi"
          "SUPER, N, exec, ${uwsm} app -- ${terminal} -e ${nvim}"
          "SUPER, Q, killactive"
          "SUPER, F, fullscreen, 0"
          "SUPER, V, togglefloating"
          "SUPER SHIFT, E, exec, ${uwsm} stop"
          "SUPER, left, movefocus, l"
          "SUPER, right, movefocus, r"
          "SUPER, up, movefocus, u"
          "SUPER, down, movefocus, d"
          "SUPER SHIFT, left, movewindow, l"
          "SUPER SHIFT, right, movewindow, r"
          "SUPER SHIFT, up, movewindow, u"
          "SUPER SHIFT, down, movewindow, d"
          "SUPER, Page_Up, workspace, r-1"
          "SUPER, Page_Down, workspace, r+1"
        ]
        ++ workspaceBinds;
      bindm = [
        "SUPER, mouse:272, movewindow"
        "SUPER, mouse:273, resizewindow"
      ];
    };
  };
}

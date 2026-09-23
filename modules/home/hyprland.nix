{
  osConfig,
  config,
  pkgs,
  lib,
  inputs,
  system,
  ...
}: let
  hyprlandEnabled = osConfig.programs.hyprland.enable or false;
  cfg = config.modules.desktop.hyprland;
  hasApplications = osConfig.modules.desktop.applications.enable or false;
  submapCheatsheet = pkgs.callPackage ../../packages/submap-cheatsheet {};
  smartFocus = pkgs.callPackage ../../packages/smart-focus {};
  autostart = lib.optionals (hasApplications && cfg.autostartApplications) [commandLayer.commands.discord];
  inherit (osConfig.stylix) cursor;
  hyprSettings = import ./hyprland/settings.nix {
    inherit config osConfig lib;
  };
  commandLayer = import ./hyprland/commands.nix {
    inherit osConfig config pkgs lib inputs system;
  };
  ruleLayer = import ./hyprland/rules.nix {
    inherit osConfig config;
    inherit (commandLayer) commands;
    inherit lib;
  };
  bindLayer = import ./hyprland/binds.nix {
    inherit osConfig config;
    inherit (commandLayer) commands;
    inherit lib;
  };
  mergedHyprSettings =
    hyprSettings
    // {
      bind = bindLayer.settings.bind;
      layer_rule = ruleLayer.settings.layer_rule;
      on = lib.optional (autostart != []) {
        _args = [
          "hyprland.start"
          (lib.generators.mkLuaInline ''
            function()
              ${lib.concatMapStringsSep "\n" (command: "hl.exec_cmd(${lib.generators.toLua {} command})") autostart}
            end
          '')
        ];
      };
      window_rule =
        (hyprSettings.window_rule or [])
        ++ map (rule:
          if cfg.applicationPlacement
          then rule
          else builtins.removeAttrs rule ["workspace"])
        ruleLayer.settings.window_rule;
      workspace_rule = ruleLayer.settings.workspace_rule;
    };

  renderUwsmEnv = attrs:
    lib.concatStringsSep "\n" (lib.mapAttrsToList
      (name: value: "export ${name}=${lib.escapeShellArg (toString value)}")
      attrs)
    + "\n";
in {
  options.modules.desktop.hyprland = let
    option = type: default: description: lib.mkOption {inherit type default description;};
    inherit (lib) types;
  in {
    sizing = option (types.enum ["portable" "ultrawide"]) "portable" "Preferred application column sizes and desktop spacing.";
    keyboard = option (types.enum ["standard" "moonlander"]) "standard" "Shortcut ergonomics, independent of keyboard firmware tooling.";
    primaryMonitor = option types.str "" "Preferred workspace and overlay output; empty follows compositor placement.";
    tvMonitor = option types.str "" "Optional TV output for explicit display profile shortcuts.";
    monitors = option (types.listOf types.attrs) [] "Additional Hyprland monitor declarations; hardware defaults may come from the host.";
    autostartApplications = option types.bool false "Start browser/social applications automatically.";
    applicationPlacement = option types.bool false "Send applications to the shared designated workspaces.";
  };

  config = lib.mkIf (pkgs.stdenv.hostPlatform.isLinux && hyprlandEnabled) {
    home.packages = [submapCheatsheet smartFocus] ++ lib.optional (commandLayer.couchMode != null) commandLayer.couchMode;

    systemd.user.services.smart-focus = {
      Unit = {
        Description = "Application pane focus broker";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "${lib.getExe smartFocus} serve";
        Restart = "on-failure";
        RestartSec = 1;
        UMask = "0077";
      };
      Install.WantedBy = ["graphical-session.target"];
    };

    systemd.user.services.submap-cheatsheet = {
      Unit = {
        Description = "Hyprland submap cheatsheet";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "${lib.getExe submapCheatsheet} --no-duplicate";
        Environment = ["SUBMAP_CHEATSHEET_MONITOR=${cfg.primaryMonitor}"];
        Restart = "on-failure";
      };
      Install.WantedBy = ["graphical-session.target"];
    };

    services = {
      udiskie = {
        enable = true;
        tray = "never";
      };
      hyprpaper.enable = lib.mkForce false;
    };

    stylix.targets.hyprland = {
      enable = false;
      hyprpaper.enable = false;
    };

    xdg.configFile = {
      "uwsm/env".text = renderUwsmEnv {
        GDK_BACKEND = "wayland,x11";
        MOZ_ENABLE_WAYLAND = "1";
        NIXOS_OZONE_WL = "1";
        QT_QPA_PLATFORM = "wayland;xcb";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        SDL_VIDEODRIVER = "wayland,x11";
        XDG_SCREENSHOTS_DIR = "${config.home.homeDirectory}/pictures/screenshots";
        XCURSOR_THEME = cursor.name;
        XCURSOR_SIZE = cursor.size;
        _JAVA_AWT_WM_NONREPARENTING = "1";
      };

      "uwsm/env-hyprland".text = renderUwsmEnv {
        AQ_TRIPLE_BUFFER = "1";
        HYPRCURSOR_THEME = cursor.name;
        HYPRCURSOR_SIZE = cursor.size;
      };

      "submap-cheatsheet/palette.json".text = let
        c = config.lib.stylix.colors;
      in
        builtins.toJSON {
          panel = "#B3${c.base00}";
          surface = "#${c.base01}";
          border = "#${c.base03}";
          textPrimary = "#${c.base05}";
          textMuted = "#${c.base04}";
          textError = "#${c.base08}";
          keyText = "#${c.base0B}";
          submapAccent = "#${c.base0C}";
          escapeAccent = "#${c.base08}";
        };
    };

    wayland.windowManager.hyprland = {
      enable = true;
      inherit (osConfig.programs.hyprland) package;
      inherit (osConfig.programs.hyprland) portalPackage;
      systemd.enable = false; # UWSM manages the systemd session
      configType = "lua";
      settings = mergedHyprSettings;
      inherit (bindLayer) submaps;
      extraLuaFiles = import ./hyprland/lua.nix {
        inherit osConfig config pkgs lib;
        inherit (commandLayer) commands;
        settings = hyprSettings.config;
      };
    };
  };
}

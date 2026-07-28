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
  inherit (osConfig.stylix) cursor;
  luaCfg = import ./hyprland/cfg.nix {
    inherit osConfig config pkgs lib inputs system;
  };
  hyprSettings = import ./hyprland/settings.nix {
    cfg = luaCfg;
    inherit config;
  };
  commandLayer = import ./hyprland/commands.nix {
    cfg = luaCfg;
    inherit lib pkgs;
  };
  ruleLayer = import ./hyprland/rules.nix {
    cfg = luaCfg;
    inherit (commandLayer) commands;
    inherit lib;
  };
  bindLayer = import ./hyprland/binds.nix {
    cfg = luaCfg;
    inherit (commandLayer) commands;
    inherit lib;
  };
  mergedHyprSettings =
    hyprSettings
    // {
      bind = bindLayer.settings.bind;
      layer_rule = ruleLayer.settings.layer_rule;
      window_rule = (hyprSettings.window_rule or []) ++ ruleLayer.settings.window_rule;
      workspace_rule = ruleLayer.settings.workspace_rule;
    };

  renderUwsmEnv = attrs:
    lib.concatStringsSep "\n" (lib.mapAttrsToList
      (name: value: "export ${name}=${lib.escapeShellArg (toString value)}")
      attrs)
    + "\n";
in {
  config = lib.mkIf (pkgs.stdenv.isLinux && hyprlandEnabled) {
    home.packages =
      lib.optionals (osConfig.modules.desktop.annotation.enable or false) [pkgs.wayscriber];

    services = {
      hyprpolkitagent.enable = true;
      elephant.enable = true;

      udiskie = {
        enable = true;
        automount = true;
        notify = true;
        tray = "never";
      };
      hyprpaper.enable = lib.mkForce false;
    };

    programs.noctalia.systemd.enable = true;

    systemd.user.services =
      {
        submap-cheatsheet = {
          Unit = {
            Description = "Hyprland submap cheatsheet";
            After = ["graphical-session.target"];
            PartOf = ["graphical-session.target"];
          };
          Service = {
            ExecStart = luaCfg.scripts.submapCheatsheetStart;
            Restart = "on-failure";
          };
          Install.WantedBy = ["graphical-session.target"];
        };
      }
      // lib.optionalAttrs luaCfg.features.annotation {
        wayscriber = {
          Unit = {
            Description = "Wayland screen annotation daemon";
            After = ["graphical-session.target"];
            PartOf = ["graphical-session.target"];
          };
          Service = {
            ExecStart = "${luaCfg.apps.wayscriber} -d --no-tray";
            Environment = ["WAYSCRIBER_NO_DETACH=1"];
            Restart = "on-failure";
          };
          Install.WantedBy = ["graphical-session.target"];
        };
      }
      // lib.optionalAttrs luaCfg.features.jellyfinMpvShim {
        jellyfin-mpv-shim = {
          Unit = {
            Description = "Jellyfin MPV Shim";
            After = ["graphical-session.target"];
            PartOf = ["graphical-session.target"];
          };
          Service = {
            ExecStart = luaCfg.apps.jellyfinMpvShim;
            Restart = "on-failure";
          };
          Install.WantedBy = ["graphical-session.target"];
        };
      };

    stylix.targets.hyprland = {
      enable = false;
      hyprpaper.enable = false;
    };

    xdg.configFile = {
      "uwsm/env".text = renderUwsmEnv {
        GDK_BACKEND = "wayland,x11";
        LIBVA_DRIVER_NAME = "radeonsi";
        MOZ_ENABLE_WAYLAND = "1";
        NIXOS_OZONE_WL = "1";
        PROTON_ENABLE_WAYLAND = "1";
        QT_QPA_PLATFORM = "wayland;xcb";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        SDL_VIDEODRIVER = "wayland,x11";
        XDG_SCREENSHOTS_DIR = "${config.home.homeDirectory}/pictures/screenshots";
        XCURSOR_THEME = cursor.name;
        XCURSOR_SIZE = cursor.size;
        _JAVA_AWT_WM_NONREPARENTING = "1";
      };

      "uwsm/env-hyprland".text = renderUwsmEnv {
        XDG_CURRENT_DESKTOP = "Hyprland";
        XDG_SESSION_DESKTOP = "Hyprland";
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
        inherit lib;
        cfg = luaCfg;
        inherit (commandLayer) commands;
        settings = hyprSettings.config;
      };
    };
  };
}

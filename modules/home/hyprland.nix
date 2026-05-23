{
  osConfig,
  config,
  pkgs,
  lib,
  inputs,
  system,
  ...
}: let
  desktop = osConfig.modules.desktop.enable or false;
  inherit (osConfig.stylix) cursor;
  luaCfg = import ./hyprland/cfg.nix {
    inherit osConfig config pkgs lib inputs system;
  };

  renderUwsmEnv = attrs:
    lib.concatStringsSep "\n" (lib.mapAttrsToList
      (name: value: "export ${name}=${lib.escapeShellArg (toString value)}")
      attrs)
    + "\n";
in {
  config = lib.mkIf (pkgs.stdenv.isLinux && desktop) {
    home.packages = [
      pkgs.socat
      pkgs.wayscriber
    ];

    services = {
      hyprpolkitagent.enable = true;

      udiskie = {
        enable = true;
        automount = true;
        notify = true;
        tray = "never";
      };
      hyprpaper.enable = lib.mkForce false;
    };

    programs.hyprlock.enable = true;

    stylix.targets.hyprland = {
      enable = false;
      hyprpaper.enable = false;
    };

    xdg.configFile = {
      "uwsm/env".text = renderUwsmEnv {
        LIBVA_DRIVER_NAME = "radeonsi";
        XCURSOR_THEME = cursor.name;
        XCURSOR_SIZE = cursor.size;
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
      extraConfig = import ./hyprland/lua.nix {
        inherit lib;
        cfg = luaCfg;
      };

      #     settings = lib.mkForce {};
      #extraConfig = lib.mkForce "";
    };
  };
}

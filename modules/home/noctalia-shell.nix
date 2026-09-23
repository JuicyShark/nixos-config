{
  config,
  osConfig,
  lib,
  inputs,
  pkgs,
  ...
}: let
  noctaliaPackage = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
  wallpaper = "${config.home.homeDirectory}/pictures/wallpaper/5120x2160-Monstera.png";
  paletteColors = config.lib.stylix.colors.withHashtag;
in {
  imports = [inputs.noctalia.homeModules.default];

  config = lib.optionalAttrs osConfig.programs.hyprland.enable {
    home.packages = with pkgs; [ddcutil bitwarden-cli];

    # Stylix owns every Noctalia hue: blue primary, teal hover, sage tertiary.
    stylix.targets.noctalia.enable = true;

    programs.noctalia = {
      enable = true;
      package = noctaliaPackage;
      systemd.enable = true;
      customPalettes.stylix.dark = {
        mPrimary = lib.mkForce paletteColors.base0D;
        mOnPrimary = lib.mkForce paletteColors.base00;
        mSecondary = lib.mkForce paletteColors.base0C;
        mOnSecondary = lib.mkForce paletteColors.base00;
        mTertiary = lib.mkForce paletteColors.base0B;
        mOnTertiary = lib.mkForce paletteColors.base00;
        mHover = lib.mkForce paletteColors.base0C;
        mOnHover = lib.mkForce paletteColors.base00;
      };

      # Keep this deliberately small. The pinned module validates the generated
      # TOML, so removed or renamed Noctalia settings fail during evaluation.
      settings = {
        shell = {
          lang = "en";
          panel_anchor_bar = "main";
          polkit_agent = true;
          screen_time_enabled = true;
          settings_show_advanced = false;
          telemetry_enabled = false;

          launcher = {
            compact = true;
            sort_by_usage = true;
          };

          panel = {
            launcher_placement = "floating";
            launcher_position = "center";
            open_near_click_control_center = true;
            transparency_mode = "glass";
          };

          screenshot.directory = "~/pictures/screenshots";
        };

        wallpaper = {
          enabled = true;
          directory = "${config.home.homeDirectory}/pictures/wallpaper";
          fill_color = "on_secondary";
          fill_mode = "center";
          transition = ["fade" "wipe" "disc" "stripes" "zoom" "honeycomb"];
          transition_duration = 1500;
          edge_smoothness = 0.05;
          transition_on_startup = true;

          default.path = lib.mkForce wallpaper;
          automation.enabled = false;
        };

        audio = {
          enable_overdrive = true;
          enable_sounds = true;
        };

        bar.main = {
          enabled = true;
          position = "left";
          layer = "top";
          reserve_space = true;
          thickness = 60;
          margin_edge = 0;
          margin_ends = 0;
          padding = 30;
          radius = 0;
          radius_top_left = 0;
          radius_top_right = 0;
          radius_bottom_left = 0;
          radius_bottom_right = 0;
          scale = 1.2;
          font_weight = 600;
          contact_shadow = true;
          panel_overlap = 0;
          start = ["workspaces" "launcher"];
          center = ["audio_visualizer"];
          end = [
            "tray"
            "notifications"
            "bluetooth"
            "volume"
            "brightness"
            "clock"
          ];

          monitor.primary = lib.mkIf (config.modules.desktop.hyprland.primaryMonitor != "") {
            match = config.modules.desktop.hyprland.primaryMonitor;
            enabled = true;
          };
        };

        brightness.enable_ddcutil = true;

        idle.behavior = {
          lock = {
            enabled = true;
            timeout = 600;
            action = "lock";
          };
          suspend = {
            enabled = true;
            timeout = 7200;
            action = "lock_and_suspend";
          };
        };

        lockscreen.enabled = true;

        location = {
          auto_locate = true;
        };

        weather = {
          enabled = true;
          effects = true;
          unit = "celsius";
        };

        nightlight = {
          enabled = true;
          temperature_day = 6500;
          temperature_night = 3500;
        };

        notification = {
          allowed_urgencies = ["normal" "critical"];
          layer = "overlay";
          monitors = lib.optional (config.modules.desktop.hyprland.primaryMonitor != "") config.modules.desktop.hyprland.primaryMonitor;
          offset_y = 16;
          position = "top_center";
        };

        osd = {
          background_opacity = lib.mkForce 0.85;
          position = "bottom_center";
          scale = 1.2;
          offset_y = 24;
        };

        dock.enabled = false;
        desktop_widgets.enabled = false;

        plugins = {
          enabled = [
            "noctalia/bitwarden"
            "juicy/steam-games"
            "raycursive/discord-voice"
            "pozzoo/hassio"
            "avivbintangaringga/nix-monitor"
          ];
          source = [
            {
              name = "official";
              kind = "git";
              location = "https://github.com/noctalia-dev/official-plugins";
            }
            {
              name = "community";
              kind = "git";
              location = "https://github.com/noctalia-dev/community-plugins";
            }
            {
              name = "juicy-local";
              kind = "path";
              location = toString ./noctalia-plugins;
            }
          ];
        };
      };
    };
  };
}

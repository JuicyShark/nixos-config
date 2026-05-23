{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.desktop;
  sunshinePorts = config.modules.ports.sunshine;
  streamCfg = cfg.sunshine.streamingMonitor;
  hyprctl = "${config.programs.hyprland.package}/bin/hyprctl";
  luaString = builtins.toJSON;
  enableStreamingMonitor = ''
    hl.monitor({
      output = ${luaString streamCfg.output},
      mode = ${luaString streamCfg.mode},
      position = ${luaString streamCfg.position},
      scale = tonumber(${luaString streamCfg.scale}),
    })
  '';
  disableStreamingMonitor = ''
    hl.monitor({
      output = ${luaString streamCfg.output},
      disabled = true,
    })
  '';
  setStreamingMonitor = pkgs.writeShellScript "sunshine-streaming-monitor" ''
    set -eu

    monitor=${lib.escapeShellArg streamCfg.output}
    steam_workspace=${lib.escapeShellArg streamCfg.steamWorkspace}
    game_workspace=${lib.escapeShellArg streamCfg.gameWorkspace}

    case "''${1:-}" in
      enable)
        ${hyprctl} eval ${lib.escapeShellArg enableStreamingMonitor}
        ${hyprctl} dispatch moveworkspacetomonitor "$steam_workspace" "$monitor"
        ${hyprctl} dispatch moveworkspacetomonitor "$game_workspace" "$monitor"
        ${hyprctl} dispatch workspace "$game_workspace"
        ;;
      disable)
        ${hyprctl} eval ${lib.escapeShellArg disableStreamingMonitor}
        ;;
      *)
        echo "usage: $0 enable|disable" >&2
        exit 64
        ;;
    esac
  '';
in {
  options.modules.desktop.sunshine = {
    enable = lib.mkEnableOption "Sunshine game streaming host";

    streamingMonitor = {
      output = lib.mkOption {
        type = lib.types.str;
        default = "HDMI-A-1";
        description = "Hyprland output name for the dummy-plug display used by Sunshine streams.";
      };
      mode = lib.mkOption {
        type = lib.types.str;
        default = "1920x1080@120";
        description = "Hyprland mode for the Sunshine dummy-plug display while streaming.";
      };
      position = lib.mkOption {
        type = lib.types.str;
        default = "0x1440";
        description = "Hyprland position for the Sunshine dummy-plug display while streaming.";
      };
      scale = lib.mkOption {
        type = lib.types.str;
        default = "1";
        description = "Hyprland scale for the Sunshine dummy-plug display while streaming.";
      };
      steamWorkspace = lib.mkOption {
        type = lib.types.str;
        default = "21";
        description = "Workspace used for Steam and Steam Big Picture while the Sunshine dummy-plug display is enabled.";
      };
      gameWorkspace = lib.mkOption {
        type = lib.types.str;
        default = "22";
        description = "Workspace used for games while the Sunshine dummy-plug display is enabled.";
      };
    };
  };

  config = lib.mkIf cfg.sunshine.enable {
    networking.firewall.allowedTCPPorts = with sunshinePorts; [
      https
      http
      web
      rtsp
    ];
    networking.firewall.allowedUDPPorts = with sunshinePorts; [
      discovery
      video
      control
      audio
      mic
      rtsp
    ];

    assertions = [
      {
        assertion = config.programs.steam.enable;
        message = "Sunshine requires programs.steam.enable == true.";
      }
    ];

    services = {
      sunshine = {
        enable = true;

        applications.env.PATH = "$PATH:$HOME/.local/bin";
        applications.apps = [
          {
            name = "Desktop";
            image-path = "desktop.png";
            prep-cmd = [
              {
                do = "${setStreamingMonitor} enable";
                undo = "${setStreamingMonitor} disable";
              }
            ];
            exclude-global-prep-cmd = "false";
            auto-detach = "true";
          }
        ];

        autoStart = true;
        capSysAdmin = true;
        openFirewall = false;
        settings = {
          port = config.modules.ports.sunshine.http;
          controller = "enabled";
          capture = "kms";
          encoder = "vaapi";
          adapter_name = "/dev/dri/renderD128";
          output_name = streamCfg.output;
          hevc_mode = 1;
          av1_mode = 1;
          gamepad = "xone";
          stream_audio = "disabled";
        };
      };

      udev.extraRules = ''
        KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
      '';
    };

    systemd.user.services.sunshine.environment.LIBVA_DRIVER_NAME = "radeonsi";
  };
}

{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = builtins.elem "desktop-sunshine" config.modules.system.roles;
  primaryMonitorName = config.modules.desktop.primaryMonitorName or "DP-1";
  primaryMonitorMode = config.modules.desktop.primaryMonitorMode or "5120x1440@120";
  virtualMonitorName = "Virtual";

  getHyprlandSignature = pkgs.writeShellScript "getHyprlandSignature" ''
    ${pkgs.findutils}/bin/find "$XDG_RUNTIME_DIR/hypr/" -maxdepth 1 -type d |
      ${pkgs.gnugrep}/bin/grep -v "^$XDG_RUNTIME_DIR/hypr/$" |
      ${pkgs.gawk}/bin/awk -F'/' 'NR==1 {print $NF; exit}'
  '';

  onConnect = pkgs.writeShellScript "onConnect" ''
    set -euo pipefail
    export PATH="${pkgs.hyprland}/bin:$PATH"
    HYPRLAND_INSTANCE_SIGNATURE=$(${getHyprlandSignature})
    export HYPRLAND_INSTANCE_SIGNATURE

    if ! hyprctl -j monitors | ${pkgs.gnugrep}/bin/grep -Eq '"name"[[:space:]]*:[[:space:]]*"Virtual"'; then
      hyprctl output create headless ${virtualMonitorName}
    fi

    hyprctl dispatch moveworkspacetomonitor 6 ${virtualMonitorName};
    hyprctl dispatch moveworkspacetomonitor 7 ${virtualMonitorName};
    hyprctl dispatch moveworkspacetomonitor 8 ${virtualMonitorName};
    hyprctl dispatch moveworkspacetomonitor 9 ${virtualMonitorName};
  '';

  moveMainWorkspacesToVirtual = pkgs.writeShellScript "moveMainWorkspacesToVirtual" ''
    set -euo pipefail
    export PATH="${pkgs.hyprland}/bin:$PATH"
    HYPRLAND_INSTANCE_SIGNATURE=$(${getHyprlandSignature})
    export HYPRLAND_INSTANCE_SIGNATURE

    for workspace in 1 2 3 4 5; do
      hyprctl dispatch moveworkspacetomonitor "$workspace" '${virtualMonitorName}'
    done
    hyprctl dispatch workspace 5
  '';

  moveMainWorkspacesToPrimary = pkgs.writeShellScript "moveMainWorkspacesToPrimary" ''
    set -euo pipefail
    export PATH="${pkgs.hyprland}/bin:$PATH"
    HYPRLAND_INSTANCE_SIGNATURE=$(${getHyprlandSignature})
    export HYPRLAND_INSTANCE_SIGNATURE

    for workspace in 1 2 3 4 5; do
      hyprctl dispatch moveworkspacetomonitor "$workspace" '${primaryMonitorName}'
    done
  '';

  onDisconnect = pkgs.writeShellScript "onDisconnect" ''
    set -euo pipefail
    export PATH="${pkgs.hyprland}/bin:$PATH"
    HYPRLAND_INSTANCE_SIGNATURE=$(${getHyprlandSignature})
    export HYPRLAND_INSTANCE_SIGNATURE

    hyprctl dispatch moveworkspacetomonitor '6' '${primaryMonitorName}'
    hyprctl dispatch moveworkspacetomonitor '7' '${primaryMonitorName}'
    hyprctl dispatch moveworkspacetomonitor '8' '${primaryMonitorName}'
    hyprctl dispatch moveworkspacetomonitor '9' '${primaryMonitorName}'

    if hyprctl -j monitors | ${pkgs.gnugrep}/bin/grep -Eq '"name"[[:space:]]*:[[:space:]]*"Virtual"'; then
      hyprctl output remove ${virtualMonitorName}
    fi
    hyprctl keyword monitor "${primaryMonitorName},${primaryMonitorMode},0x0,1"
    hyprctl keyword misc:vrr 1
  '';
in {
  config = lib.mkIf cfg {
    networking.firewall.allowedTCPPortRanges = [
      {
        from = 47984;
        to = 48010;
      }
    ];
    networking.firewall.allowedUDPPortRanges = [
      {
        from = 47998;
        to = 48010;
      }
    ];
    assertions = [
      {
        assertion = config.programs.steam.enable;
        message = "Sunshine requires programs.steam.enable == true.";
      }
    ];

    environment.systemPackages = with pkgs; [
      moonlight-qt
    ];

    hardware.xone.enable = true;

    services = {
      sunshine = {
        enable = true;
        applications = {
          env = {
            PATH = "$PATH:$HOME/.local/bin";
          };
          apps = lib.mkAfter [
            # Workspaces 6-9 now the clients, leave main monitor on
            {
              name = "Add Virtual Monitor";
              prep-cmd = [
                {
                  do = onConnect;
                  undo = onDisconnect;
                }
                {
                  do = "hyprctl dispatch focusmonitor '${virtualMonitorName}'";
                  undo = "hyprctl dispatch focusmonitor '${primaryMonitorName}'";
                }
              ];
              exclude-global-prep-cmd = "false";
            }
            # Move all workspace to Virtual Screen and disable monitor
            {
              name = "Virtual Monitor Only";
              prep-cmd = [
                {
                  do = onConnect;
                  undo = onDisconnect;
                }
                {
                  do = moveMainWorkspacesToVirtual;
                  undo = moveMainWorkspacesToPrimary;
                }
                {
                  do = "hyprctl keyword monitor '${primaryMonitorName},disable'";
                  undo = "hyprctl keyword monitor '${primaryMonitorName},${primaryMonitorMode},0x0,1'";
                }
              ];
              exclude-global-prep-cmd = "false";
            }
          ];
        };

        autoStart = true;
        capSysAdmin = true;
        openFirewall = true;
        settings = {
          port = 47989;
          controller = "enabled";
          gamepad = "xone";
          stream_audio = "disabled";
        };
      };

      udev.extraRules = ''
        ## Controller support for Sunshine.
        KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
      '';
    };
  };
}

# Hack The Box VPN integration: systemd service, toggle script, polkit rule.
{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.modules.htb;
  inherit (config.modules.system) username;

  htbVpnToggle = pkgs.writeShellApplication {
    name = "htb-vpn-toggle";
    runtimeInputs = [
      pkgs.iproute2
      pkgs.libnotify
      pkgs.systemd
      pkgs.gnugrep
    ];
    text = ''
      SERVICE="htb-vpn.service"
      if systemctl is-active --quiet "$SERVICE"; then
        systemctl stop "$SERVICE"
        ${pkgs.libnotify}/bin/notify-send -u normal -i network-offline "HTB VPN" "Disconnected"
      else
        systemctl start "$SERVICE"
        # Wait briefly for tun interface
        for i in 1 2 3 4 5; do
          sleep 1
          if ip link show tun0 &>/dev/null 2>&1; then
            IP=$(ip -4 addr show tun0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
            ${pkgs.libnotify}/bin/notify-send -u normal -i network-vpn "HTB VPN" "Connected: $IP"
            exit 0
          fi
        done
        ${pkgs.libnotify}/bin/notify-send -u normal -i network-vpn "HTB VPN" "Connecting..."
      fi
    '';
  };

  htbVpnStatus = pkgs.writeShellApplication {
    name = "htb-vpn-status";
    runtimeInputs = [
      pkgs.iproute2
      pkgs.systemd
      pkgs.gnugrep
    ];
    text = ''
      if systemctl is-active --quiet htb-vpn.service && ip link show tun0 &>/dev/null 2>&1; then
        IP=$(ip -4 addr show tun0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
        echo "connected:$IP"
      else
        echo "disconnected"
      fi
    '';
  };
in {
  options.modules.htb.enable = lib.mkEnableOption "Hack The Box VPN and pentesting integration";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      htbVpnToggle
      htbVpnStatus
      pkgs.openvpn
    ];

    # OpenVPN service for HTB — not auto-started, toggled on demand
    systemd.services.htb-vpn = {
      description = "Hack The Box OpenVPN";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.openvpn}/bin/openvpn --config /home/${username}/htb/lab.ovpn";
        Restart = "on-failure";
        RestartSec = 5;
        # Security hardening
        ProtectHome = "read-only";
        ProtectSystem = "strict";
        ReadWritePaths = ["/run" "/dev/net"];
        DeviceAllow = ["/dev/net/tun rw"];
        CapabilityBoundingSet = ["CAP_NET_ADMIN" "CAP_NET_RAW" "CAP_NET_BIND_SERVICE"];
        AmbientCapabilities = ["CAP_NET_ADMIN" "CAP_NET_RAW" "CAP_NET_BIND_SERVICE"];
      };
    };

    # Allow the user to start/stop htb-vpn without sudo
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id === "org.freedesktop.systemd1.manage-units" &&
            (action.lookup("unit") === "htb-vpn.service") &&
            subject.user === "${username}") {
          return polkit.Result.YES;
        }
      });
    '';
  };
}

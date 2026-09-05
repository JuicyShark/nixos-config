{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.tether;
  btmgmt = lib.getExe' pkgs.bluez "btmgmt";
in {
  options.modules.tether = {
    enable = lib.mkEnableOption "Tether iPhone integration";

    interface = lib.mkOption {
      type = lib.types.str;
      default = "enp7s0";
      description = "Network interface used for Tether discovery and incoming connections.";
    };

    bluetoothAdapter = lib.mkOption {
      type = lib.types.str;
      default = "hci0";
      description = "Bluetooth adapter whose class Tether configures for iPhone MAP and PBAP support.";
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;
      settings.General.Experimental = true;
    };

    services.avahi = {
      enable = true;
      openFirewall = false;
      publish.enable = true;
      publish.userServices = true;
      allowInterfaces = lib.mkDefault [cfg.interface];
    };

    networking.firewall.interfaces.${cfg.interface} = {
      allowedTCPPorts = [5134];
      allowedUDPPorts = [5353];
    };

    systemd.services.tether-bluetooth-class = {
      description = "Set the Bluetooth class required by Tether";
      documentation = ["https://github.com/zackb/tether/blob/main/docs/BLUETOOTH.md"];
      wantedBy = ["bluetooth.service"];
      after = ["bluetooth.service"];
      partOf = ["bluetooth.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        for attempt in {1..10}; do
          ${btmgmt} --index ${lib.escapeShellArg cfg.bluetoothAdapter} class 4 8 >/dev/null 2>&1 || true
          if ${btmgmt} --index ${lib.escapeShellArg cfg.bluetoothAdapter} info 2>/dev/null \
            | ${lib.getExe pkgs.gnugrep} -q 'class 0x..0408'; then
            exit 0
          fi
          ${lib.getExe' pkgs.coreutils "sleep"} 1
        done
        exit 1
      '';
    };
  };
}

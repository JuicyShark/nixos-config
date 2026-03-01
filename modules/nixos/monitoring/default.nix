# Monitoring Stack
#
# Comprehensive monitoring setup with Prometheus, Grafana, Loki, and exporters.
# This module coordinates all monitoring-related services.
#
# Split from monolithic monitoring.nix (804 lines) for better maintainability.

{
  config,
  lib,
  ...
}:
with lib;
{
  imports = [
    ./prometheus.nix
    ./grafana.nix
    ./loki.nix
    ./alertmanager.nix
    ./exporters/media.nix
    ./exporters/system.nix
    ./exporters/network.nix
  ];

  options.modules.monitoring = {
    enable = mkEnableOption "monitoring stack";

    enableHomelab = mkOption {
      type = types.bool;
      default = false;
      description = "Enable homelab service monitoring";
    };

    enableHostMonitoring = mkOption {
      type = types.bool;
      default = false;
      description = "Enable host-level system monitoring";
    };

    enableNas = mkOption {
      type = types.bool;
      default = false;
      description = "Enable NAS-specific monitoring";
    };
  };

  config = mkIf config.modules.monitoring.enable {
    # Monitoring stack enabled
    # Individual services configured in submodules
  };
}

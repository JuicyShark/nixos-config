{
  lib,
  config,
  ...
}: {
  imports = [
    ./exporters.nix
    ./loki.nix
    ./grafana.nix
    ./prometheus.nix
    ./alertmanager.nix
  ];

  options.modules.monitoring = {
    enable = lib.mkEnableOption "monitoring stack (Prometheus, Alertmanager, Grafana, Loki, and Alloy)";
    alertEmail = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Address used as both sender and recipient for Alertmanager email notifications.";
    };
    host.enable = lib.mkEnableOption "host-level monitoring (node exporter + alloy log shipping)";
    nas.enable = lib.mkEnableOption "NAS disk monitoring (smartctl exporter)";
    writablePaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Critical backup or shared paths tested for write access by the host health collector.";
    };
    vpnGuard = {
      service = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Service whose process must remain inside the expected network namespace.";
      };
      namespace = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Expected network namespace for the guarded service.";
      };
    };
  };

  config.assertions = [
    {
      assertion = config.modules.monitoring.enable -> config.modules.monitoring.alertEmail != null;
      message = "modules.monitoring.enable requires modules.monitoring.alertEmail";
    }
    {
      assertion = config.modules.monitoring.nas.enable -> config.modules.monitoring.enable;
      message = "modules.monitoring.nas requires modules.monitoring to be enabled";
    }
    {
      assertion = (config.modules.monitoring.vpnGuard.service != "") == (config.modules.monitoring.vpnGuard.namespace != "");
      message = "modules.monitoring.vpnGuard requires both service and namespace";
    }
    {
      assertion = (config.modules.monitoring.writablePaths != [] || config.modules.monitoring.vpnGuard.service != "") -> config.modules.monitoring.host.enable;
      message = "modules.monitoring writablePaths and vpnGuard require host monitoring";
    }
  ];
}

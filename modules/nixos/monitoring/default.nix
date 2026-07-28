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
    host.enable = lib.mkEnableOption "host-level monitoring (node exporter + alloy log shipping)";
    nas.enable = lib.mkEnableOption "NAS disk monitoring (smartctl exporter)";
  };

  config.assertions = [
    {
      assertion = config.modules.monitoring.nas.enable -> config.modules.monitoring.enable;
      message = "modules.monitoring.nas requires modules.monitoring to be enabled";
    }
  ];
}

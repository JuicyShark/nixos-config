{
  lib,
  config,
  ...
}: let
  exporterPorts = config.modules.ports.exporters;
in {
  environment.etc."resolv.conf" = lib.mkIf config.services.unbound.enable {
    text = ''
      nameserver 192.168.1.99
      options timeout:2 attempts:2
    '';
  };

  services.prometheus.exporters.unbound = lib.mkIf config.services.unbound.enable {
    enable = true;
    port = exporterPorts.unbound;
    openFirewall = false;
  };
}

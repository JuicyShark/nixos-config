{
  lib,
  config,
  ...
}:
let
  networkCfg = config.modules.network;
in
{
  environment.etc."resolv.conf" = lib.mkIf config.services.unbound.enable {
    text = ''
      nameserver ${networkCfg.hosts.zues}
      options timeout:2 attempts:2
    '';
  };

  services.prometheus.exporters.unbound = lib.mkIf config.services.unbound.enable {
    enable = true;
    port = 9167;
    openFirewall = true;
  };
}

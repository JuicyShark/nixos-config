{
  nix-config,
  system,
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (nix-config.lib.${system}.roles) mkHasRole;
  hasRole = mkHasRole config;
  homelabFilebrowser = hasRole "homelab-filebrowser";
  filebrowserPort = 8095;
  filebrowserRoot = "/srv/chonk/family";
in
{
  config = lib.mkIf homelabFilebrowser {
    services.filebrowser = {
      enable = true;
      openFirewall = false;
      user = "media";
      group = "media";
      settings = {
        address = "127.0.0.1";
        port = filebrowserPort;
        root = filebrowserRoot;
        noauth = false;
      };
    };

    systemd.tmpfiles.rules = [
      "d ${filebrowserRoot} 0770 media media -"
      "d ${filebrowserRoot}/Shared 0770 media media -"
      "d ${filebrowserRoot}/Uploads 0770 media media -"
      "d ${filebrowserRoot}/Private 0770 media media -"
      "d ${filebrowserRoot}/Uploads/juicy 0770 media media -"
      "d ${filebrowserRoot}/Private/juicy 0770 media media -"
    ];

    systemd.services.filebrowser.serviceConfig.RequiresMountsFor = [ "/srv/chonk" ];
  };
}

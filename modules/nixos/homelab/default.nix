{lib, ...}: let
  inherit (lib) mkEnableOption mkDefault;
in {
  imports = [
    ./media.nix
    ./tidarr.nix
    ./jellystat.nix
    ./swiparr.nix
    ./vaultwarden.nix
    ./gatus.nix
    ./filebrowser.nix
    ./syncthing.nix
    ./atuin.nix
  ];

  options.modules.homelab = {
    jellyfin = {
      enable = mkEnableOption "Jellyfin media server";
    };
    media.enable = mkEnableOption "*arr media acquisition stack (sonarr, radarr, lidarr, prowlarr, jellyseerr)";
  };

  config = {
    services.nginx = {
      enable = mkDefault true;
      recommendedGzipSettings = mkDefault true;
      recommendedOptimisation = mkDefault true;
      recommendedProxySettings = mkDefault true;
    };
  };
}

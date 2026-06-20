# Port Configuration
#
# Centralizes all port definitions for services and exporters.
{lib, ...}: let
  mkPortOption = default: description:
    lib.mkOption {
      type = lib.types.port;
      inherit default description;
    };
in {
  options.modules.ports = {
    grafana = mkPortOption 3000 "Grafana dashboard";
    glance = mkPortOption 5678 "Glance dashboard";
    prometheus = mkPortOption 9090 "Prometheus server";
    alertmanager = mkPortOption 9093 "Prometheus Alertmanager";
    loki = mkPortOption 3100 "Loki log aggregation";
    alloy = mkPortOption 9080 "Grafana Alloy agent";
    jellyfin = mkPortOption 8096 "Jellyfin media server";
    jellyseerr = mkPortOption 5055 "Jellyseerr request management";
    prowlarr = mkPortOption 9696 "Prowlarr indexer manager";
    sonarr = mkPortOption 8989 "Sonarr TV show management";
    radarr = mkPortOption 7878 "Radarr movie management";
    lidarr = mkPortOption 8686 "Lidarr music management";
    bazarr = mkPortOption 6767 "Bazarr subtitle management";
    readarr = mkPortOption 8787 "Readarr book management";
    delugeWeb = mkPortOption 9050 "Deluge web interface";
    delugeDaemon = mkPortOption 58846 "Deluge daemon";
    delugeIncoming = mkPortOption 51413 "Deluge incoming torrent peer traffic";
    homeAssistant = mkPortOption 8123 "Home Assistant";
    mqtt = mkPortOption 1883 "MQTT broker (Mosquitto)";
    headscale = mkPortOption 8085 "Headscale coordination server";
    uptimeKuma = mkPortOption 3001 "Uptime Kuma status monitor";
    gatus = mkPortOption 8888 "Gatus status monitor";
    syncthing = mkPortOption 8384 "Syncthing web GUI";
    vaultwarden = mkPortOption 8521 "Vaultwarden password manager";
    vaultwardenWs = mkPortOption 3012 "Vaultwarden websocket";
    filebrowser = mkPortOption 8095 "File browser";
    dhcpServer = mkPortOption 67 "DHCP server (bootps)";
    dhcpClient = mkPortOption 68 "DHCP client (bootpc)";
    kdeConnect = mkPortOption 60344 "KDE Connect / Valent";
    localsend = mkPortOption 53317 "LocalSend (cross-platform file share)";

    exporters = {
      node = mkPortOption 9100 "Node exporter";
      nginx = mkPortOption 9113 "Nginx exporter";
      blackbox = mkPortOption 9115 "Blackbox exporter";
      unbound = mkPortOption 9167 "Unbound DNS exporter";
      smartctl = mkPortOption 9633 "Smartctl disk health exporter";
      jellyfin = mkPortOption 9707 "Jellyfin exporter";
      prowlarr = mkPortOption 9710 "Prowlarr exporter";
      sonarr = mkPortOption 9712 "Sonarr exporter";
      radarr = mkPortOption 9711 "Radarr exporter";
      lidarr = mkPortOption 9709 "Lidarr exporter";
      bazarr = mkPortOption 9708 "Bazarr exporter";
      deluge = mkPortOption 9720 "Deluge exporter";
    };

    sunshine = {
      discovery = mkPortOption 5353 "Sunshine/Moonlight mDNS discovery port";
      https = mkPortOption 47984 "Sunshine HTTPS port";
      http = mkPortOption 47989 "Sunshine HTTP port";
      web = mkPortOption 47990 "Sunshine web UI port";
      rtsp = mkPortOption 48010 "Sunshine RTSP port";
      video = mkPortOption 47998 "Sunshine video stream port";
      control = mkPortOption 47999 "Sunshine control stream port";
      audio = mkPortOption 48000 "Sunshine audio stream port";
      mic = mkPortOption 48002 "Sunshine microphone stream port";
    };
  };
}

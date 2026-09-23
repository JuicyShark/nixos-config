{
  ports,
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.homelab.tidarr;
  stateDir = "/var/lib/tidarr";
  musicDir = "/mnt/chonk/media/music";
  lidarrDownloadsDir = "/mnt/chonk/torrent/tidarr";
  lidarrAddress = config.vpnNamespaces.wg.namespaceAddress;
  tidarrAddress = config.vpnNamespaces.wg.bridgeAddress;
  tidarrUrl = "http://${tidarrAddress}:${toString ports.tidarr}";
  lidarrUrl = "http://${lidarrAddress}:${toString ports.lidarr}";
  setupLidarr = pkgs.writeShellApplication {
    name = "tidarr-setup-lidarr";
    runtimeInputs = with pkgs; [coreutils curl jq];
    text = ''
      set -euo pipefail

      lidarr_key="$(tr -d '\r\n' < ${config.age.secrets.lidarr-api.path})"
      auth_header="$(mktemp)"
      trap 'rm -f "$auth_header"' EXIT
      chmod 0600 "$auth_header"
      printf 'X-Api-Key: %s\n' "$lidarr_key" > "$auth_header"

      ready=false
      for _ in $(seq 1 60); do
        if test -s ${stateDir}/.tidarr-api-key \
          && curl --fail --silent --output /dev/null ${tidarrUrl}/ \
          && curl --fail --silent --output /dev/null \
            --header "@$auth_header" \
            ${lidarrUrl}/api/v1/system/status; then
          ready=true
          break
        fi
        sleep 2
      done
      if test "$ready" != true; then
        echo "Tidarr or Lidarr did not become ready" >&2
        exit 1
      fi

      tidarr_key="$(tr -d '\r\n' < ${stateDir}/.tidarr-api-key)"
      lidarr_get() {
        curl --fail --silent --show-error \
          --header "@$auth_header" \
          "${lidarrUrl}/api/v1/$1"
      }

      lidarr_write() {
        local method="$1"
        local endpoint="$2"
        local payload="$3"
        printf '%s' "$payload" | curl --fail --silent --show-error \
          --request "$method" \
          --header "@$auth_header" \
          --header "Content-Type: application/json" \
          --data-binary @- \
          "${lidarrUrl}/api/v1/$endpoint"
      }

      download_client_id="$(lidarr_get downloadclient | jq -r '.[] | select(.name == "Tidarr") | .id' | head -n1)"
      download_client="$(
        lidarr_get downloadclient/schema | jq \
          --arg apiKey "$tidarr_key" \
          --arg host "${tidarrAddress}" \
          --argjson port ${toString ports.tidarr} '
            .[] | select(.implementation == "Sabnzbd")
            | .enable = true
            | .name = "Tidarr"
            | .removeCompletedDownloads = true
            | .removeFailedDownloads = true
            | .fields |= map(
                if .name == "host" then .value = $host
                elif .name == "port" then .value = $port
                elif .name == "useSsl" then .value = false
                elif .name == "urlBase" then .value = "/api/sabnzbd"
                elif .name == "apiKey" then .value = $apiKey
                elif .name == "musicCategory" then .value = "music"
                else . end
              )
          '
      )"
      if test -n "$download_client_id"; then
        download_client="$(jq --argjson id "$download_client_id" '.id = $id' <<<"$download_client")"
        lidarr_write PUT "downloadclient/$download_client_id" "$download_client" >/dev/null
      else
        download_client_id="$(lidarr_write POST downloadclient "$download_client" | jq -r .id)"
      fi

      indexer_id="$(lidarr_get indexer | jq -r '.[] | select(.name == "Tidarr") | .id' | head -n1)"
      indexer="$(
        lidarr_get indexer/schema | jq \
          --arg apiKey "$tidarr_key" \
          --arg baseUrl "${tidarrUrl}" \
          --argjson downloadClientId "$download_client_id" '
            .[] | select(.implementation == "Newznab" and .name == "")
            | .enableRss = false
            | .enableAutomaticSearch = true
            | .enableInteractiveSearch = true
            | .downloadClientId = $downloadClientId
            | .name = "Tidarr"
            | .fields |= map(
                if .name == "baseUrl" then .value = $baseUrl
                elif .name == "apiPath" then .value = "/api/lidarr"
                elif .name == "apiKey" then .value = $apiKey
                elif .name == "categories" then .value = [3000, 3010, 3040]
                else . end
              )
          '
      )"
      if test -n "$indexer_id"; then
        indexer="$(jq --argjson id "$indexer_id" '.id = $id' <<<"$indexer")"
        lidarr_write PUT "indexer/$indexer_id" "$indexer" >/dev/null
      else
        lidarr_write POST indexer "$indexer" >/dev/null
      fi

      mapping_id="$(lidarr_get remotepathmapping | jq -r \
        --arg host "${tidarrAddress}" \
        '.[] | select(.host == $host and (.remotePath | rtrimstr("/")) == "/shared/nzb_downloads") | .id' | head -n1)"
      mapping="$(jq -n \
        --arg host "${tidarrAddress}" \
        --arg localPath "${lidarrDownloadsDir}/" \
        '{host: $host, remotePath: "/shared/nzb_downloads/", localPath: $localPath}')"
      if test -n "$mapping_id"; then
        mapping="$(jq --argjson id "$mapping_id" '.id = $id' <<<"$mapping")"
        lidarr_write PUT "remotepathmapping/$mapping_id" "$mapping" >/dev/null
      else
        lidarr_write POST remotepathmapping "$mapping" >/dev/null
      fi
    '';
  };
in {
  options.modules.homelab.tidarr.enable = mkEnableOption "Tidarr TIDAL playlist downloader";

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.modules.homelab.media.enable;
        message = "modules.homelab.tidarr requires modules.homelab.media for Lidarr and the wg namespace";
      }
    ];

    # Lidarr runs inside the wg namespace and must initiate SABnzbd API calls
    # back to Tidarr on the default namespace's bridge address. Keep this
    # exemption limited to that single host instead of opening LAN egress.
    vpnNamespaces.wg.allowedEgress = [tidarrAddress];
    networking.firewall.interfaces.wg-br.allowedTCPPorts = [ports.tidarr];

    virtualisation = {
      podman.enable = true;
      oci-containers = {
        backend = "podman";
        containers.tidarr = {
          image = "docker.io/cstaelen/tidarr@sha256:5d843dab8eee816ffeb6b794ce38ffe15bc72c5d164b913e522b88d35e1e9d48";
          pull = "missing";
          environment = {
            ENABLE_HISTORY = "true";
            PGID = "2000";
            PORT = toString ports.tidarr;
            PUID = "2000";
            SYNC_CRON_EXPRESSION = "0 3 * * *";
            TZ = "Australia/Brisbane";
            UMASK = "0002";
          };
          volumes = [
            "${stateDir}:/shared"
            "${musicDir}:/music"
            "${lidarrDownloadsDir}:/shared/nzb_downloads"
          ];
          ports = ["${tidarrAddress}:${toString ports.tidarr}:${toString ports.tidarr}"];
          extraOptions = [
            "--dns=1.1.1.1"
            "--dns=1.0.0.1"
            "--security-opt=no-new-privileges"
            "--memory=2g"
            "--cpus=2"
            "--pids-limit=512"
          ];
        };
      };
    };

    systemd = {
      services = {
        podman-tidarr = {
          after = ["wg.service"];
          bindsTo = ["wg.service"];
          unitConfig.RequiresMountsFor = [stateDir musicDir lidarrDownloadsDir];
        };
        tidarr-lidarr-setup = {
          description = "Configure Tidarr's Lidarr download integration";
          wantedBy = ["multi-user.target"];
          after = ["lidarr-downloadclients.service" "podman-tidarr.service"];
          requires = ["lidarr.service" "podman-tidarr.service"];
          restartTriggers = [config.systemd.services.wg.serviceConfig.ExecStart];
          unitConfig.RequiresMountsFor = [lidarrDownloadsDir];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = lib.getExe setupLidarr;
            RemainAfterExit = true;
          };
        };
      };
      tmpfiles.rules = [
        "d ${stateDir} 0770 media media -"
        "d ${musicDir} 0770 media media -"
        "d ${lidarrDownloadsDir} 0770 media media -"
      ];
    };

    services.nginx.virtualHosts."tidarr.home.arpa".locations."/" = {
      proxyPass = tidarrUrl;
      proxyWebsockets = true;
    };
  };
}

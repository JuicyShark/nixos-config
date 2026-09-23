{
  ports,
  lib,
  config,
  pkgs,
  self,
  homelabFeatures,
  ...
}: let
  inherit (lib) mkForce mkIf;
  cfg = config.modules.homelab;
  endpoints = self.lib.services.mkHomelabEndpoints {
    inherit config;
    features = homelabFeatures;
  };

  apiSecret = name: config.age.secrets.${name}.path;
  qbitConfigFile = "${config.services.qbittorrent.profileDir}/qBittorrent/config/qBittorrent.conf";
  prepareQbitPassword = pkgs.writeScript "qbittorrent-prepare-password" ''
    #!${pkgs.python3}/bin/python3
    import base64
    import hashlib
    import os
    from pathlib import Path
    import sys
    import tempfile

    password_file = Path(sys.argv[1])
    config_file = Path(sys.argv[2])
    password = password_file.read_bytes().rstrip(b"\r\n")
    if not password:
        raise SystemExit("qBittorrent password secret is empty")

    salt = os.urandom(16)
    digest = hashlib.pbkdf2_hmac("sha512", password, salt, 100_000)
    encoded = (
        "@ByteArray("
        + base64.b64encode(salt).decode("ascii")
        + ":"
        + base64.b64encode(digest).decode("ascii")
        + ")"
    )
    replacement = rf'WebUI\Password_PBKDF2="{encoded}"'

    original = config_file.read_text()
    lines = original.splitlines()
    for index, line in enumerate(lines):
        if line.startswith(r"WebUI\Password_PBKDF2="):
            lines[index] = replacement
            break
    else:
        raise SystemExit("qBittorrent WebUI password setting is missing")

    stat = config_file.stat()
    with tempfile.NamedTemporaryFile(
        mode="w",
        dir=config_file.parent,
        prefix=".qBittorrent.conf.",
        delete=False,
    ) as output:
        output.write("\n".join(lines) + "\n")
        temporary = Path(output.name)

    os.chmod(temporary, stat.st_mode)
    os.chown(temporary, stat.st_uid, stat.st_gid)
    os.replace(temporary, config_file)
  '';
  waitForWireguardEndpoint = pkgs.writeShellApplication {
    name = "wait-for-wireguard-endpoint";
    runtimeInputs = with pkgs; [coreutils gnugrep iputils];
    text = ''
      endpoint="$(grep -m1 -E '^[[:space:]]*Endpoint[[:space:]]*=' ${config.age.secrets."zues-wg".path})"
      endpoint="''${endpoint#*=}"
      endpoint="''${endpoint//[[:space:]]/}"
      if [[ "$endpoint" =~ ^\[?([^]]+)\]?:[0-9]+$ ]]; then
        endpoint_ip="''${BASH_REMATCH[1]}"
      else
        echo "Invalid WireGuard endpoint: $endpoint" >&2
        exit 1
      fi

      for attempt in $(seq 1 60); do
        if ping -c 1 -W 1 "$endpoint_ip" >/dev/null 2>&1; then
          exit 0
        fi
        echo "Waiting for WireGuard endpoint $endpoint_ip ($attempt/60)" >&2
        sleep 1
      done

      echo "WireGuard endpoint $endpoint_ip remained unreachable for two minutes" >&2
      exit 1
    '';
  };
  waitForWireguardDns = pkgs.writeShellApplication {
    name = "wait-for-wireguard-dns";
    runtimeInputs = with pkgs; [coreutils gawk iproute2 dnsutils];
    text = ''
      nameserver="$(awk '$1 == "nameserver" { print $2; exit }' /etc/netns/wg/resolv.conf)"
      for attempt in $(seq 1 30); do
        # Query the VPN resolver explicitly: neither host DNS nor nscd may
        # satisfy this check while the tunnel is broken.
        answer="$(ip netns exec wg dig +time=2 +tries=1 +short @"$nameserver" . SOA 2>/dev/null)" || answer=""
        if [[ -n "$answer" ]]; then
          echo "WireGuard tunnel DNS is ready"
          exit 0
        fi
        echo "Waiting for DNS through WireGuard ($attempt/30)" >&2
        sleep 2
      done
      echo "WireGuard tunnel DNS did not become ready; check the peer handshake and VPN credentials" >&2
      exit 1
    '';
  };

  username = config.modules.profile.username;
  arrBindAddress =
    if config.modules.homelab.media.enable
    then config.vpnNamespaces.wg.namespaceAddress
    else "127.0.0.1";

  # Shared Settings
  arrHostConfig = port: {
    inherit port username;
    bindAddress = arrBindAddress;
    password._secret = apiSecret "juicy-password";
    authenticationMethod = "forms";
    authenticationRequired = "disabledForLocalAddresses";
    analyticsEnabled = true;
  };

  # Shared Settings
  arrSettings = port: {
    server = {
      inherit port;
      bindaddress = arrBindAddress;
    };
    auth = {
      method = mkForce "Forms";
      required = mkForce "DisabledForLocalAddresses";
    };
    log.analyticsEnabled = true;
  };
in {
  config = {
    boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = mkIf config.modules.homelab.media.enable (
      mkForce 1
    );

    nixflix = mkIf config.modules.homelab.media.enable {
      enable = true;
      mediaDir = "/mnt/chonk/media";
      downloadsDir = "/mnt/chonk/torrent";
      stateDir = "/var/lib";
      mediaUsers = [username];
      serviceDependencies = ["mnt-chonk.mount"];
      nginx = {
        enable = true;
        domain = "home.arpa";
      };
      vpn = {
        enable = true;
        wgConfFile = config.age.secrets."zues-wg".path;
        accessibleFrom = ["192.168.1.0/24"];
      };
      torrentClients.qbittorrent = {
        enable = true;
        group = "media";
        downloadsDir = "/mnt/chonk/torrent";
        subdomain = "torrent";
        serverConfig = {
          LegalNotice.Accepted = true;
          Preferences = {
            NetworkInterface = "wg-br";
            WebUI = {
              Username = username;
              Password_PBKDF2 = "@ByteArray(8jdOijrb6SqrAuw5sM3WPg==:KBC5PSh+MrkB0ucA5IjlTTWKjx/JDz9HxoU81ycAU9jjLibqYc8CJAXiT6rh6MhFOvFEJVlSS1JzUex92C+60A==)";
            };
          };
        };

        vpn.enable = true;
      };
      postgres.enable = true;
      flaresolverr.enable = true;

      downloadarr = {
        qbittorrent = {
          enable = true;
          password._secret = apiSecret "qbit";
        };
      };
      sonarr = {
        enable = true;
        vpn.enable = true;
        group = "media";
        dataDir = "/var/lib/sonarr/";
        mediaDirs = [
          "/mnt/chonk/media/shows"
          #"/mnt/chonk/media/anime"
        ];
        config = {
          apiKey._secret = apiSecret "sonarr-api";
          hostConfig = arrHostConfig ports.sonarr;
        };
        settings = arrSettings ports.sonarr;
      };

      radarr = {
        enable = true;
        vpn.enable = true;
        group = "media";
        dataDir = "/var/lib/radarr/";
        config = {
          apiKey._secret = apiSecret "radarr-api";
          hostConfig = arrHostConfig ports.radarr;
        };
        settings = arrSettings ports.radarr;
      };

      lidarr = {
        enable = true;
        vpn.enable = true;
        group = "media";
        dataDir = "/var/lib/lidarr";
        config = {
          apiKey._secret = apiSecret "lidarr-api";
          hostConfig = arrHostConfig ports.lidarr;
        };
        settings = arrSettings ports.lidarr;
      };

      prowlarr = {
        enable = true;
        vpn.enable = true;
        group = "media";
        dataDir = "/var/lib/prowlarr";
        config = {
          apiKey._secret = apiSecret "prowlarr-api";
          hostConfig = arrHostConfig ports.prowlarr;
          indexers = [
            {
              name = "IPTorrents";
              enable = true;
              cookie._secret = apiSecret "pirates-cookie";
              userAgent._secret = apiSecret "pirates-agent";
              tags = ["flaresolverr"];
              freeLeechOnly = false;
              priority = 25;
            }
            {
              name = "IPTorrents (freeleech)";
              schemaName = "IPTorrents";
              enable = true;
              cookie._secret = apiSecret "pirates-cookie";
              userAgent._secret = apiSecret "pirates-agent";
              tags = ["flaresolverr"];
              freeLeechOnly = true;
              priority = 15;
            }

            {
              name = "Nyaa.si";
              enable = true;
              priority = 25;
            }
          ];
        };
        settings = arrSettings ports.prowlarr;
      };

      seerr = {
        enable = true;
        apiKey._secret = apiSecret "seerr-api";
        port = ports.jellyseerr;
        group = "media";
        dataDir = "/var/lib/seerr";

        sonarr = mkForce {};
        radarr = mkForce {};
        jellyfin = {
          adminUsername = username;
          adminPassword._secret = apiSecret "jellyfin-admin-password";
          hostname = "jellyfin.home.arpa";
          port = 80;
          externalHostname = "https://jellyfin.nixlab.au";
        };
      };
    };

    age.secrets = mkIf config.modules.homelab.media.enable {
      juicy-password.file = ../../../secrets/juicy-password.age;
      "zues-wg" = {
        file = ../../../secrets/zues-wg.age;
        owner = "root";
        group = "root";
        mode = "0400";
      };
      jellyfin-admin-password = {
        file = ../../../secrets/jellyfin-admin-password.age;
        group = "media";
        mode = "0440";
        path = "/run/media-secrets/jellyfin-admin-password";
        symlink = false;
      };
      seerr-api = {
        file = ../../../secrets/seerr-api.age;
        group = "media";
        mode = "0440";
        path = "/run/media-secrets/seerr-api";
        symlink = false;
      };
      sonarr-api = {
        file = ../../../secrets/sonarr-api.age;
        group = "media";
        mode = "0440";
        path = "/run/media-secrets/sonarr-api";
        symlink = false;
      };
      radarr-api = {
        file = ../../../secrets/radarr-api.age;
        group = "media";
        mode = "0440";
        path = "/run/media-secrets/radarr-api";
        symlink = false;
      };
      lidarr-api = {
        file = ../../../secrets/lidarr-api.age;
        group = "media";
        mode = "0440";
        path = "/run/media-secrets/lidarr-api";
        symlink = false;
      };
      prowlarr-api = {
        file = ../../../secrets/prowlarr-api.age;
        group = "media";
        mode = "0440";
        path = "/run/media-secrets/prowlarr-api";
        symlink = false;
      };
      pirates-cookie = {
        file = ../../../secrets/pirates-cookie.age;
        group = "media";
        mode = "0440";
        path = "/run/media-secrets/pirates-cookie";
        symlink = false;
      };
      pirates-agent = {
        file = ../../../secrets/pirates-agent.age;
        group = "media";
        mode = "0440";
        path = "/run/media-secrets/pirates-agent";
        symlink = false;
      };
      qbit = {
        file = ../../../secrets/qbit.age;
        group = "media";
        mode = "0440";
        path = "/run/media-secrets/qbit-pass";
        symlink = false;
      };
    };

    modules.system.media.enable = mkIf cfg.media.enable true;
    # nixflix's qBittorrent module forces the entire group to {}. Override at
    # that same level so it cannot discard the GID needed by NFS/containers.
    users.groups.media = mkIf cfg.media.enable (lib.mkOverride 10 {
      gid = 2000;
      members = config.nixflix.mediaUsers;
    });

    systemd.services = lib.mkMerge [
      (mkIf cfg.media.enable {
        qbittorrent.serviceConfig.ExecStartPre = lib.mkAfter [
          "+${prepareQbitPassword} ${apiSecret "qbit"} ${qbitConfigFile}"
        ];
      })

      (mkIf config.modules.homelab.media.enable {
        wg = {
          # The decrypted path stays constant when agenix rotates credentials.
          restartTriggers = [(builtins.hashFile "sha256" config.age.secrets."zues-wg".file)];
          serviceConfig = {
            ExecStartPre = lib.getExe waitForWireguardEndpoint;
            # After=wg.service now waits for usable tunnel DNS, not just links.
            ExecStartPost = lib.getExe waitForWireguardDns;
            TimeoutStartSec = "5min";
          };
        };
      })

      # BindsTo stops these services when the namespace goes away; PartOf
      # also brings them through a restart when wg is explicitly restarted.
      (mkIf cfg.media.enable (lib.genAttrs [
        "flaresolverr"
        "lidarr"
        "prowlarr"
        "qbittorrent"
        "radarr"
        "sonarr"
      ] (_: {partOf = ["wg.service"];})))

      (mkIf (cfg.media.enable && config.nixflix.flaresolverr.enable) {
        flaresolverr = {
          after = ["wg.service"];
          bindsTo = ["wg.service"];
          serviceConfig = {
            NetworkNamespacePath = "/run/netns/wg";
            BindReadOnlyPaths = "/etc/netns/wg/resolv.conf:/etc/resolv.conf:norbind";
          };
        };
      })
      (mkIf (cfg.media.enable && !config.nixflix.jellyfin.enable) {
        seerr-setup.enable = mkForce false;
        seerr-user-settings.enable = mkForce false;
        seerr-jellyfin.enable = mkForce false;
        seerr-libraries.enable = mkForce false;
        seerr-radarr.enable = mkForce false;
        seerr-sonarr.enable = mkForce false;
      })
    ];

    services = {
      transmission.enable = mkIf cfg.media.enable (mkForce false);

      nginx = {
        enable = mkIf config.modules.homelab.media.enable true;
        virtualHosts."jellyfin.home.arpa".locations."/" = mkIf cfg.jellyfin.enable {
          proxyPass = endpoints.services.jellyfin.upstream;
          proxyWebsockets = true;
        };
      };
    };
  };
}

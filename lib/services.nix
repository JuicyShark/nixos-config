{lib}: let
  ports = import ./ports.nix;
in {
  # Homelab service catalog.
  #
  # The attr name is the service name. Most generated names come directly from
  # that key: <name>.home.arpa, qutebrowser quickmark names, Gatus labels, and
  # Glance titles. Use `homeName` only when the LAN hostname intentionally
  # differs from the service key, such as jellyseerr -> seerr.
  mkHomelabEndpoints = {
    config ? null,
    features,
  }: let
    # Backend addresses. User-facing names belong in service entries below.
    hosts = {
      leo = "192.168.1.54";
      zues = "192.168.1.99";
      homeAssistant = "192.168.1.48";
    };

    internalDomain = "home.arpa";
    publicDomain = "nixlab.au";

    port = name: ports.${name};
    host = name: hosts.${name};

    # URL constructors. `home` is the zues-fronted LAN surface; `local` is for
    # zues-local backends; `remote` is for services hosted elsewhere.
    local = portName: "http://127.0.0.1:${toString (port portName)}";
    remote = hostName: portName: "http://${host hostName}:${toString (port portName)}";
    remoteHost = address: portName: "http://${address}:${toString (port portName)}";
    home = name: "http://${name}.${internalDomain}";
    public = domain: "https://${domain}";

    # Mac's reserved Wi-Fi address hosts the migrated Jellyfin library.
    jellyfinHost = "192.168.1.52";
    vaultwardenPublicDomain = "pass.${publicDomain}";
    sunshineStatusUrl = "http://${host "leo"}:${toString ports.sunshine.http}";
    sunshineAdminUrl = "https://leo.${internalDomain}:${toString ports.sunshine.web}";
    hassLanUrl = "http://hass.${internalDomain}:${toString ports.homeAssistant}";

    removeScheme = url: lib.removePrefix "https://" (lib.removePrefix "http://" url);
    urlHost = url:
      builtins.head (
        lib.splitString ":" (builtins.head (lib.splitString "/" (removeScheme url)))
      );
    isHomeArpaUrl = url: lib.hasSuffix ".${internalDomain}" (urlHost url);
    isPublicDomain = domain: domain == publicDomain || lib.hasSuffix ".${publicDomain}" domain;

    mkLocalApp = {
      portName,
      homeName ? portName,
      icon ? null,
      enabled ? true,
      backendUrl ? local portName,
      checkPath ? null,
      statusPath ? null,
      statusUrl ?
        if statusPath == null
        then backendUrl
        else "${backendUrl}${statusPath}",
      altStatusCodes ? null,
    }:
      {
        inherit enabled homeName;
        url = home homeName;
        checkUrl =
          if checkPath == null
          then home homeName
          else "${home homeName}${checkPath}";
        inherit statusUrl;
        upstream = backendUrl;
      }
      // lib.optionalAttrs (icon != null) {inherit icon;}
      // lib.optionalAttrs (altStatusCodes != null) {inherit altStatusCodes;};

    nixflixBackend = serviceName: portName:
      if config == null
      then local portName
      else let
        hostConfig = config.nixflix.${serviceName}.config.hostConfig or {};
        address = hostConfig.bindAddress or "127.0.0.1";
        servicePort = hostConfig.port or (port portName);
      in "http://${address}:${toString servicePort}";

    # Service facts. Keep entries boring: only write fields that differ from
    # the service key or from the local-app defaults.
    rawServices = {
      # zues-local apps with the standard home.arpa -> localhost shape.
      grafana = mkLocalApp {
        portName = "grafana";
        icon = "di:grafana";
        enabled = features.monitoring;
      };

      prometheus = mkLocalApp {
        portName = "prometheus";
        enabled = features.monitoring;
        checkPath = "/-/ready";
        statusPath = "/-/healthy";
      };

      alertmanager = mkLocalApp {
        portName = "alertmanager";
        icon = "si:prometheus";
        enabled = features.monitoring;
        checkPath = "/-/ready";
        statusPath = "/-/ready";
      };

      # Loki has no user-facing LAN endpoint; Grafana queries it over loopback
      # and Alloy writers use the explicitly firewalled ingestion port.
      loki = {
        enabled = features.monitoring;
        statusUrl = "${local "loki"}/ready";
      };

      atuin = mkLocalApp {
        portName = "atuin";
        enabled = features.atuin;
      };

      jellyseerr =
        mkLocalApp {
          portName = "jellyseerr";
          homeName = "seerr";
          icon = "di:jellyseerr";
          enabled = features.media;
        }
        // {
          public = {
            domain = "seerr.${publicDomain}";
            upstream = local "jellyseerr";
          };
        };

      swiparr = {
        enabled = features.swiparr;
        icon = "si:jellyfin";
        homeName = "swiparr";
        url = home "swiparr";
        checkUrl = "${local "swiparr"}/api/health";
        upstream = local "swiparr";
        statusUrl = "${local "swiparr"}/api/health";
        public = {
          domain = "swiparr.${publicDomain}";
          upstream = local "swiparr";
          checkUrl = "${public "swiparr.${publicDomain}"}/api/health";
          statusUrl = "${public "swiparr.${publicDomain}"}/api/health";
        };
      };

      sonarr = mkLocalApp {
        portName = "sonarr";
        icon = "di:sonarr";
        enabled = features.media;
        backendUrl = nixflixBackend "sonarr" "sonarr";
        statusUrl = home "sonarr";
      };

      radarr = mkLocalApp {
        portName = "radarr";
        icon = "di:radarr";
        enabled = features.media;
        backendUrl = nixflixBackend "radarr" "radarr";
        statusUrl = home "radarr";
      };

      lidarr = mkLocalApp {
        portName = "lidarr";
        icon = "di:lidarr";
        enabled = features.media;
        backendUrl = nixflixBackend "lidarr" "lidarr";
        statusUrl = home "lidarr";
      };

      tidarr = mkLocalApp {
        portName = "tidarr";
        icon = "si:tidal";
        enabled = features.tidarr;
      };

      prowlarr = mkLocalApp {
        portName = "prowlarr";
        icon = "di:prowlarr";
        enabled = features.media;
        backendUrl = nixflixBackend "prowlarr" "prowlarr";
        statusUrl = home "prowlarr";
      };

      filebrowser = mkLocalApp {
        portName = "filebrowser";
        homeName = "files";
        icon = "di:filebrowser";
        enabled = features.filebrowser;
      };

      syncthing = mkLocalApp {
        portName = "syncthing";
        icon = "di:syncthing";
        enabled = features.syncthing;
      };

      # Manual entries: remote backends, public-only services, or nonstandard
      # health/status URLs.
      router.homeName = "router";

      glance = {
        url = home "zues";
        checkUrl = remote "leo" "glance";
        statusUrl = remote "leo" "glance";
        public = {
          domain = publicDomain;
          upstream = remote "leo" "glance";
          checkUrl = public publicDomain;
        };
      };

      jellyfin = {
        enabled = features.jellyfin;
        icon = "di:jellyfin";
        homeName = "jellyfin";
        url = home "jellyfin";
        checkUrl = "${home "jellyfin"}/web/index.html";
        upstream = remoteHost jellyfinHost "jellyfin";
        statusUrl = "${remoteHost jellyfinHost "jellyfin"}/health";
        public = {
          domain = "jellyfin.${publicDomain}";
          upstream = remoteHost jellyfinHost "jellyfin";
          checkUrl = "${public "jellyfin.${publicDomain}"}/web/index.html";
          statusUrl = "${public "jellyfin.${publicDomain}"}/health";
        };
      };

      jellystat = mkLocalApp {
        portName = "jellystat";
        icon = "si:jellyfin";
        enabled = features.jellystat;
        statusPath = "/auth/isConfigured";
      };

      torrent = {
        enabled = features.media;
        icon = "di:qbittorrent";
        homeName = "torrent";
        url = home "torrent";
        statusUrl = home "torrent";
        altStatusCodes = [401];
      };

      vaultwarden = {
        enabled = features.vaultwarden;
        icon = "di:vaultwarden";
        homeName = "vaultwarden";
        url = home "vaultwarden";
        checkUrl = home "vaultwarden";
        upstream = local "vaultwarden";
        statusUrl = "${local "vaultwarden"}/alive";
        public = {
          domain = vaultwardenPublicDomain;
          upstream = local "vaultwarden";
          checkUrl = public vaultwardenPublicDomain;
          statusUrl = public vaultwardenPublicDomain;
        };
      };

      sunshine = {
        icon = "di:sunshine";
        url = sunshineAdminUrl;
        checkUrl = sunshineStatusUrl;
        statusUrl = sunshineStatusUrl;
      };

      hass = {
        icon = "di:home-assistant";
        url = hassLanUrl;
        checkUrl = remote "homeAssistant" "homeAssistant";
        upstream = remote "homeAssistant" "homeAssistant";
        statusUrl = remote "homeAssistant" "homeAssistant";
        public = {
          domain = "hass.${publicDomain}";
          upstream = remote "homeAssistant" "homeAssistant";
        };
      };

      gatus = {
        enabled = features.gatus;
        icon = "di:gatus";
        homeName = "status";
        url = home "status";
        upstream = local "gatus";
        public = {
          domain = "status.${publicDomain}";
          upstream = local "gatus";
        };
      };

      nixlab.url = public publicDomain;
    };

    # Output order is grouped for human scanning and reused by quickmarks,
    # status checks, and dashboard lists.
    serviceGroups = {
      frontDoors = [
        "router"
        "glance"
      ];
      observability = [
        "grafana"
        "prometheus"
        "alertmanager"
        "loki"
      ];
      media = [
        "jellyfin"
        "jellystat"
        "swiparr"
        "jellyseerr"
        "sonarr"
        "radarr"
        "lidarr"
        "tidarr"
        "prowlarr"
        "torrent"
      ];
      personal = [
        "atuin"
        "vaultwarden"
        "filebrowser"
        "syncthing"
      ];
      remoteIntegrations = [
        "sunshine"
        "hass"
      ];
      statusAndLanding = [
        "gatus"
        "nixlab"
      ];
    };

    serviceOrder = lib.concatLists [
      serviceGroups.frontDoors
      serviceGroups.observability
      serviceGroups.media
      serviceGroups.personal
      serviceGroups.remoteIntegrations
      serviceGroups.statusAndLanding
    ];

    normalizeService = name: svc:
      {
        inherit name;
        title = name;
        enabled = svc.enabled or true;
      }
      // lib.optionalAttrs (svc ? icon) {inherit (svc) icon;}
      // lib.optionalAttrs (svc ? homeName) {inherit (svc) homeName;}
      // lib.optionalAttrs (svc ? url) {inherit (svc) url;}
      // lib.optionalAttrs (svc ? checkUrl) {inherit (svc) checkUrl;}
      // lib.optionalAttrs (svc ? upstream) {inherit (svc) upstream;}
      // lib.optionalAttrs (svc ? statusUrl) {inherit (svc) statusUrl;}
      // lib.optionalAttrs (svc ? altStatusCodes) {inherit (svc) altStatusCodes;}
      // lib.optionalAttrs (svc ? public) {inherit (svc) public;};

    services = lib.mapAttrs normalizeService rawServices;
    serviceList = map (name: services.${name}) serviceOrder;
    enabled = svc: svc.enabled or true;
    hasIcon = svc: svc ? icon;
    enabledServiceList = lib.filter enabled serviceList;
    publicServices =
      lib.filter (
        svc: (svc.public.domain or null) != null && (svc.public.ingress or true)
      )
      enabledServiceList;

    mkStatusPageEndpoint = svc: {
      name = svc.title;
      url = svc.statusUrl;
      interval = svc.statusInterval or "1m";
      conditions =
        (svc.statusConditions or ["[STATUS] == 200"])
        ++ ["[RESPONSE_TIME] < 5000"];
    };
    mkPublicStatusPageEndpoint = svc: let
      url = svc.public.statusUrl or (svc.public.checkUrl or (public svc.public.domain));
    in {
      name = "${svc.title} (public)";
      inherit url;
      interval = svc.public.statusInterval or "5m";
      conditions =
        (svc.public.statusConditions or ["[STATUS] == 200"])
        ++ ["[RESPONSE_TIME] < 10000"]
        ++ lib.optional (lib.hasPrefix "https://" url) "[CERTIFICATE_EXPIRATION] > 336h";
    };

    mkGlanceSite = svc:
      {
        inherit (svc) title url;
        check-url = svc.checkUrl or svc.url;
      }
      // lib.optionalAttrs (svc ? icon) {inherit (svc) icon;}
      // lib.optionalAttrs (svc ? altStatusCodes) {
        alt-status-codes = svc.altStatusCodes;
      };
    mkPublicGlanceSite = svc:
      {
        inherit (svc) title;
        url = svc.public.url or (public svc.public.domain);
        check-url = svc.public.checkUrl or (public svc.public.domain);
      }
      // lib.optionalAttrs (svc ? icon) {inherit (svc) icon;}
      // lib.optionalAttrs (svc.public ? icon) {icon = svc.public.icon;};
    hasLanGlanceUrl = svc: (svc ? url) && isHomeArpaUrl svc.url;
    hasPublicGlanceDomain = svc: (svc.public.domain or null) != null && isPublicDomain svc.public.domain;
  in {
    inherit services;

    # zues dnsmasq maps these enabled service names to <name>.home.arpa.
    # Host DNS entries live in hosts/zues/networking.nix.
    homeArpaServiceAliases = lib.unique (
      map (svc: svc.homeName) (lib.filter (svc: svc ? homeName) enabledServiceList)
    );

    # Cloudflared tunnel ingress for public hostnames owned by this catalog.
    publicTunnelIngress = lib.listToAttrs (
      map (
        svc:
          lib.nameValuePair svc.public.domain {
            service = svc.public.upstream;
          }
      )
      publicServices
    );

    # Every enabled service with a URL gets a quickmark named after its LAN
    # hostname when it has one, otherwise after the service key.
    qutebrowserQuickmarks = lib.listToAttrs (
      map (svc: lib.nameValuePair (svc.homeName or svc.name) svc.url) (
        lib.filter (svc: enabled svc && svc ? url) serviceList
      )
    );

    statusPageEndpoints =
      map mkStatusPageEndpoint (
        lib.filter (svc: enabled svc && hasIcon svc && svc ? statusUrl) serviceList
      )
      ++ map mkPublicStatusPageEndpoint (
        lib.filter (
          svc:
            enabled svc
            && hasIcon svc
            && (svc.public.statusUrl or (svc.public.checkUrl or (svc.public.domain or null))) != null
        )
        serviceList
      );

    # Glance is derived, not configured per service: every enabled LAN service
    # URL is a LAN site, and every enabled nixlab.au public hostname is public.
    glanceLanSites = map mkGlanceSite (lib.filter hasLanGlanceUrl enabledServiceList);
    glancePublicSites = map mkPublicGlanceSite (
      lib.filter hasPublicGlanceDomain publicServices
    );
  };
}

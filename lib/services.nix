{lib}: {
  mkHomelabEndpoints = {config}: let
    inherit (config.modules) ports;
    inherit (config.modules.network) hosts;

    port = name: ports.${name};
    host = name: hosts.${name};

    internalDomain = "home.arpa";
    publicDomain = "nixlab.au";
    hostFqdn = "${config.networking.hostName or "zues"}.${internalDomain}";

    local = portName: "http://127.0.0.1:${toString (port portName)}";
    localPath = portName: path: "${local portName}${path}";
    remote = hostName: portName: "http://${host hostName}:${toString (port portName)}";
    remotePath = hostName: portName: path: "${remote hostName portName}${path}";
    home = name: "http://${name}.${internalDomain}";
    homePath = name: path: "${home name}${path}";
    public = domain: "https://${domain}";
    publicPath = domain: path: "${public domain}${path}";

    immichDomain = config.modules.homelab.immich.domain or "photos.${internalDomain}";
    immichPublicDomain = config.modules.homelab.immich.publicDomain or "photos.${publicDomain}";
    paperlessDomain = config.modules.homelab.paperless.domain or "docs.${internalDomain}";
    vaultwardenPublicDomain = "pass.${publicDomain}";
    immichEnabled = config.services.immich.enable or (config.modules.homelab.immich.enable or false);
    paperlessEnabled = config.services.paperless.enable or (config.modules.homelab.paperless.enable or false);

    services = {
      router = {
        title = "Router";
        aliases = ["router"];
      };

      glance = {
        title = "Glance";
        url = home "zues";
        checkUrl = remote "leo" "glance";
        quickmarkName = "glance";
        gatus.url = remote "leo" "glance";
        public = {
          domain = publicDomain;
          upstream = remote "leo" "glance";
          checkUrl = public publicDomain;
          blackbox = true;
        };
      };

      grafana = {
        title = "Grafana";
        aliases = ["grafana"];
        icon = "di:grafana";
        url = home "grafana";
        checkUrl = home "grafana";
        upstream = local "grafana";
        quickmarkName = "grafana";
        gatus.url = local "grafana";
        blackbox = true;
        glance = "private";
      };

      prometheus = {
        title = "Prometheus";
        aliases = ["prometheus"];
        url = home "prometheus";
        checkUrl = homePath "prometheus" "/-/ready";
        upstream = local "prometheus";
        quickmarkName = "prometheus";
        gatus.url = localPath "prometheus" "/-/healthy";
        blackbox = true;
      };

      alertmanager = {
        title = "Alertmanager";
        aliases = ["alertmanager"];
        url = home "alertmanager";
        upstream = local "alertmanager";
        quickmarkName = "alertmanager";
        gatus.url = localPath "alertmanager" "/-/healthy";
      };

      loki = {
        title = "Loki";
        aliases = ["loki"];
        url = home "loki";
        checkUrl = homePath "loki" "/ready";
        upstream = local "loki";
        quickmarkName = "loki";
        gatus.url = localPath "loki" "/ready";
        blackbox = true;
      };

      jellyfin = {
        title = "Jellyfin";
        aliases = ["jellyfin"];
        icon = "di:jellyfin";
        url = home "jellyfin";
        checkUrl = homePath "jellyfin" "/web/index.html";
        upstream = remote "imac-machop" "jellyfin";
        quickmarkName = "jellyfin";
        gatus.url = remotePath "imac-machop" "jellyfin" "/health";
        blackbox = true;
        glance = "private";
        public = {
          domain = "jellyfin.${publicDomain}";
          upstream = remote "imac-machop" "jellyfin";
          checkUrl = publicPath "jellyfin.${publicDomain}" "/web/index.html";
          gatusUrl = publicPath "jellyfin.${publicDomain}" "/health";
          blackbox = true;
          gatus = true;
          glance = true;
        };
      };

      jellyseerr = {
        title = "Jellyseerr";
        aliases = ["seerr"];
        icon = "di:jellyseerr";
        url = home "seerr";
        upstream = local "jellyseerr";
        quickmarkName = "seerr";
        gatus.url = local "jellyseerr";
        glance = "private";
      };

      sonarr = {
        title = "Sonarr";
        aliases = ["sonarr"];
        icon = "di:sonarr";
        url = home "sonarr";
        upstream = local "sonarr";
        quickmarkName = "sonarr";
        gatus.url = local "sonarr";
        blackbox = true;
        glance = "private";
      };

      radarr = {
        title = "Radarr";
        aliases = ["radarr"];
        icon = "di:radarr";
        url = home "radarr";
        upstream = local "radarr";
        quickmarkName = "radarr";
        gatus.url = local "radarr";
        blackbox = true;
        glance = "private";
      };

      lidarr = {
        title = "Lidarr";
        aliases = ["lidarr"];
        icon = "di:lidarr";
        url = home "lidarr";
        upstream = local "lidarr";
        quickmarkName = "lidarr";
        gatus.url = local "lidarr";
        blackbox = true;
        glance = "private";
      };

      readarr = {
        title = "Readarr";
        aliases = ["readarr"];
        icon = "di:readarr";
        url = home "readarr";
        upstream = local "readarr";
        quickmarkName = "readarr";
        gatus.url = local "readarr";
        blackbox = true;
        glance = "private";
      };

      bazarr = {
        title = "Bazarr";
        aliases = ["bazarr"];
        icon = "di:bazarr";
        url = home "bazarr";
        upstream = local "bazarr";
        quickmarkName = "bazarr";
        gatus.url = local "bazarr";
        blackbox = true;
        glance = "private";
      };

      prowlarr = {
        title = "Prowlarr";
        aliases = ["prowlarr"];
        icon = "di:prowlarr";
        url = home "prowlarr";
        upstream = local "prowlarr";
        quickmarkName = "prowlarr";
        gatus.url = local "prowlarr";
        blackbox = true;
        glance = "private";
      };

      deluge = {
        title = "Deluge";
        aliases = ["deluge"];
        icon = "di:deluge";
        url = home "deluge";
        upstream = local "delugeWeb";
        quickmarkName = "deluge";
        gatus.url = local "delugeWeb";
        blackboxAuth = true;
        glance = "private";
        altStatusCodes = [401];
      };

      vaultwarden = {
        title = "Vaultwarden";
        aliases = ["vaultwarden"];
        icon = "di:vaultwarden";
        url = home "vaultwarden";
        checkUrl = home "vaultwarden";
        upstream = local "vaultwarden";
        quickmarkName = "vaultwarden";
        gatus.url = localPath "vaultwarden" "/alive";
        blackbox = true;
        public = {
          domain = vaultwardenPublicDomain;
          upstream = local "vaultwarden";
          checkUrl = public vaultwardenPublicDomain;
          blackbox = true;
          gatus = true;
          glance = true;
        };
      };

      filebrowser = {
        title = "Files";
        aliases = ["files"];
        icon = "di:filebrowser";
        url = home "files";
        upstream = local "filebrowser";
        quickmarkName = "files";
        gatus.url = local "filebrowser";
        blackbox = true;
        glance = "private";
      };

      headscale = {
        title = "Headscale";
        upstream = local "headscale";
        gatus.url = localPath "headscale" "/health";
        public = {
          domain = "ts.${publicDomain}";
          upstream = local "headscale";
          checkUrl = publicPath "ts.${publicDomain}" "/health";
          gatusUrl = publicPath "ts.${publicDomain}" "/health";
          gatus = true;
        };
      };

      immich = {
        title = "Immich";
        aliases = ["photos"];
        url = "http://${immichDomain}";
        checkUrl = "http://${immichDomain}/api/server/ping";
        upstream = local "immich";
        gatus.url = localPath "immich" "/api/server/ping";
        blackbox = immichEnabled;
        public = {
          domain = immichPublicDomain;
          upstream = local "immich";
          ingress = immichEnabled;
          checkUrl =
            if immichPublicDomain != null
            then publicPath immichPublicDomain "/api/server/ping"
            else null;
          gatusUrl =
            if immichPublicDomain != null
            then publicPath immichPublicDomain "/api/server/ping"
            else null;
          blackbox = immichEnabled;
          gatus = immichEnabled;
        };
      };

      miniflux = {
        title = "Miniflux";
        aliases = ["rss"];
        icon = "di:miniflux";
        url = home "rss";
        upstream = local "miniflux";
        quickmarkName = "rss";
        gatus.url = local "miniflux";
        glance = "private";
      };

      paperless = {
        title = "Paperless";
        aliases = ["docs"];
        url = "http://${paperlessDomain}";
        checkUrl = "http://${paperlessDomain}";
        upstream = local "paperless";
        gatus.url = local "paperless";
        blackbox = paperlessEnabled;
      };

      syncthing = {
        title = "Syncthing";
        aliases = ["syncthing"];
        icon = "di:syncthing";
        url = home "syncthing";
        upstream = local "syncthing";
        quickmarkName = "syncthing";
        gatus.url = local "syncthing";
        glance = "private";
      };

      homeAssistant = {
        title = "Home-Assist";
        aliases = ["hass"];
        icon = "di:home-assistant";
        url = remote "homeAssistant" "homeAssistant";
        checkUrl = remote "homeAssistant" "homeAssistant";
        upstream = remote "homeAssistant" "homeAssistant";
        quickmarkName = "hass";
        quickmarkUrl = home "hass";
        gatus.url = remote "homeAssistant" "homeAssistant";
        blackbox = true;
        glance = "private";
        public = {
          domain = "hass.${publicDomain}";
          upstream = remote "homeAssistant" "homeAssistant";
        };
      };

      gatus = {
        title = "Gatus";
        aliases = ["status"];
        icon = "di:gatus";
        url = home "status";
        upstream = local "gatus";
        quickmarkName = "status";
        glance = "private";
        public = {
          domain = "status.${publicDomain}";
          upstream = local "gatus";
        };
      };

      nixlab = {
        title = "nixlab";
        url = public publicDomain;
        quickmarkName = "nixlab";
      };
    };

    serviceOrder = [
      "router"
      "grafana"
      "prometheus"
      "alertmanager"
      "loki"
      "jellyfin"
      "jellyseerr"
      "sonarr"
      "radarr"
      "lidarr"
      "bazarr"
      "readarr"
      "prowlarr"
      "deluge"
      "vaultwarden"
      "filebrowser"
      "headscale"
      "immich"
      "miniflux"
      "paperless"
      "syncthing"
      "glance"
      "homeAssistant"
      "gatus"
      "nixlab"
    ];

    glancePrivateOrder = [
      "jellyfin"
      "sonarr"
      "radarr"
      "lidarr"
      "readarr"
      "bazarr"
      "prowlarr"
      "deluge"
      "grafana"
      "homeAssistant"
      "filebrowser"
      "jellyseerr"
      "miniflux"
      "syncthing"
      "gatus"
    ];

    glancePublicOrder = [
      "jellyfin"
      "vaultwarden"
    ];

    serviceList = map (name: services.${name}) serviceOrder;
    publicServices = lib.filter (svc: (svc.public.domain or null) != null && (svc.public.ingress or true)) serviceList;
    mkGatusEndpoint = svc: {
      name = svc.title;
      inherit (svc.gatus) url;
      interval = svc.gatus.interval or "1m";
      conditions = svc.gatus.conditions or ["[STATUS] == 200"];
    };
    mkPublicGatusEndpoint = svc: {
      name = "${svc.title} (public)";
      url = svc.public.gatusUrl or (svc.public.checkUrl or (public svc.public.domain));
      interval = svc.public.gatusInterval or "5m";
      conditions = svc.public.gatusConditions or ["[STATUS] == 200"];
    };
    mkGlanceSite = svc:
      {
        inherit (svc) title url icon;
        check-url = svc.checkUrl or svc.url;
      }
      // lib.optionalAttrs (svc ? altStatusCodes) {
        alt-status-codes = svc.altStatusCodes;
      };
    mkPublicGlanceSite = svc: {
      title = svc.public.title or svc.title;
      url = svc.public.url or (public svc.public.domain);
      check-url = svc.public.checkUrl or (public svc.public.domain);
      icon = svc.public.icon or svc.icon;
    };
  in {
    inherit services;

    dnsAliases = lib.unique (lib.concatMap (svc: svc.aliases or []) serviceList);

    cloudflaredIngress = lib.listToAttrs (
      map (svc:
        lib.nameValuePair svc.public.domain {
          service = svc.public.upstream;
        })
      publicServices
    );

    quickmarks = lib.listToAttrs (
      map (svc: lib.nameValuePair svc.quickmarkName (svc.quickmarkUrl or svc.url))
      (lib.filter (svc: svc ? quickmarkName) serviceList)
    );

    gatusEndpoints =
      map mkGatusEndpoint (lib.filter (svc: svc ? gatus) serviceList)
      ++ map mkPublicGatusEndpoint (
        lib.filter (svc: (svc.public.gatus or false) && (svc.public.domain or null) != null) serviceList
      );

    blackboxHttpTargets =
      lib.concatMap (
        svc:
          lib.optionals (svc.blackbox or false) [(svc.checkUrl or svc.url)]
          ++ lib.optionals ((svc.public.blackbox or false) && (svc.public.domain or null) != null) [
            (svc.public.checkUrl or (public svc.public.domain))
          ]
      )
      serviceList;

    blackboxHttpAuthTargets =
      lib.concatMap (
        svc: lib.optionals (svc.blackboxAuth or false) [(svc.checkUrl or svc.url)]
      )
      serviceList;

    blackboxTcpTargets = [
      "${hostFqdn}:22"
      "leo.${internalDomain}:22"
      "turn.${publicDomain}:3478"
    ];

    glancePrivateSites = map mkGlanceSite (
      lib.filter (svc: (svc.glance or null) == "private") (map (name: services.${name}) glancePrivateOrder)
    );
    glancePublicSites = map mkPublicGlanceSite (
      lib.filter (svc: (svc.public.glance or false) && (svc.public.domain or null) != null) (
        map (name: services.${name}) glancePublicOrder
      )
    );
  };
}

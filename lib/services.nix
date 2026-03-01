# Service Helper Functions
#
# Provides utility functions for common service configuration patterns.
# Reduces duplication across modules and standardizes service setup.
#
# Usage:
#   let
#     inherit (nix-config.lib.services) mkMountDep mkScrapeConfig;
#   in

{ lib }:
{
  # Helper for services that need mount dependencies
  # Returns systemd service configuration
  #
  # Example:
  #   systemd.services.jellyfin = mkMountDep "srv-smol";
  mkMountDep = mount: {
    after = [ "${mount}.mount" ];
    wants = [ "${mount}.mount" ];
  };

  # Helper for services with agenix secrets
  # Returns age.secrets configuration
  #
  # Example:
  #   age.secrets = mkServiceSecret {
  #     secretName = "jellyfin-api";
  #     file = ../../secrets/jellyfin-api.age;
  #     owner = "jellyfin";
  #   };
  mkServiceSecret =
    {
      secretName,
      file,
      owner,
      group ? "users",
      mode ? "0400",
    }:
    {
      ${secretName} = {
        inherit
          file
          owner
          group
          mode
          ;
      };
    };

  # Helper for prometheus exportarr exporters
  # Returns services.prometheus.exportarr.<service> configuration
  #
  # Example:
  #   services.prometheus.exportarr.sonarr = mkExportarrExporter {
  #     service = config.services.sonarr;
  #     apiSecret = config.age.secrets.sonarr-api.path;
  #     port = 9707;
  #   };
  mkExportarrExporter =
    {
      service,
      apiSecret,
      port,
      url ? null,
      listenAddress ? "0.0.0.0",
      additionalMetrics ? true,
      backfill ? true,
    }:
    let
      computedUrl =
        if url != null then url else "http://127.0.0.1:${toString service.settings.server.port}";
    in
    {
      enable = service.enable;
      apiKeyFile = apiSecret;
      inherit port listenAddress;
      url = computedUrl;
      openFirewall = true;
      environment =
        lib.mkIf additionalMetrics {
          ENABLE_ADDITIONAL_METRICS = "true";
        }
        // lib.optionalAttrs backfill {
          PROWLARR__BACKFILL = "true";
        };
    };

  # Prometheus scrape config builder
  # Returns a scrape_config entry
  #
  # Example:
  #   services.prometheus.scrapeConfigs = [
  #     (mkScrapeConfig { name = "sonarr"; port = 9707; })
  #     (mkScrapeConfig { name = "grafana"; host = "leo.home.arpa"; port = 3000; })
  #   ];
  mkScrapeConfig =
    {
      name,
      host ? "zues.home.arpa",
      port,
      interval ? null,
      path ? "/metrics",
    }:
    {
      job_name = name;
      static_configs = [
        {
          targets = [ "${host}:${toString port}" ];
        }
      ];
      metrics_path = path;
    }
    // lib.optionalAttrs (interval != null) {
      scrape_interval = interval;
    };

  # Build multiple scrape configs from a service list
  # Filters out disabled services automatically
  #
  # Example:
  #   let
  #     services = [
  #       { name = "sonarr"; port = 9707; enabled = config.services.sonarr.enable; }
  #       { name = "radarr"; port = 9708; enabled = config.services.radarr.enable; }
  #     ];
  #   in
  #   services.prometheus.scrapeConfigs = mkScrapeConfigs services;
  mkScrapeConfigs =
    servicesList:
    lib.flatten (
      map (
        svc:
        lib.optional (svc.enabled or true) (mkScrapeConfig {
          name = svc.name;
          port = svc.port;
          host = svc.host or "zues.home.arpa";
          interval = svc.interval or null;
        })
      ) servicesList
    );

  # Helper to create a Grafana dashboard from JSON file
  # Returns dashboard configuration
  #
  # Example:
  #   services.grafana.provision.dashboards.settings.providers = [
  #     (mkGrafanaDashboard { path = ./dashboards; })
  #   ];
  mkGrafanaDashboard =
    {
      name ? "default",
      path,
      folder ? "",
      options ? { },
    }:
    {
      inherit name folder;
      type = "file";
      options = {
        path = toString path;
        foldersFromFilesStructure = true;
      }
      // options;
    };
}

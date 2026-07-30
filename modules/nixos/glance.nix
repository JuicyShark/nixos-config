{
  self,
  config,
  lib,
  pkgs,
  ...
}: let
  portsCfg = config.modules.ports;
  glanceAssets = pkgs.writeTextDir "nixlab.css" (builtins.readFile ./glance.css);
  homelabConfig = self.nixosConfigurations.zues.config;
  endpoints = self.lib.services.mkHomelabEndpoints {
    config = homelabConfig;
  };

  # The catalog deliberately uses terse machine-readable names. Keep its data
  # canonical, then polish only the labels and missing icons at the UI edge.
  titleOverrides = {
    filebrowser = "Files";
    glance = "Nixlab";
    hass = "Home Assistant";
    jellyseerr = "Seerr";
    media-vote = "Media Vote";
    torrent = "qBittorrent";
  };
  iconOverrides = {
    glance = "sh:glance";
    loki = "di:loki";
    prometheus = "si:prometheus";
  };
  upperFirst = value: "${lib.toUpper (builtins.substring 0 1 value)}${builtins.substring 1 ((builtins.stringLength value) - 1) value}";
  displayTitle = title:
    if builtins.hasAttr title titleOverrides
    then titleOverrides.${title}
    else upperFirst title;
  polishSite = site:
    site
    // {
      title = displayTitle site.title;
    }
    // lib.optionalAttrs (
      !(site ? icon) && builtins.hasAttr site.title iconOverrides
    ) {
      icon = iconOverrides.${site.title};
    };

  # Glance itself is already represented by its public edge check. Omitting it
  # from the LAN list avoids a confusing self-link to zues.home.arpa.
  lanSites = map polishSite (
    lib.filter (site: site.title != "glance") endpoints.glanceLanSites
  );
  publicSites = map polishSite endpoints.glancePublicSites;

  mkRss = {
    title,
    feeds,
    limit ? 12,
    collapseAfter ? 6,
    cache ? "6h",
    style ? "vertical-list",
  }: {
    type = "rss";
    inherit title feeds limit cache style;
    collapse-after = collapseAfter;
  };

  nixFeeds = [
    {
      url = "https://nixos.org/blog/announcements-rss.xml";
      title = "NixOS";
      limit = 3;
    }
    {
      url = "https://discourse.nixos.org/c/announcements/8.rss";
      title = "NixOS Discourse";
      limit = 3;
    }
    {
      url = "https://lwn.net/headlines/rss";
      title = "LWN";
      limit = 3;
    }
    {
      url = "https://www.phoronix.com/rss.php";
      title = "Phoronix";
      limit = 3;
    }
  ];
  desktopFeeds = [
    {
      url = "https://hypr.land/rss.xml";
      title = "Hyprland";
      limit = 4;
    }
    {
      url = "https://github.com/hyprwm/Hyprland/releases.atom";
      title = "Hyprland Releases";
      limit = 2;
    }
    {
      url = "https://lobste.rs/t/linux.rss";
      title = "Lobsters Linux";
      limit = 3;
    }
  ];
  homelabFeeds = [
    {
      url = "https://grafana.com/blog/index.xml";
      title = "Grafana";
      limit = 2;
    }
    {
      url = "https://prometheus.io/blog/feed.xml";
      title = "Prometheus";
      limit = 2;
    }
    {
      url = "https://www.home-assistant.io/atom.xml";
      title = "Home Assistant";
      limit = 2;
    }
    {
      url = "https://jellyfin.org/index.xml";
      title = "Jellyfin";
      limit = 2;
    }
    {
      url = "https://tailscale.com/blog/index.xml";
      title = "Tailscale";
      limit = 2;
    }
    {
      url = "https://blog.cloudflare.com/rss/";
      title = "Cloudflare";
      limit = 2;
    }
  ];
  devFeeds = [
    {
      url = "https://openai.com/news/rss.xml";
      title = "OpenAI";
      limit = 3;
    }
    {
      url = "https://github.com/NixOS/nixpkgs/releases.atom";
      title = "nixpkgs Releases";
      limit = 3;
    }
    {
      url = "https://lobste.rs/t/nix.rss";
      title = "Lobsters Nix";
      limit = 3;
    }
  ];
  generalNewsFeeds = [
    {
      url = "https://feeds.npr.org/1001/rss.xml";
      title = "NPR";
      limit = 5;
    }
    {
      url = "https://www.theverge.com/rss/index.xml";
      title = "The Verge";
      limit = 5;
    }
  ];
in {
  options.modules.glance.enable = lib.mkEnableOption "Glance homelab dashboard";

  config = lib.mkIf config.modules.glance.enable {
    services.glance = {
      enable = true;
      openFirewall = true;

      settings = {
        branding = {
          app-name = "Nixlab";
          logo-text = "N";
          hide-footer = true;
        };

        pages = [
          {
            name = "Home";
            slug = "home";
            width = "default";
            desktop-navigation-width = "default";
            show-mobile-header = true;

            head-widgets = [
              {
                type = "search";
                css-class = "nixlab-search";
                autofocus = true;
                new-tab = true;
                placeholder = "Search the web, or use a bang…";
                bangs = [
                  {
                    title = "YouTube";
                    shortcut = "!yt";
                    url = "https://www.youtube.com/results?search_query={QUERY}";
                  }
                  {
                    title = "GitHub";
                    shortcut = "!gh";
                    url = "https://github.com/search?q={QUERY}";
                  }
                  {
                    title = "Nix packages";
                    shortcut = "!nix";
                    url = "https://search.nixos.org/packages?channel=unstable&query={QUERY}";
                  }
                ];
              }
            ];

            columns = [
              {
                size = "small";
                widgets = [
                  {
                    type = "clock";
                    hour-format = "24h";
                  }
                  {
                    type = "calendar";
                    first-day-of-week = "monday";
                  }
                  {
                    type = "weather";
                    location = "Brisbane, Australia";
                    units = "metric";
                    hour-format = "24h";
                  }
                ];
              }
              {
                size = "full";
                widgets = [
                  {
                    type = "group";
                    css-class = "nixlab-status-overview";
                    widgets = [
                      {
                        type = "monitor";
                        title = "LAN Services";
                        style = "compact";
                        cache = "1m";
                        sites = lanSites;
                      }
                      {
                        type = "monitor";
                        title = "Public Edge";
                        style = "compact";
                        cache = "1m";
                        sites = publicSites;
                      }
                    ];
                  }
                  {
                    type = "group";
                    css-class = "nixlab-briefing";
                    widgets = [
                      (mkRss {
                        title = "Nix & Linux";
                        feeds = nixFeeds;
                        limit = 10;
                        collapseAfter = 6;
                      })
                      (mkRss {
                        title = "Homelab";
                        feeds = homelabFeeds;
                        limit = 10;
                        collapseAfter = 6;
                      })
                      (mkRss {
                        title = "Dev & AI";
                        feeds = devFeeds;
                        limit = 9;
                        collapseAfter = 6;
                      })
                    ];
                  }
                ];
              }
              {
                size = "small";
                widgets = [
                  {
                    type = "bookmarks";
                    css-class = "nixlab-bookmarks";
                    groups = [
                      {
                        title = "Daily";
                        links = [
                          {
                            title = "Gmail";
                            url = "https://mail.google.com/";
                            icon = "si:gmail";
                          }
                          {
                            title = "GitHub";
                            url = "https://github.com/";
                            icon = "si:github";
                          }
                          {
                            title = "YouTube";
                            url = "https://www.youtube.com/";
                            icon = "si:youtube";
                          }
                        ];
                      }
                      {
                        title = "Home";
                        links = [
                          {
                            title = "Home Assistant";
                            url = endpoints.services.hass.url;
                            icon = "di:home-assistant";
                          }
                          {
                            title = "Jellyfin";
                            url = endpoints.services.jellyfin.url;
                            icon = "di:jellyfin";
                          }
                          {
                            title = "Requests";
                            url = endpoints.services.jellyseerr.url;
                            icon = "di:jellyseerr";
                          }
                        ];
                      }
                      {
                        title = "Social";
                        links = [
                          {
                            title = "Bluesky";
                            url = "https://bsky.app/";
                            icon = "si:bluesky";
                          }
                          {
                            title = "Reddit";
                            url = "https://www.reddit.com/";
                            icon = "si:reddit";
                          }
                        ];
                      }
                    ];
                  }
                  {
                    type = "to-do";
                    css-class = "nixlab-todo";
                    title = "Today";
                    id = "home";
                  }
                ];
              }
            ];
          }
          {
            name = "Homelab";
            slug = "homelab";
            width = "default";
            desktop-navigation-width = "default";
            show-mobile-header = true;

            columns = [
              {
                size = "small";
                widgets = [
                  {
                    type = "server-stats";
                    css-class = "nixlab-server-stats";
                    title = "Leo";
                    servers = [
                      {
                        type = "local";
                        name = "Leo";
                        hide-mountpoints-by-default = true;
                        mountpoints = {
                          "/" = {
                            name = "System";
                            hide = false;
                          };
                          "/mnt/smol" = {
                            name = "Smol";
                            hide = false;
                          };
                          "/mnt/games" = {
                            name = "Games";
                            hide = false;
                          };
                        };
                      }
                    ];
                  }
                  {
                    type = "bookmarks";
                    css-class = "nixlab-operations";
                    groups = [
                      {
                        title = "Operations";
                        links = [
                          {
                            title = "Status";
                            description = "Endpoint history";
                            url = endpoints.services.gatus.url;
                            icon = "di:gatus";
                          }
                          {
                            title = "Grafana";
                            description = "Metrics and logs";
                            url = endpoints.services.grafana.url;
                            icon = "di:grafana";
                          }
                          {
                            title = "Files";
                            description = "Shared storage";
                            url = endpoints.services.filebrowser.url;
                            icon = "di:filebrowser";
                          }
                        ];
                      }
                    ];
                  }
                ];
              }
              {
                size = "full";
                widgets = [
                  {
                    type = "monitor";
                    css-class = "nixlab-monitor";
                    title = "LAN Services";
                    cache = "1m";
                    sites = lanSites;
                  }
                  {
                    type = "monitor";
                    css-class = "nixlab-monitor";
                    title = "Public Edge";
                    cache = "1m";
                    sites = publicSites;
                  }
                ];
              }
              {
                size = "small";
                widgets = [
                  {
                    type = "releases";
                    css-class = "nixlab-releases";
                    title = "Stack Releases";
                    cache = "6h";
                    show-source-icon = true;
                    collapse-after = 6;
                    repositories = [
                      "glanceapp/glance"
                      "hyprwm/Hyprland"
                      "grafana/grafana"
                      "grafana/loki"
                      "prometheus/prometheus"
                      "home-assistant/core"
                      "jellyfin/jellyfin"
                    ];
                  }
                ];
              }
            ];
          }
          {
            name = "Feeds";
            slug = "feeds";
            width = "wide";
            desktop-navigation-width = "default";
            show-mobile-header = true;

            head-widgets = [
              {
                type = "videos";
                css-class = "nixlab-videos";
                title = "Watch";
                style = "horizontal-cards";
                limit = 12;
                channels = [
                  "UCXuqSBlHAE6Xw-yeJA0Tunw" # Linus Tech Tips
                  "UCR-DXc1voovS8nhAvccRZhg" # Jeff Geerling
                  "UCHnyfMqiRRG1u-2MsSQLbXA" # Veritasium
                  "UC9PBzalIcEQCsiIkq36PyUA" # Digital Foundry
                  "UCpa-Zb0ZcQjTCPP1Dx_1M8Q" # LegalEagle
                  "UCld68syR8Wi-GY_n4CaoJGA" # Brodie Robertson
                ];
              }
            ];

            columns = [
              {
                size = "full";
                widgets = [
                  {
                    type = "group";
                    css-class = "nixlab-feeds";
                    widgets = [
                      (mkRss {
                        title = "Nix & Linux";
                        feeds = nixFeeds;
                        limit = 16;
                        collapseAfter = 10;
                        style = "detailed-list";
                      })
                      (mkRss {
                        title = "Desktop";
                        feeds = desktopFeeds;
                        limit = 12;
                        collapseAfter = 8;
                        style = "detailed-list";
                      })
                      (mkRss {
                        title = "Homelab";
                        feeds = homelabFeeds;
                        limit = 16;
                        collapseAfter = 10;
                        style = "detailed-list";
                      })
                      (mkRss {
                        title = "Dev & AI";
                        feeds = devFeeds;
                        limit = 12;
                        collapseAfter = 8;
                        style = "detailed-list";
                      })
                    ];
                  }
                ];
              }
              {
                size = "full";
                widgets = [
                  {
                    type = "group";
                    css-class = "nixlab-feeds";
                    widgets = [
                      {
                        type = "hacker-news";
                        title = "Hacker News";
                        limit = 20;
                        collapse-after = 10;
                      }
                      {
                        type = "lobsters";
                        title = "Lobsters";
                        limit = 20;
                        collapse-after = 10;
                      }
                      (mkRss {
                        title = "General News";
                        feeds = generalNewsFeeds;
                        limit = 16;
                        collapseAfter = 10;
                        style = "detailed-list";
                        cache = "12h";
                      })
                    ];
                  }
                ];
              }
            ];
          }
        ];

        server = {
          host = "0.0.0.0";
          port = portsCfg.glance;
          assets-path = glanceAssets;
        };

        theme = {
          custom-css-file = "/assets/nixlab.css";
          disable-picker = true;
        };
      };
    };
  };
}

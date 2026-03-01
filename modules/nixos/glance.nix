{
  config,
  lib,
  ...
}:
let
  networkCfg = config.modules.network;
in
{
  services.glance = {
    enable = builtins.elem "homelab-glance" config.modules.system.roles;
    openFirewall = true;

    settings = {
      pages = [
        {
          name = "leo";
          width = "slim";
          hide-desktop-navigation = true;
          center-vertically = true;
          columns = [
            {
              size = "full";
              widgets = [
                {
                  type = "search";
                  autofocus = true;
                }
                {
                  type = "monitor";
                  cache = "1m";
                  title = "Public Services";

                  sites = [
                    {
                      title = "jellyfin";
                      url = "https://jellyfin.nixlab.au/";
                      check-url = "https://jellyfin.nixlab.au/web/index.html";
                      icon = "di:jellyfin";
                    }

                    {
                      title = "Vaultwarden";
                      url = "https://pass.nixlab.au/";
                      check-url = "https://pass.nixlab.au/";
                      icon = "di:vaultwarden";
                    }
                  ];
                }
                {
                  type = "monitor";
                  cache = "1m";
                  title = "Private Services";

                  sites = [
                    {
                      title = "Jellyfin";
                      url = "http://${networkCfg.hosts.imac-machop}:8096";
                      check-url = "http://${networkCfg.hosts.imac-machop}:8096/web/index.html";
                      icon = "di:jellyfin";
                    }
                    {
                      title = "Sonarr";
                      url = "http://${networkCfg.hosts.zues}:${toString config.services.sonarr.settings.server.port}";
                      check-url = "http://${networkCfg.hosts.zues}:${toString config.services.sonarr.settings.server.port}";
                      icon = "di:sonarr";
                    }
                    {
                      title = "Radarr";
                      url = "http://${networkCfg.hosts.zues}:${toString config.services.radarr.settings.server.port}";
                      check-url = "http://${networkCfg.hosts.zues}:${toString config.services.radarr.settings.server.port}";
                      icon = "di:radarr";
                    }
                    {
                      title = "Lidarr";
                      url = "http://${networkCfg.hosts.zues}:${toString config.services.lidarr.settings.server.port}";
                      check-url = "http://${networkCfg.hosts.zues}:${toString config.services.lidarr.settings.server.port}";
                      icon = "di:lidarr";
                    }
                    {
                      title = "Bazarr";
                      url = "http://${networkCfg.hosts.zues}:${toString config.services.bazarr.listenPort}";
                      check-url = "http://${networkCfg.hosts.zues}:${toString config.services.bazarr.listenPort}";
                      icon = "di:bazarr";
                    }
                    {
                      title = "Prowlarr";
                      url = "http://${networkCfg.hosts.zues}:${toString config.services.prowlarr.settings.server.port}";
                      check-url = "http://${networkCfg.hosts.zues}:${toString config.services.prowlarr.settings.server.port}";
                      icon = "di:prowlarr";
                    }

                    {
                      title = "Deluge";
                      url = "http://${networkCfg.hosts.zues}:${toString config.services.deluge.web.port}";
                      check-url = "http://${networkCfg.hosts.zues}:${toString config.services.deluge.web.port}";
                      icon = "di:deluge";
                      alt-status-codes = [ 401 ];
                    }
                    {
                      title = "Grafana";
                      url = "http://${networkCfg.hosts.zues}:${toString config.services.grafana.settings.server.http_port}";
                      check-url = "http://${networkCfg.hosts.zues}:${toString config.services.grafana.settings.server.http_port}";
                      icon = "di:grafana";
                    }
                    {
                      title = "Home-Assist";
                      url = "http://${networkCfg.hosts.ring-doorbell}:8123";
                      check-url = "http://${networkCfg.hosts.ring-doorbell}:8123";
                      icon = "di:home-assistant";
                    }
                    {
                      title = "Files";
                      url = "http://files.home.arpa";
                      check-url = "http://files.home.arpa";
                      icon = "di:filebrowser";
                    }
                  ];
                }
                {
                  type = "split-column";
                  widgets = [
                    {
                      type = "hacker-news";
                      collapse-after = 4;
                    }
                    {
                      type = "rss";
                      title = "The Verge";
                      limit = 10;
                      collapse-after = 5;
                      cache = "12h";

                      feeds = [
                        {
                          url = "https://www.theverge.com/rss/index.xml";
                          title = "The Verge";
                          limit = 4;
                        }
                      ];
                    }
                  ];
                }
                {
                  collapse-after-rows = 1;
                  style = "grid-cards";
                  type = "videos";

                  channels = [
                    "UCXuqSBlHAE6Xw-yeJA0Tunw" # Linus Tech Tips
                    "UCR-DXc1voovS8nhAvccRZhg" # Jeff Geerling
                    "UCHnyfMqiRRG1u-2MsSQLbXA" # Veritasium
                    "UC9PBzalIcEQCsiIkq36PyUA" # Digital Foundry
                    "UCpa-Zb0ZcQjTCPP1Dx_1M8Q" # LegalEagle
                    "UCld68syR8Wi-GY_n4CaoJGA" # Brodie Robertson
                  ];
                }
                {
                  type = "split-column";
                  widgets = [
                    {
                      type = "rss";
                      title = "NPR";
                      limit = 10;
                      collapse-after = 5;
                      cache = "12h";

                      feeds = [
                        {
                          url = "https://feeds.npr.org/1001/rss.xml";
                          title = "NPR";
                          limit = 4;
                        }
                      ];
                    }
                    {
                      type = "lobsters";
                      collapse-after = 4;
                    }
                  ];
                }
                {
                  type = "bookmarks";
                  groups = [
                    {
                      title = "General";
                      links = [
                        {
                          title = "Gmail";
                          url = "https://gmail.com/";
                        }
                        {
                          title = "YouTube";
                          url = "https://www.youtube.com/";
                        }
                        {
                          title = "Github";
                          url = "https://github.com/";
                        }
                      ];
                    }
                    {
                      title = "Social";
                      links = [
                        {
                          title = "Bluesky";
                          url = "https://bsky.app/";
                        }
                        {
                          title = "Reddit";
                          url = "https://www.reddit.com/";
                        }
                      ];
                    }
                  ];
                }
              ];
            }
          ];
        }
      ];

      server.host = "0.0.0.0";
      server.port = 3457;
    };
  };
}

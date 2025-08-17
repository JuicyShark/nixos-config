{
  #gglance
  services.glance = {
    enable = true;
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
                      title = "Immich";
                      url = "https://photos.nixlab.au/";
                      check-url = "https://photos.nixlab.au/";
                      icon = "di:immich";
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
                      url = "http://192.168.1.54:8096";
                      check-url = "http://192.168.1.54:8096/web/index.html";
                      icon = "di:jellyfin";
                    }
                    {
                      title = "Sonarr";
                      url = "http://192.168.1.54:8096";
                      check-url = "http://192.168.1.54:8989";
                      icon = "di:sonarr";
                    }
                    {
                      title = "Radarr";
                      url = "http://192.168.1.54:8096";
                      check-url = "http://192.168.1.54:7878";
                      icon = "di:radarr";
                    }
                    {
                      title = "Lidarr";
                      url = "http://192.168.1.54:8096";
                      check-url = "http://192.168.1.54:8686";
                      icon = "di:lidarr";
                    }
                    {
                      title = "Prowlarr";
                      url = "http://192.168.1.54:9696";
                      check-url = "http://192.168.1.54:8096";
                      icon = "di:prowlarr";
                    }

                    {
                      title = "Deluge";
                      url = "http://192.168.1.54:9050";
                      check-url = "http://192.168.1.54:8096";
                      icon = "di:deluge";
                      alt-status-codes = [ 401 ];
                    }
                    {
                      title = "Grafana";
                      url = "http://192.168.1.54:3007";
                      check-url = "http://192.168.1.54:3007";
                      icon = "di:grafana";
                    }
                    {
                      title = "Uptime Kuma";
                      url = "http://192.168.1.54:6664";
                      check-url = "http://192.168.1.54:8096";
                      icon = "di:uptime-kuma";
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
                      title = "Aly Raffauf";
                      links = [
                        {
                          title = "Website";
                          url = "https://aly.codes/";
                        }
                        {
                          title = "Github";
                          url = "https://github.com/alyraffauf/";
                        }
                        {
                          title = "Linkedin";
                          url = "https://www.linkedin.com/in/alyraffauf/";
                        }
                      ];
                    }
                    {
                      title = "General";
                      links = [
                        {
                          title = "Fastmail";
                          url = "https://fastmail.com/";
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
                        {
                          title = "Instagram";
                          url = "https://www.instagram.com/";
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
      server.port = 5678;
    };
  };
}

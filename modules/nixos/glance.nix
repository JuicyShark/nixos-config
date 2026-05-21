{
  self,
  config,
  lib,
  pkgs,
  ...
}: let
  portsCfg = config.modules.ports;
  endpoints = self.lib.${pkgs.stdenv.hostPlatform.system}.services.mkHomelabEndpoints {inherit config;};
in {
  options.modules.glance.enable = lib.mkEnableOption "Glance homelab dashboard";

  config = lib.mkIf config.modules.glance.enable {
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

                    sites = endpoints.glancePublicSites;
                  }
                  {
                    type = "monitor";
                    cache = "1m";
                    title = "Private Services";

                    sites = endpoints.glancePrivateSites;
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
        server.port = portsCfg.glance;
      };
    };
  };
}

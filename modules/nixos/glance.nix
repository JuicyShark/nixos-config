{
  self,
  config,
  lib,
  ...
}: let
  portsCfg = config.modules.ports;
  homelabConfig = self.nixosConfigurations.zues.config;
  endpoints = self.lib.services.mkHomelabEndpoints {
    config = homelabConfig;
  };
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

                    sites = endpoints.glanceLanSites;
                  }
                  {
                    type = "split-column";
                    widgets = [
                      {
                        type = "rss";
                        title = "Nix & Linux";
                        limit = 12;
                        collapse-after = 6;
                        cache = "6h";
                        feeds = [
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
                      }
                      {
                        type = "rss";
                        title = "Desktop";
                        limit = 8;
                        collapse-after = 4;
                        cache = "6h";
                        feeds = [
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
                            limit = 2;
                          }
                        ];
                      }
                    ];
                  }
                  {
                    type = "split-column";
                    widgets = [
                      {
                        type = "rss";
                        title = "Homelab";
                        limit = 12;
                        collapse-after = 6;
                        cache = "6h";
                        feeds = [
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
                      }
                      {
                        type = "rss";
                        title = "Dev & AI";
                        limit = 8;
                        collapse-after = 4;
                        cache = "6h";
                        feeds = [
                          {
                            url = "https://openai.com/news/rss.xml";
                            title = "OpenAI";
                            limit = 3;
                          }
                          {
                            url = "https://github.com/NixOS/nixpkgs/releases.atom";
                            title = "nixpkgs Releases";
                            limit = 2;
                          }
                          {
                            url = "https://lobste.rs/t/nix.rss";
                            title = "Lobsters Nix";
                            limit = 3;
                          }
                        ];
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
        server.port = portsCfg.glance;
      };
    };
  };
}

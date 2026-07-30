{
  self,
  config,
  osConfig,
  lib,
  pkgs,
  ...
}: let
  c = config.lib.stylix.colors;
  terminal = config.modules.terminal.command;
  homelabConfig = self.nixosConfigurations.zues.config;
  endpoints = self.lib.services.mkHomelabEndpoints {
    config = homelabConfig;
  };

  mpvUserscript = pkgs.writeShellApplication {
    name = "qute-mpv";
    runtimeInputs = [pkgs.mpv];
    text = ''
      # qutebrowser userscript: open current page or hinted link in mpv
      URL="''${QUTE_SELECTED_TEXT:-''${QUTE_URL:-}}"
      URL="$(printf '%s' "$URL" | tr -d '[:space:]')"
      [ -z "$URL" ] && { echo "qute-mpv: no URL" >&2; exit 1; }
      mpv "$URL" &>/dev/null &
      disown
    '';
  };
in
  lib.mkIf ((osConfig.modules.desktop.enable or false) && !pkgs.stdenv.hostPlatform.isDarwin) {
    xdg.dataFile."qutebrowser/userscripts/qute-mpv" = {
      source = "${mpvUserscript}/bin/qute-mpv";
      executable = true;
    };

    programs.qutebrowser = {
      enable = true;
      package = pkgs.qutebrowser;

      settings = {
        # Startup
        auto_save.session = true;
        session.lazy_restore = true;
        new_instance_open_target = "tab";
        window.hide_decoration = false;

        # Colors: Stylix owns the base palette; force a few readability tweaks.
        colors = {
          webpage.preferred_color_scheme = "dark";
          hints = {
            bg = lib.mkForce "#${c.base0A}";
            fg = lib.mkForce "#${c.base00}";
            match.fg = lib.mkForce "#${c.base03}";
          };
          keyhint = {
            bg = lib.mkForce "rgba(15,20,17,0.92)";
            suffix.fg = lib.mkForce "#${c.base0D}";
          };
          completion = {
            category.border = {
              bottom = lib.mkForce "#${c.base02}";
              top = lib.mkForce "#${c.base02}";
            };
            item.selected = {
              bg = lib.mkForce "#${c.base02}";
              border = {
                top = lib.mkForce "#${c.base02}";
                bottom = lib.mkForce "#${c.base02}";
              };
            };
            scrollbar.fg = lib.mkForce "#${c.base04}";
          };
          tabs = {
            odd.fg = lib.mkForce "#${c.base04}";
            even.fg = lib.mkForce "#${c.base04}";
          };
          statusbar = {
            insert.bg = lib.mkForce "#${c.base0D}";
            caret.bg = lib.mkForce "#${c.base0E}";
            passthrough.bg = lib.mkForce "#${c.base0E}";
            url = {
              hover.fg = lib.mkForce "#${c.base0C}";
              success.https.fg = lib.mkForce "#${c.base0D}";
            };
          };
        };

        # Privacy & security
        content = {
          cookies.accept = "no-3rdparty";
          geolocation = false;
          notifications.enabled = false;
          webgl = true;
          javascript = {
            enabled = true;
            clipboard = "none";
          };
          autoplay = false;
          canvas_reading = true;
          headers = {
            do_not_track = true;
            referer = "same-domain";
          };
          private_browsing = false;
          blocking = {
            enabled = true;
            method = "both";
            adblock.lists = [
              "https://easylist.to/easylist/easylist.txt"
              "https://easylist.to/easylist/easyprivacy.txt"
              "https://secure.fanboy.co.nz/fanboy-cookiemonster.txt"
              "https://easylist-downloads.adblockplus.org/abp-filters-anti-cv.txt"
              "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/unbreak.txt"
              "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters.txt"
              "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/privacy.txt"
              "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/resource-abuse.txt"
            ];
          };
        };

        # Tabs (scalar options only; tabs.padding goes in extraConfig)
        tabs = {
          position = "top";
          show = "multiple";
          last_close = "close";
          new_position = {
            unrelated = "next";
            related = "next";
          };
          select_on_remove = "next";
          mousewheel_switching = false;
          indicator.width = 3;
          min_width = 140;
          max_width = 280;
          close_mouse_button = "middle";
          close_mouse_button_on_bar = "new-tab";
          favicons.show = "pinned";
          title = {
            format = "{audio}{private}{current_title}";
            format_pinned = "{audio}{private}";
          };
        };

        # Scrolling
        scrolling.smooth = true;
        scrolling.bar = "overlay";

        # Completion
        completion = {
          open_categories = [
            "searchengines"
            "quickmarks"
            "bookmarks"
            "history"
            "filesystem"
          ];
          use_best_match = true;
          height = "35%";
          shrink = true;
          timestamp_format = "%Y-%m-%d";
          web_history.max_items = 2000;
        };

        # Statusbar
        statusbar.widgets = [
          "keypress"
          "progress"
          "scroll"
          "history"
          "tabs"
          "url"
        ];
        statusbar.show = "in-mode";

        # Downloads
        downloads.position = "bottom";
        downloads.remove_finished = 5000;

        # Hints
        hints = {
          mode = "letter";
          uppercase = false;
          scatter = true;
          min_chars = 1;
          chars = "arstgmneioqwfpbxcdv";
          radius = 3;
        };

        # Input / editor
        input = {
          insert_mode = {
            auto_enter = true;
            auto_leave = true;
            plugins = false;
          };
          partial_timeout = 200;
        };
        fileselect = {
          handler = "external";
          single_file.command = [
            terminal
            "-e"
            "yazi"
            "--chooser-file"
            "{}"
          ];
          multiple_files.command = [
            terminal
            "-e"
            "yazi"
            "--chooser-file"
            "{}"
          ];
          folder.command = [
            terminal
            "-e"
            "yazi"
            "--chooser-file"
            "{}"
          ];
        };

        editor.command = [
          terminal
          "-e"
          "nvim"
          "{file}"
        ];

        # Zoom
        zoom.default = "100%";
        zoom.levels = [
          "25%"
          "33%"
          "50%"
          "67%"
          "75%"
          "90%"
          "100%"
          "110%"
          "125%"
          "150%"
          "175%"
          "200%"
          "250%"
          "300%"
        ];

        content.pdfjs = true;
        url = {
          start_pages = ["https://nixlab.au"];
          default_page = "https://nixlab.au";
        };

        qt.args = [
          "enable-gpu-rasterization"
          "ignore-gpu-blocklist"
          "disable-gpu-driver-bug-workarounds"
          "enable-accelerated-video-decode"
          "enable-features=VaapiVideoDecoder,VaapiVideoEncoder"
          "enable-zero-copy"
        ];
      };

      searchEngines = {
        DEFAULT = "https://duckduckgo.com/?q={}";
        ddg = "https://duckduckgo.com/?q={}";
        g = "https://www.google.com/search?q={}";
        gh = "https://github.com/search?q={}&type=repositories";
        nix = "https://search.nixos.org/packages?query={}";
        nixo = "https://search.nixos.org/options?query={}";
        hm = "https://search.nixos.org/options?source=home_manager&query={}";
        yt = "https://www.youtube.com/results?search_query={}";
        wiki = "https://en.wikipedia.org/wiki/Special:Search?search={}";
        arch = "https://wiki.archlinux.org/index.php?search={}";
        rd = "https://www.reddit.com/search/?q={}";
        pypi = "https://pypi.org/search/?q={}";
        img = "https://www.google.com/search?tbm=isch&q={}";
      };

      keyBindings.normal = {
        # Layer 1 is the navigation surface: arrows scroll, Ctrl changes tabs,
        # and Alt walks browser history. Do not make Colemak letters pretend
        # to be a QWERTY navigation cluster.
        "<Left>" = "scroll left";
        "<Down>" = "scroll down";
        "<Up>" = "scroll up";
        "<Right>" = "scroll right";
        "<Ctrl-Left>" = "tab-prev";
        "<Ctrl-Right>" = "tab-next";
        "<Alt-Left>" = "back";
        "<Alt-Right>" = "forward";
        h = "nop";
        j = "nop";
        k = "nop";
        l = "nop";
        H = "nop";
        J = "nop";
        K = "nop";
        L = "nop";
        ",m" = "spawn --userscript qute-mpv";
        ",M" = "hint links userscript qute-mpv";
      };

      perDomainSettings = {
        "*://www.youtube.com/*".content.autoplay = true;
        "*://music.youtube.com/*".content.autoplay = true;
        "*://open.spotify.com/*".content.autoplay = true;
        "*://twitch.tv/*".content.autoplay = true;
        "*://www.twitch.tv/*".content.autoplay = true;
        "*://calendar.google.com/*".content.notifications.enabled = true;
      };

      quickmarks = endpoints.qutebrowserQuickmarks;

      # Home Manager flattens nested settings into config.set calls; these
      # qutebrowser options intentionally need Python dict assignment.
      extraConfig = ''
        c.qt.environ = {"LIBVA_DRIVER_NAME": "radeonsi"}

        c.tabs.padding = {"top": 3, "bottom": 3, "left": 6, "right": 6}
        c.hints.padding = {"top": 1, "bottom": 1, "left": 3, "right": 3}
      '';
    };
  }

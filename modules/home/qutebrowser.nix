{
  self,
  config,
  osConfig,
  lib,
  pkgs,
  ...
}: let
  c = config.lib.stylix.colors;
  endpoints = self.lib.${pkgs.stdenv.hostPlatform.system}.services.mkHomelabEndpoints {config = osConfig;};

  mpvUserscript = pkgs.writeScript "qute-mpv" ''
    #!/usr/bin/env bash
    # qutebrowser userscript: open current page or hinted link in mpv
    set -euo pipefail
    URL="''${QUTE_SELECTED_TEXT:-''${QUTE_URL:-}}"
    URL="$(printf '%s' "$URL" | tr -d '[:space:]')"
    [ -z "$URL" ] && { echo "qute-mpv: no URL" >&2; exit 1; }
    ${lib.getExe pkgs.mpv} "$URL" &>/dev/null &
    disown
  '';
in
  lib.mkIf ((osConfig.modules.desktop.enable or false) || pkgs.stdenv.isDarwin) {
    xdg.dataFile."qutebrowser/userscripts/qute-mpv" = {
      source = mpvUserscript;
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

        # Dark mode
        colors.webpage.preferred_color_scheme = "dark";

        # Privacy & security
        content = {
          cookies.accept = "no-3rdparty";
          geolocation = false;
          notifications.enabled = true;
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

        # Fonts (Stylix values)
        fonts = {
          default_family = "Iosevka Nerd Font";
          default_size = "11pt";
          completion = {
            entry = "11pt IosevkaTerm Nerd Font Mono";
            category = "bold 11pt Iosevka Nerd Font";
          };
          statusbar = "11pt IosevkaTerm Nerd Font Mono";
          tabs = {
            selected = "11pt Iosevka Nerd Font";
            unselected = "11pt Iosevka Nerd Font";
          };
          hints = "bold 10pt IosevkaTerm Nerd Font Mono";
          messages = {
            info = "11pt IosevkaTerm Nerd Font Mono";
            error = "11pt IosevkaTerm Nerd Font Mono";
            warning = "11pt IosevkaTerm Nerd Font Mono";
          };
          keyhint = "bold 10pt IosevkaTerm Nerd Font Mono";
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
          chars = "asdfjkl;ghqwertyuiopzxcvbnm";
          radius = 3;
        };

        # Spellcheck
        spellcheck.languages = [
          "en-AU"
          "en-US"
        ];

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
            "${lib.getExe pkgs.kitty}"
            "--class"
            "floating-editor"
            "-e"
            "yazi"
            "--chooser-file"
            "{}"
          ];
          multiple_files.command = [
            "${lib.getExe pkgs.kitty}"
            "--class"
            "floating-editor"
            "-e"
            "yazi"
            "--chooser-file"
            "{}"
          ];
          folder.command = [
            "${lib.getExe pkgs.kitty}"
            "--class"
            "floating-editor"
            "-e"
            "yazi"
            "--chooser-file"
            "{}"
          ];
        };

        editor.command = [
          "${lib.getExe pkgs.kitty}"
          "--class"
          "floating-editor"
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

        # Colors: Stylix auto-generates all qutebrowser colors via its own HM
        # target — no color settings here to avoid conflicts. Fine-tuning is
        # done in extraConfig with c.colors.* assignments.
      };

      # -------------------------------------------------------------------------
      # Key bindings
      # cmd-set-text replaces the deprecated set-cmd-text.
      # completion-item-focus history uses the -H flag, not a "prev-history" value.
      # follow-selected is caret-mode only; it's selection-follow in normal mode
      # (but <Return> in normal mode is already handled by default).
      # -------------------------------------------------------------------------
      keyBindings = {
        normal = {
          # Navigation
          "j" = "scroll down";
          "k" = "scroll up";
          "h" = "scroll left";
          "l" = "scroll right";
          "gg" = "scroll-to-perc 0";
          "G" = "scroll-to-perc";
          "d" = "scroll-page 0 0.5";
          "u" = "scroll-page 0 -0.5";

          # Hints
          "f" = "hint";
          "F" = "hint all tab";
          ";m" = "hint links userscript qute-mpv";
          ";M" = "hint --rapid links userscript qute-mpv";
          ";i" = "hint images";
          ";I" = "hint images tab";
          ";u" = "hint links yank";
          ";y" = "hint links yank-primary";

          # MPV
          "M" = "spawn --userscript qute-mpv";
          "<Ctrl-m>" = "spawn --userscript qute-mpv";

          # History
          "H" = "back";
          "L" = "forward";
          "r" = "reload";
          "R" = "reload -f";

          # Open / URL bar (cmd-set-text replaces set-cmd-text)
          "o" = "cmd-set-text -s :open";
          "O" = "cmd-set-text -s :open {url:pretty}";
          "t" = "cmd-set-text -s :open -t";
          "T" = "cmd-set-text -s :open -t {url:pretty}";
          "b" = "cmd-set-text -s :buffer";
          "gw" = "cmd-set-text -s :tab-take";
          "gB" = "cmd-set-text -s :quickmark-load";
          "gQ" = "quickmark-add";
          "Sc" = "cmd-set-text -s :set";
          "gr" = "cmd-set-text :reader";
          "m" = "cmd-set-text -s :set-mark";
          "`" = "cmd-set-text -s :jump-mark";

          # Search
          "/" = "cmd-set-text /";
          "?" = "cmd-set-text ?";
          "n" = "search-next";
          "N" = "search-prev";

          # Tabs
          "gt" = "tab-next";
          "gT" = "tab-prev";
          "J" = "tab-next";
          "K" = "tab-prev";
          "<Ctrl-j>" = "tab-next";
          "<Ctrl-k>" = "tab-prev";
          "x" = "tab-close";
          "X" = "undo";
          "gd" = "tab-clone";
          "gl" = "tab-move +";
          "gh" = "tab-move -";
          "p" = "tab-pin";
          "gm" = "tab-mute";
          "W" = "tab-give";
          "<Ctrl-1>" = "tab-focus 1";
          "<Ctrl-2>" = "tab-focus 2";
          "<Ctrl-3>" = "tab-focus 3";
          "<Ctrl-4>" = "tab-focus 4";
          "<Ctrl-5>" = "tab-focus 5";
          "<Ctrl-6>" = "tab-focus 6";
          "<Ctrl-7>" = "tab-focus 7";
          "<Ctrl-8>" = "tab-focus 8";
          "<Ctrl-9>" = "tab-focus -1";

          # Zoom
          "+" = "zoom-in";
          "-" = "zoom-out";
          "=" = "zoom";

          # Yank / clipboard
          "yy" = "yank";
          "yt" = "yank title";
          "yT" = "yank --sel title";
          "yY" = "yank --sel";
          "ym" = "yank inline [{title}]({url})";
          "P" = "open -- {clipboard}";
          "pp" = "open -t -- {clipboard}";

          # Page / dev
          "gf" = "view-source";
          "gi" = "hint inputs";

          # Caret
          "v" = "caret";

          # Config
          "Ss" = "config-source";
          "Se" = "config-edit";
          "St" = "config-cycle statusbar.show always in-mode";
          "Sh" = "config-cycle tabs.show multiple always never switching";

          # Bookmarks
          "gb" = "bookmark-add";
          "gL" = "bookmark-list";

          # Stop / quit
          "Cs" = "stop";
          "ZZ" = "quit --save";
          "ZQ" = "quit";

          # Private window
          "<Ctrl-Shift-p>" = "open -p";

          # Dev tools
          "<F12>" = "devtools";
          "<Ctrl-Shift-i>" = "devtools";
          "<Ctrl-Shift-j>" = "devtools --position=bottom";

          # Hint: search selected text via DEFAULT engine
          ";s" = "hint links fill :open -t {hint-url}";

          # Open URL in mpv at specific quality (pipe through yt-dlp flags via spawn)
          ";4" = "hint links spawn ${lib.getExe pkgs.mpv} --ytdl-format='bestvideo[height<=480]+bestaudio/best[height<=480]' {hint-url}";
          ";8" = "hint links spawn ${lib.getExe pkgs.mpv} --ytdl-format='bestvideo[height<=1080]+bestaudio/best' {hint-url}";

          # Scroll to % (e.g. 5g = 50%, 2g = 20%)
          "gp" = "scroll-to-perc 50";

          # Duplicate tab in background
          "gD" = "tab-clone -b";
        };

        insert = {
          "<Escape>" = "leave-mode";
          "<Ctrl-e>" = "edit-text";
        };

        hint = {
          "<Escape>" = "leave-mode";
        };

        command = {
          # completion-item-focus: valid values are next/prev/next-category/
          # prev-category/next-page/prev-page.  History browsing uses the -H flag.
          "<Ctrl-p>" = "completion-item-focus prev -H";
          "<Ctrl-n>" = "completion-item-focus next -H";
          "<Tab>" = "completion-item-focus next";
          "<Shift-Tab>" = "completion-item-focus prev";
          "<Ctrl-j>" = "completion-item-focus next";
          "<Ctrl-k>" = "completion-item-focus prev";
          "<Up>" = "completion-item-focus prev -H";
          "<Down>" = "completion-item-focus next -H";
        };

        caret = {
          "<Escape>" = "leave-mode";
          "v" = "toggle-selection";
          # selection-follow is the correct command name in 3.x
          "<Return>" = "selection-follow";
          "<Ctrl-Return>" = "selection-follow --tab";
          "y" = "yank selection";
          "j" = "move-to-next-line";
          "k" = "move-to-prev-line";
          "h" = "move-to-prev-char";
          "l" = "move-to-next-char";
          "w" = "move-to-next-word";
          "b" = "move-to-prev-word";
          "e" = "move-to-end-of-word";
          "0" = "move-to-start-of-line";
          "$" = "move-to-end-of-line";
          "gg" = "move-to-start-of-document";
          "G" = "move-to-end-of-document";
        };
      };

      inherit (endpoints) quickmarks;

      # -------------------------------------------------------------------------
      # extraConfig — raw Python appended after the generated config.set() calls.
      # load_autoconfig(False) is already emitted first by the HM module, so we
      # do NOT repeat it here.
      # Dict/Padding options must be set here with the c. shorthand.
      # -------------------------------------------------------------------------
      extraConfig = ''
        # --- Color tweaks over Stylix defaults ---
        # Stylix sets all colors; we override a handful for better contrast/accent.
        # Hints: yellow bg is far more readable than dark secondary-background.
        c.colors.hints.bg = "#${c.base0A}"
        c.colors.hints.fg = "#${c.base00}"
        c.colors.hints.match.fg = "#${c.base03}"
        # Keyhint: semi-transparent dark bg, green accent on suffix
        c.colors.keyhint.bg = "rgba(15,20,17,0.92)"
        c.colors.keyhint.suffix.fg = "#${c.base0D}"
        # Completion: tighter border contrast, brighter selected highlight
        c.colors.completion.category.border.bottom = "#${c.base02}"
        c.colors.completion.category.border.top = "#${c.base02}"
        c.colors.completion.item.selected.bg = "#${c.base02}"
        c.colors.completion.item.selected.border.top = "#${c.base02}"
        c.colors.completion.item.selected.border.bottom = "#${c.base02}"
        c.colors.completion.scrollbar.fg = "#${c.base04}"
        # Tabs: dim unselected tab text so selected stands out
        c.colors.tabs.odd.fg = "#${c.base04}"
        c.colors.tabs.even.fg = "#${c.base04}"
        # Statusbar: use green accent for insert, purple for caret/passthrough
        c.colors.statusbar.insert.bg = "#${c.base0D}"
        c.colors.statusbar.caret.bg = "#${c.base0E}"
        c.colors.statusbar.passthrough.bg = "#${c.base0E}"
        # URL: teal on hover, bright green for https success
        c.colors.statusbar.url.hover.fg = "#${c.base0C}"
        c.colors.statusbar.url.success.https.fg = "#${c.base0D}"

        # --- AMD GPU hardware acceleration + best video quality ---
        # ignore-gpu-blocklist: allow VA-API even if driver is on Chromium's denylist
        # disable-gpu-driver-bug-workarounds: drop throttles/workarounds that cut quality
        # enable-features=VaapiVideoDecoder: full VA-API path for H.264/VP9/AV1 decode
        # enable-zero-copy: video frames stay in GPU memory, no CPU readback
        # NOTE: ozone-platform=wayland removed — QtWebEngine's bundled Chromium is
        # not built with the wayland ozone backend, which aborts on startup.
        # NOTE: Vulkan/UseSkiaRenderer removed — QtWebEngine's bundled Skia crashes
        # on AMD (SIGFPE in GrVkPrimaryCommandBuffer::beginRenderPass). GL path is
        # stable and still gets VA-API video decode.
        c.qt.args = [
            "enable-gpu-rasterization",
            "ignore-gpu-blocklist",
            "disable-gpu-driver-bug-workarounds",
            "enable-accelerated-video-decode",
            "enable-features=VaapiVideoDecoder,VaapiVideoEncoder",
            "enable-zero-copy",
        ]
        # Point libva at the radeonsi driver (amdgpu VA-API backend)
        c.qt.environ = {"LIBVA_DRIVER_NAME": "radeonsi"}

        # --- Dict/Padding typed options (can't be split into sub-keys by HM) ---

        c.tabs.padding = {"top": 3, "bottom": 3, "left": 6, "right": 6}
        c.hints.padding = {"top": 1, "bottom": 1, "left": 3, "right": 3}

        c.url.searchengines = {
            "DEFAULT": "https://duckduckgo.com/?q={}",
            "ddg":     "https://duckduckgo.com/?q={}",
            "g":       "https://www.google.com/search?q={}",
            "gh":      "https://github.com/search?q={}&type=repositories",
            "nix":     "https://search.nixos.org/packages?query={}",
            "nixo":    "https://search.nixos.org/options?query={}",
            "hm":      "https://home-manager-options.extranix.com/?query={}",
            "yt":      "https://www.youtube.com/results?search_query={}",
            "wiki":    "https://en.wikipedia.org/wiki/Special:Search?search={}",
            "arch":    "https://wiki.archlinux.org/index.php?search={}",
            "rd":      "https://www.reddit.com/search/?q={}",
            "mdn":     "https://developer.mozilla.org/en-US/search?q={}",
            "crate":   "https://crates.io/search?q={}",
            "np":      "https://mynixos.com/search?q={}",
            "so":      "https://stackoverflow.com/search?q={}",
            "pypi":    "https://pypi.org/search/?q={}",
            "img":     "https://www.google.com/search?tbm=isch&q={}",
            "aw":      "https://wiki.archlinux.org/index.php?search={}",
            "gt":      "https://translate.google.com/?sl=auto&tl=en&text={}",
        }

        # --- Misc tab/content settings ---
        c.tabs.close_mouse_button = "middle"
        c.tabs.close_mouse_button_on_bar = "new-tab"
        c.tabs.favicons.show = "pinned"
        c.content.pdfjs = True
        c.url.start_pages = ["https://nixlab.au"]
        c.url.default_page = "https://nixlab.au"
        # Tab suspend: unload background tabs to save RAM (keeps URL/title)

        # --- Per-domain autoplay overrides ---
        config.set("content.autoplay", True, "*://www.youtube.com/*")
        config.set("content.autoplay", True, "*://music.youtube.com/*")
        config.set("content.autoplay", True, "*://open.spotify.com/*")
        config.set("content.autoplay", True, "*://twitch.tv/*")
        config.set("content.autoplay", True, "*://www.twitch.tv/*")

        # --- Per-domain notification overrides ---
        config.set("content.notifications.enabled", True, "*://calendar.google.com/*")
      '';
    };
  }

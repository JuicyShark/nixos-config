# Oh Firefox, gateway to the interwebs, devourer of ram. Give onto me your infinite knowledge and shelter me from ads, but bless my $HOME with directories nobody needs and live long enough to turn into Chrome.

# Credit, https://github.com/hlissner/dotfiles/blob/55194e703d1fe82e7e0ffd06e460f1897b6fc404/modules/desktop/browsers/firefox.nix#L48

{pkgs, ...}: {
  xdg.mimeApps.defaultApplications = {
    "text/html" = ["firefox.desktop"];
    "text/xml" = ["firefox.desktop"];
    "x-scheme-handler/http" = ["firefox.desktop"];
    "x-scheme-handler/https" = ["firefox.desktop"];
  };

 # xdg.configFile."ff2mpv-rust.json".text = lib.optionals config.programs.mpv.enable ''
 #   "player_command": "${config.programs.mpv.package}/bin/umpv",
 #   "player_args": ["--no-config"]
 # '';

  programs.firefox = {
    enable = true;

    languagePacks = [ "en-GB" ];

    nativeMessagingHosts = with pkgs; [tridactyl-native];

      policies = {
        DontCheckDefaultBrowser = true;
        DisablePocket = true;
        DisableAppUpdate = true;
      };
    profiles.default = {
      isDefault = true;
      name = "default";

      search = {
        engines = {
          "Nix Packages" = {
            urls = [
              {
                template = "https://search.nixos.org/packages";
                params = [
                  {
                    name = "type";
                    value = "packages";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = ["@nix"];
          };
          "YT" = {
            urls = [
              {
                template = "https://www.youtube.com/results?search_query={searchTerms}";
              }
            ];
            iconUpdateURL = "https://www.youtube.com/favicon.ico";
            updateInterval = 24 * 60 * 60 * 1000;
            definedAliases = ["@yt"];
          };
          "Google" = {
            urls = [{template = "http://google.com.au/search?q={searchTerms}";}];
            iconUpdateURL = "http://google.com.au/favicon.ico";
            updateInterval = 24 * 60 * 60 * 1000;
            definedAliases = ["@g"];
          };
        };
        force = true;
        default = "Google";
      };

      settings = {
      # Allow svgs to take on theme colors
      "svg.context-properties.content.enabled" = true;
      # Pressing TAB from address bar shouldn't cycle through buttons befor switching focus back to the webppage. Most of those buttons have  dedicated shortcuts, so I don't need this level of tabstop granularity.
      "browser.toolbars.keyboard_navigation" = false;
      "browser.translations.automaticallyPopup" = false;
      "services.sync.prefs.sync.browser.uiCustomization.state" = true;
      "signon.rememberSignons" = false;
      "browser.urlbar.suggest.searches" = false;
      "browser.urlbar.shortcuts.bookmarks" = true;
      "browser.urlbar.shortcuts.history" = false;
      "browser.urlbar.shortcuts.tabs" = true;
      "browser.urlbar.showSearchSuggestionsFirst" = false;


      "full-screen-api.ignore-widgets" = true;   # Fullscreen the browser window not whole screen.
      "browser.disableResetPrompt" = true;       # "Looks like you haven't started Firefox in a while."
      "browser.onboarding.enabled" = false;      # "New to Firefox? Let's get started!" tour
      "browser.aboutConfig.showWarning" = false; # Warning when opening about:config

      "browser.newtabpage.activity-stream.asrouter.userprefs.cfr" = false;

      "extensions.htmlaboutaddons.discover.enabled" = false;

      "dom.battery.enabled" = false;
      "beacon.enabled" = false;
      "browser.send_pings" = false;
      "dom.gamepad.enabled" = false;

      "toolkit.coverage.endpoint.base" = "";
      "experiments.supported" = false;
      "experiments.enabled" = false;
      "experiments.manifest.uri" = "";


      "browser.sessionstore.interval" = "1800000";
      "extensions.unifiedExtensions.enabled" = false;
      "extensions.shield-recipe-client.enabled" = false;
      "reader.parse-on-load.enabled" = false;  # "reader view"
      # Since FF 113, you must press TAB twice to cycle through urlbar suggestions. This disables that.
      "browser.urlbar.resultMenu.keyboardAccessible" = false;


        "nglayout.initialpaint.delay" = 5;
        "nglayout.initialpaint.delay_in_oopif" = 0;
        "content.notify.interval" = 100000;
        "browser.startup.preXulSkeletonUI" = false;

        # * EXPERIMENTAL **
        "layout.css.grid-template-masonry-value.enabled" = true;
        "dom.enable_web_task_scheduling" = true;

        # * GFX **
        "gfx.webrender.all" = true;
        "gfx.webrender.precache-shaders" = true;
        "gfx.webrender.compositor" = true;
        "layers.gpu-process.enabled" = true;
        "media.hardware-video-decoding.enabled" = true;
        "gfx.canvas.accelerated" = true;
        "gfx.canvas.accelerated.cache-items" = 8192;
        "gfx.canvas.accelerated.cache-size" = 2056;
        "gfx.content.skia-font-cache-size" = 20;
        "image.cache.size" = 10485760;
        "image.mem.decode_bytes_at_a_time" = 131072;
        "image.mem.shared.unmap.min_expiration_ms" = 120000;
        "media.memory_cache_max_size" = 1048576;
        "media.memory_caches_combined_limit_kb" = 2560000;
        "media.cache_readahead_limit" = 9000;
        "media.cache_resume_threshold" = 6000;
        "media.ffmpeg.vaapi.enabled" = true;
        "media.av1.enabled" = false;
        # * BROWSER CACHE *
        "browser.cache.disk.smart_size.enabled" = false;
        "browser.cache.disk.capacity" = 1024000;
        "browser.cache.disk.max_entry_size" = 102400;
        "browser.cache.memory.max_entry_size" = 153600;
        "browser.cache.disk.metadata_memory_limit" = 1000;
        "browser.cache.memory.capacity" = 4194304;
        "browser.sessionhistory.max_total_viewers" = 2;

        # * NETWORK **
        "network.buffer.cache.size" = 262144;
        "network.buffer.cache.count" = 128;
        "network.http.max-connections" = 2400;
        "network.http.max-persistent-connections-per-server" = 10;
        "network.ssl_tokens_cache_capacity" = 32768;
        "network.http.pacing.requests.enabled" = false;
        "network.dnsCacheEntries" = 1200;
        "network.dnsCacheExpiration" = 3600;
        "network.dns.max_high_priority_threads" = 8;

        # * TRACKING PROTECTION **
        "browser.contentblocking.category" = "strict";
        "urlclassifier.trackingSkipURLs" = "*.reddit.com, *.twitter.com, *.twimg.com, *.tiktok.com, *.facebook.com, *.youtube.com, *.netflix, *.binge.com";
        "urlclassifier.features.socialtracking.skipURLs" = "*.instagram.com, *.twitter.com, *.twimg.com, *.facebook.com";
        "privacy.query_stripping.strip_list" = "__hsfp __hssc __hstc __s _hsenc _openstat dclid fbclid gbraid gclid hsCtaTracking igshid mc_eid ml_subscriber ml_subscriber_hash msclkid oft_c oft_ck oft_d oft_id oft_ids oft_k oft_lk oft_sk oly_anon_id oly_enc_id rb_clickid s_cid twclid vero_conv vero_id wbraid wickedid yclid";
        "browser.uitour.enabled" = false;
        "privacy.globalprivacycontrol.enabled" = true;
        "privacy.globalprivacycontrol.functionality.enabled" = true;

        # * OCSP & CERTS / HPKP **
        "security.OCSP.enabled" = 0;
        "security.remote_settings.crlite_filters.enabled" = true;
        "security.pki.crlite_mode" = 2;
        "security.cert_pinning.enforcement_level" = 2;

        # * SSL / TLS **
        "security.ssl.treat_unsafe_negotiation_as_broken" = true;
        "browser.xul.error_pages.expert_bad_cert" = true;
        "security.tls.enable_0rtt_data" = false;

        # * DISK AVOIDANCE **
        "browser.cache.disk.enable" = false;
        "browser.privatebrowsing.forceMediaMemoryCache" = true;
        "browser.sessionstore.privacy_level" = 2;

        # * SHUTDOWN & SANITIZING **
        "privacy.history.custom" = true;

        # * SPECULATIVE CONNECTIONS **
        "network.http.speculative-parallel-limit" = 0;
        "network.dns.disablePrefetch" = true;
        "browser.urlbar.speculativeConnect.enabled" = false;
        "browser.places.speculativeConnect.enabled" = false;
        "network.prefetch-next" = false;
        "network.predictor.enabled" = false;
        "network.predictor.enable-prefetch" = false;

        # * SEARCH / URL BAR **
        "browser.search.separatePrivateDefault.ui.enabled" = true;
        "browser.urlbar.update2.engineAliasRefresh" = true;
        "browser.search.suggest.enabled" = false;
        "browser.urlbar.suggest.quicksuggest.sponsored" = false;
        "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
        "security.insecure_connection_text.enabled" = true;
        "security.insecure_connection_text.pbmode.enabled" = true;
        "network.IDN_show_punycode" = true;

        # * HTTPS-FIRST MODE **
        "dom.security.https_first" = true;

        # * PROXY / SOCKS / IPv6 **
        "network.proxy.socks_remote_dns" = true;
        "network.file.disable_unc_paths" = true;
        "network.gio.supported-protocols" = "";

        # * ADDRESS + CREDIT CARD MANAGER **
        "extensions.formautofill.addresses.enabled" = false;
        "extensions.formautofill.creditCards.enabled" = false;
        "extensions.formautofill.heuristics.enabled" = false;
        "browser.formfill.enable" = false;

        # * MIXED CONTENT + CROSS-SITE **
        "network.auth.subresource-http-auth-allow" = 1;
        "pdfjs.enableScripting" = false;
        "extensions.postDownloadThirdPartyPrompt" = false;
        "permissions.delegation.enabled" = false;

        # * HEADERS / REFERERS **
        "network.http.referer.XOriginTrimmingPolicy" = 2;

        # * CONTAINERS **
        "privacy.userContext.ui.enabled" = true;

        # * WEBRTC **
        "media.peerconnection.ice.proxy_only_if_behind_proxy" = true;
        "media.peerconnection.ice.default_address_only" = true;

        # * SAFE BROWSING **
        "browser.safebrowsing.downloads.remote.enabled" = false;

        # * MOZILLA **
        "accessibility.force_disabled" = 1;
        #"identity.fxaccounts.enabled" = false;
        "browser.tabs.firefox-view" = false;
        "permissions.default.desktop-notification" = 2;
        "permissions.default.geo" = 2;
        "geo.provider.use_gpsd" = false; # LINUX
        "geo.provider.use_geoclue" = false; # LINUX
        "permissions.manager.defaultsUrl" = "";
        "webchannel.allowObject.urlWhitelist" = "";

        # * TELEMETRY **
        "toolkit.telemetry.unified" = false;
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.server" = "data:,";
        "toolkit.telemetry.archive.enabled" = false;
        "toolkit.telemetry.newProfilePing.enabled" = false;
        "toolkit.telemetry.shutdownPingSender.enabled" = false;
        "toolkit.telemetry.updatePing.enabled" = false;
        "toolkit.telemetry.bhrPing.enabled" = false;
        "toolkit.telemetry.firstShutdownPing.enabled" = false;
        "toolkit.telemetry.coverage.opt-out" = true;
        "toolkit.coverage.opt-out" = true;
        "datareporting.healthreport.uploadEnabled" = false;
        "datareporting.policy.dataSubmissionEnabled" = false;
        "app.shield.optoutstudies.enabled" = false;
        "browser.discovery.enabled" = false;
        "breakpad.reportURL" = "";
        "browser.tabs.crashReporting.sendReport" = false;
        "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;
        "captivedetect.canonicalURL" = "";
        "network.captive-portal-service.enabled" = false;
        "network.connectivity-service.enabled" = false;
        "default-browser-agent.enabled" = false;
        "app.normandy.enabled" = false;
        "app.normandy.api_url" = "";
        "browser.ping-centre.telemetry" = false;
        "browser.newtabpage.activity-stream.feeds.telemetry" = false;
        "browser.newtabpage.activity-stream.telemetry" = false;

        # * MOZILLA UI **
        "layout.css.prefers-color-scheme.content-override" = 0;
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "app.update.suppressPrompts" = true;
        "browser.compactmode.show" = true;
        "browser.privatebrowsing.vpnpromourl" = "";
        "extensions.getAddons.showPane" = false;
        "extensions.htmlaboutaddons.recommendations.enabled" = false;
        "browser.shell.checkDefaultBrowser" = false;
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
        "browser.preferences.moreFromMozilla" = false;
        "browser.tabs.tabmanager.enabled" = false;
        "browser.aboutwelcome.enabled" = false;
        "findbar.highlightAll" = true;
        "middlemouse.contentLoadURL" = false;
        "browser.privatebrowsing.enable-new-indicator" = false;

        # * FULLSCREEN **
        "full-screen-api.transition-duration.enter" = "0 0";
        "full-screen-api.transition-duration.leave" = "0 0";
        "full-screen-api.warning.delay" = -1;
        "full-screen-api.warning.timeout" = 0;

        # * URL BAR **
        "browser.urlbar.suggest.engines" = false;
        "browser.urlbar.suggest.topsites" = false;
        "browser.urlbar.suggest.calculator" = true;
        "browser.urlbar.unitConversion.enabled" = true;

        # * NEW TAB PAGE **
        "browser.newtabpage.activity-stream.feeds.topsites" = false;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = false;

        # ** POCKET **
        "extensions.pocket.enabled" = false;

        # * DOWNLOADS **
        "browser.download.useDownloadDir" = false;
        "browser.download.alwaysOpenPanel" = false;
        "browser.download.manager.addToRecentDocs" = false;
        "browser.download.always_ask_before_handling_new_types" = true;

        # * PDF **
        "browser.download.open_pdf_attachments_inline" = true;

        # * TAB BEHAVIOR **
        "browser.tabs.loadBookmarksInTabs" = true;
        "browser.bookmarks.openInTabClosesMenu" = false;
        "layout.css.has-selector.enabled" = true;
        "cookiebanners.service.mode" = 2;
        "cookiebanners.service.mode.privateBrowsing" = 2;

        # visit https://github.com/yokoffing/Betterfox/blob/master/Smoothfox.js
        # Enter your scrolling prefs below this line:
        "apz.overscroll.enabled" = true;
        "general.smoothScroll" = true;
        "general.smoothScroll.msdPhysics.continuousMotionMaxDeltaMS" = 12;
        "general.smoothScroll.msdPhysics.enabled" = true;
        "general.smoothScroll.msdPhysics.motionBeginSpringConstant" = 600;
        "general.smoothScroll.msdPhysics.regularSpringConstant" = 650;
        "general.smoothScroll.msdPhysics.slowdownMinDeltaMS" = 25;
        "general.smoothScroll.msdPhysics.slowdownMinDeltaRatio" = 2.0;
        "general.smoothScroll.msdPhysics.slowdownSpringConstant" = 250;
        "general.smoothScroll.currentVelocityWeighting" = 1.0;
        "general.smoothScroll.stopDecelerationWeighting" = 1.0;
        "mousewheel.default.delta_multiplier_y" = 300;
      };

      userChrome =
        # css
        ''
          @-moz-document domain(youtube.com) {
              #background, #chips-wrapper, ytd-mini-guide-entry-renderer {
                  background-color: rgba(255,255,255,.5) !important;
                  backdrop-filter: blur(20px);
              }
              body, html, ytd-app, ytd-mini-guide-renderer {
                  background-color: transparent !important;
              }
          }

          @-moz-document domain(reddit.com) {
              header {
                  background-color: rgba(255,255,255,.5) !important;
                  backdrop-filter: blur(20px);
              }
              body, html, .bg-neutral-background, .threadline, reddit-sidebar-nav, shreddit-post, aside, .reddit-search-bar, comment-body-header, shreddit-comment-tree{
                  background-color: transparent !important;
              }
          }

          @-moz-document domain(reddit.com) {
              header {
                  background-color: rgba(255,255,255,.5) !important;
                  backdrop-filter: blur(20px);
              }
              body, html, reddit-sidebar-nav, shreddit-post, aside, .reddit-search-bar{
                  background-color: transparent !important;
              }
          }

          @-moz-document domain(google.com) {
              .sfbg {
                  background-color: rgba(255,255,255,.5) !important;
                  backdrop-filter: blur(20px);
              }
              body, html, div#search > * {
                  background-color: transparent !important;
              }
              .g, .appbar {
                  background-color: transparent !important;
              }
              div#rso {
                  * {
                      background-color: transparent !important;
                  }
              }
              div#cnt > div {

              }
          }

          @-moz-document domain(github.com) {

              body, html, header, #repository-container-header, .bgColor-muted, section{
                  background-color: transparent !important;
              }
          }
                     :root {


                    /* try increasing if you encounter problems */
                    --urlbar-height-setting: 25px;
                    --tab-min-height: 25px !important;

                    /* I don't recommend you touch this unless you know what you're doing */
                    --arrowpanel-menuitem-padding: 2px !important;
                    --arrowpanel-border-radius: 0px !important;
                    --arrowpanel-menuitem-border-radius: 0px !important;
                    --toolbarbutton-border-radius: 0px !important;
                    --toolbarbutton-inner-padding: 0px 2px !important;
                    --toolbar-field-focus-background-color: var(--urlbar-focused-bg-color) !important;
                    --toolbar-field-background-color: var(--urlbar-not-focused-bg-color) !important;
                    --toolbar-field-focus-border-color: transparent !important;
                     }

                     /* --- GENERAL DEBLOAT ---------------------------------- */

                     /* Bottom left page loading status or url preview */
                     #statuspanel { display: none !important; }

                     /* Hide dropdown that appears when you type in search bar */
                     .autocomplete-history-popup, panel[type=autocomplete-richlistbox], panel[type=autocomplete] {
                    display: none !important;
                     }

                     /* remove radius from right-click popup */
                     menupopup, panel { --panel-border-radius: 0px !important; }
                     menu, menuitem, menucaption { border-radius: 0px !important; }

                     /* no stupid large buttons in right-click menu */
                     menupopup > #context-navigation { display: none !important; }
                     menupopup > #context-sep-navigation { display: none !important; }

                     /* --- DEBLOAT NAVBAR ----------------------------------- */

                     #back-button { display: none; }
                     #forward-button { display: none; }
                     #stop-button { display: none; }
                     #home-button { display: none; }
                     #library-button { display: none; }
                     #fxa-toolbar-menu-button { display: none; }
                     /* empty space before and after the url bar */
                     #customizableui-special-spring1, #customizableui-special-spring2 { display: none; }

                     /* --- STYLE NAVBAR ------------------------------------ */

                     /* remove padding between toolbar buttons */
                     toolbar .toolbarbutton-1 { padding: 0 0 !important; }

                     /* add it back to the downloads button, otherwise it's too close to the urlbar */
                     #downloads-button {
                    margin-left: 2px !important;
                     }

                     /* add padding to the right of the last button so that it doesn't touch the edge of the window */
                     #PanelUI-menu-button {
                    padding: 0px 4px 0px 0px !important;
                     }

                     #urlbar-container {
                    --urlbar-container-height: var(--urlbar-height-setting) !important;
                    margin-left: 0 !important;
                    margin-right: 0 !important;
                    padding-top: 0 !important;
                    padding-bottom: 0 !important;
                    font-family: var(--urlbar-font, 'monospace');
                    font-size: 11px;
                     }

                     #urlbar {
                    --urlbar-height: var(--urlbar-height-setting) !important;
                    --urlbar-toolbar-height: var(--urlbar-height-setting) !important;
                    min-height: var(--urlbar-height-setting) !important;
                    border-color: var(--lwt-toolbar-field-border-color, hsla(240,5%,5%,.25)) !important;
                     }

                     #urlbar-input {
                    margin-left: 0.8em !important;
                    margin-right: 0.4em !important;
                     }

                     #navigator-toolbox {
                    border: none !important;
                     }

                     /* keep pop-up menus from overlapping with navbar */
                     #widget-overflow { margin: 0 !important; }
                     #appMenu-popup { margin: 0 !important; }
                     #customizationui-widget-panel { margin: 0 !important; }
                     #unified-extensions-panel { margin: 0 !important; }

                     /* make browser dialog boxes not overlap the navbar */
                     :not(.content-prompt-dialog) > .dialogOverlay > .dialogBox:not(.spotlightBox) {
                    margin-top: 0px !important;
                     }

                     /* --- UNIFIED EXTENSIONS BUTTON ------------------------ */

                     /* make extension icons smaller */
                     #unified-extensions-view {
                    --uei-icon-size: 14px;
                     }

                     /* hide bloat */
                     .unified-extensions-item-message-deck,
                     #unified-extensions-view > .panel-header,
                     #unified-extensions-view > toolbarseparator,
                     #unified-extensions-manage-extensions {
                    display: none !important;
                     }

                     /* add 3px padding on the top and the bottom of the box */
                     .panel-subview-body {
                    padding: 3px 0px !important;
                     }

                     #unified-extensions-view .toolbarbutton-icon {
                    padding: 0 !important;
                     }

                     .unified-extensions-item-contents {
                    line-height: 1 !important;
                    white-space: nowrap !important;
                     }

                     #unified-extensions-panel .unified-extensions-item {
                    margin-block: 0 !important;
                     }

                     .toolbar-menupopup :is(menu, menuitem), .subview-subheader, panelview
                     .toolbarbutton-1, .subviewbutton, .widget-overflow-list .toolbarbutton-1 {
                    padding: 4px !important;
                     }

                     /* --- DEBLOAT URLBAR ----------------------------------- */

                     #identity-box { display: none; }
                     #pageActionButton { display: none; }
                     #pocket-button { display: none; }
                     #urlbar-zoom-button { display: none; }
                     #tracking-protection-icon-container { display: none !important; }
                     #reader-mode-button{ display: none !important; }
                     #star-button { display: none; }
                     #star-button-box:hover { background: inherit !important; }

                     /* Go to arrow button at the end of the urlbar when searching */
                     #urlbar-go-button { display: none; }

                     /* remove container indicator from urlbar */
                     #userContext-label, #userContext-indicator { display: none !important;}

                     /* --- STYLE TAB TOOLBAR -------------------------------- */

                     #titlebar {
                    --proton-tab-block-margin: 0px !important;
                    --tab-block-margin: 0px !important;
                     }

                     #TabsToolbar, .tabbrowser-tab {
                    max-height: var(--tab-min-height) !important;
                    font-size: 13px !important;
                     }

                     /* Change color of normal tabs */
                     tab:not([selected="true"]) {
                    background-color: var(--tab-inactive-bg-color) !important;
                    color: var(--identity-icon-color, var(--tab-inactive-fg-fallback-color)) !important;
                     }

                     tab {
                    font-family: var(--tab-font, monospace);
                    font-weight: bold;
                    border: none !important;
                     }
                     .tab-secondary-label { display: none !important; }

                     /* safari style tab width */
                     .tabbrowser-tab[fadein] {
                    max-width: 100vw !important;
                    border: none
                     }

                     /* Hide close button on tabs */
                     #tabbrowser-tabs .tabbrowser-tab .tab-close-button { display: none !important; }

                     /* disable favicons in tab */
                     /* .tab-icon-stack:not([pinned]) { display: none !important; } */

                     .tabbrowser-tab {
                    /* remove border between tabs */
                    padding-inline: 0px !important;
                    /* reduce fade effect of tab text */
                    --tab-label-mask-size: 1em !important;
                    /* fix pinned tab behaviour on overflow */
                    overflow-clip-margin: 0px !important;
                     }

                     /* Tab: selected colors */
                     #tabbrowser-tabs .tabbrowser-tab[selected] .tab-content {
                    background: var(--tab-active-bg-color) !important;
                    color: var(--identity-icon-color, var(--tab-active-fg-fallback-color)) !important;
                     }

                     /* Tab: hovered colors */
                     #tabbrowser-tabs .tabbrowser-tab:hover:not([selected]) .tab-content {
                    background: var(--tab-active-bg-color) !important;
                     }

                     /* hide window controls */
                     .titlebar-buttonbox-container { display: none; }

                     /* remove titlebar spacers */
                     .titlebar-spacer { display: none !important; }



                     /* disable tab shadow */
                     #tabbrowser-tabs:not([noshadowfortests]) .tab-background:is([selected], [multiselected]) {
                     box-shadow: none !important;
                     }

                     /* remove dark space between pinned tab and first non-pinned tab */
                     #tabbrowser-tabs[haspinnedtabs]:not([positionpinnedtabs]) >
                     #tabbrowser-arrowscrollbox >
                     .tabbrowser-tab:nth-child(1 of :not([pinned], [hidden])) {
                    margin-inline-start: 0px !important;
                     }

                     /* remove dropdown menu button which displays all tabs on overflow */
                     #alltabs-button { display: none !important }

                     /* fix displaying of pinned tabs on overflow */
                     #tabbrowser-tabs:not([secondarytext-unsupported]) .tab-label-container {
                    height: var(--tab-min-height) !important;
                     }

                     /* remove overflow scroll buttons */
                     #scrollbutton-up, #scrollbutton-down { display: none !important; }

                     /* hide private browsing indicator */
                     #private-browsing-indicator-with-label {
                    display: none;
                     }

                     @media (min-width: 749px) {
                     #navigator-toolbox { display: flex; flex-wrap: wrap; flex-direction: row; }
                     #nav-bar {
                     order: 1;
                     width: 450px;

                     }
                     #nav-bar #urlbar-container { min-width: 0px !important; width: auto !important; }
                     #titlebar {
                     order: 2;
                     width: calc(100vw - 451px);


                     }
                     #nav-bar{
                     max-height: 25px !important;
                    height: 25px !important;
                    min-height: 24px !important;
                     }
        '';
    };
  };
}

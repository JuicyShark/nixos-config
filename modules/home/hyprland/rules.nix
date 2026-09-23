{
  osConfig,
  config,
  commands,
  lib,
}: let
  hasApplications = osConfig.modules.desktop.applications.enable or false;
  cfg = config.modules.desktop.hyprland;
  ultrawide = cfg.sizing == "ultrawide";
  width = wide: portable:
    if ultrawide
    then wide
    else portable;
  browserWidth = width 0.3 0.8;
  socialWorkspace = "3";
  mediaWorkspace = "6";

  # Game workspace 5 is gapless. Convert the requested aspect ratio to a
  # scrolling column fraction, excluding the primary monitor's reserved bars.
  gameWidth = ratio:
    lib.generators.mkLuaInline ''
      (function()
        local m = hl.get_monitor(${builtins.toJSON cfg.primaryMonitor})
        if not m then return ${toString (width (ratio / (32.0 / 9.0)) 1.0)} end
        local r = m.reserved
        local w = m.width / m.scale - r.left - r.right
        local h = m.height / m.scale - r.top - r.bottom
        return math.min(1, h * ${toString ratio} / w)
      end)()
    '';

  tiledStrategyGame = name: class: ratio: {
    inherit name;
    match.class = class;
    workspace = "5 silent";
    tile = true;
    fullscreen_state = "0 0";
    sync_fullscreen = false;
    suppress_event = "fullscreen fullscreenoutput maximize";
    scrolling_width = gameWidth ratio;
    immediate = true;
    content = "game";
    tag = "+game";
  };

  centeredFadeRule = spec:
    spec
    // {
      float = true;
      center = true;
      animation = "fade";
    };

  pipTitle = "(Picture-in-Picture|Picture in picture|Picture-in-picture)";

  mainWorkspace = workspace:
    {
      inherit workspace;
    }
    // lib.optionalAttrs (cfg.primaryMonitor != "") {monitor = cfg.primaryMonitor;};
  persistentWorkspace = workspace: name: rule:
    mainWorkspace workspace
    // {
      default_name = name;
      persistent = true;
    }
    // rule;
  workspaceRules =
    [
      (persistentWorkspace "1" "1" {layout = "scrolling";})
      (persistentWorkspace "2" "web" {
        default = true;
        layout = "scrolling";
        on_created_empty = lib.optionalString cfg.autostartApplications commands.web;
      })
      (persistentWorkspace "3" "social" {
        layout = "scrolling";
        on_created_empty = lib.optionalString (hasApplications && cfg.autostartApplications) commands.social;
      })
      (persistentWorkspace "4" "4" {
        layout = "scrolling";
        gaps_in = 0;
        gaps_out = 0;
        no_rounding = true;
        decorate = true;
      })
      (persistentWorkspace "5" "game" {
        layout = "scrolling";
        gaps_in = 0;
        gaps_out = 0;
        no_rounding = true;
        no_shadow = true;
        decorate = false;
      })
      {
        workspace = "6";
        default_name = "media";
        persistent = true;
        layout = "scrolling";
      }
      {
        workspace = "7";
        default_name = "tv-secondary";
        persistent = true;
        layout = "scrolling";
      }
      (mainWorkspace "8")
      (mainWorkspace "9")
      (mainWorkspace "10")
      (mainWorkspace "s[true]")
    ]
    ++ lib.optional (cfg.tvMonitor != "") {
      # Follow the output, including workspaces moved there after creation.
      workspace = "m[${cfg.tvMonitor}]";
      layout = "monocle";
    };
in {
  settings = {
    workspace_rule = workspaceRules;

    layer_rule = [
      {
        name = "submap-cheatsheet";
        match.namespace = "submap-cheatsheet";
        animation = "slide bottom";
        blur = true;
      }
      {
        name = "noctalia-blur";
        match.namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|launcher.*)$";
        ignore_alpha = 0.5;
        blur = true;
        blur_popups = true;
        no_anim = true;
      }
    ];

    window_rule = [
      {
        match.class = ".*";
        suppress_event = "maximize";
      }
      {
        match.class = "com.mitchellh.ghostty";
        scrolling_width = width 0.25 0.65;
      }
      {
        match.class = "(org.qutebrowser.qutebrowser|firefox|firefox-esr|librewolf)";
        # Just under 16:9 at the usable height of the ultrawide.
        scrolling_width = browserWidth;
        suppress_event = "maximize";
      }
      {
        match.class = "(firefox|firefox-esr|librewolf)";
        sync_fullscreen = false;
      }
      {
        # Narrow, navigation-heavy apps work well as a companion column.
        match.class = "(org.gnome.Nautilus|dolphin|pcmanfm|org.keepassxc.KeePassXC|bitwarden)";
        scrolling_width = width 0.2 0.5;
      }
      {
        # Notes and IDEs need enough line length without claiming the panel.
        match.class = "(logseq|Code|code|codium|VSCodium|jetbrains-.+)";
        scrolling_width = width 0.35 0.8;
      }
      {
        match.class = "(com.obsproject.Studio|tidal-hifi)";
        scrolling_width = width 0.4 0.8;
      }
      {
        match.class = "mpv";
        scrolling_width = 0.5;
        tag = "+low-latency";
      }
      {
        # Placement is static and independent of connected displays.
        match.xdg_tag = "proton-game";
        workspace = "5 silent";
        scrolling_width = 1;
        fullscreen_state = "2 0";
        immediate = true;
        content = "game";
        suppress_event = "fullscreen fullscreenoutput maximize";
        tag = "+game";
      }
      {
        match.class = "^steam_app_[0-9]+$";
        workspace = "5 silent";
        scrolling_width = 1;
        fullscreen_state = "2 0";
        immediate = true;
        content = "game";
        suppress_event = "fullscreen fullscreenoutput maximize";
        tag = "+game";
      }
      # Override the generic Proton/Steam fullscreen policy above. Include
      # native Linux classes as well as Proton's Steam application IDs.
      (tiledStrategyGame "victoria-3-tiled" "(?i)^(victoria3([.]exe)?|steam_app_529340)$" (16.0 / 9.0))
      (tiledStrategyGame "paradox-ultrawide-tiled" "(?i)^((ck2|ck3|eu4|eu5|stellaris)([.]exe)?|Crusader Kings (II|III)|Europa Universalis (IV|V)|steam_app_(203770|1158310|236850|3450310|281990))$" (21.0 / 9.0))
      {
        match.class = "^com[.]factorio[.]Factorio$";
        workspace = "5 silent";
        scrolling_width = 0.6;
        immediate = true;
        content = "game";
        tag = "+game";
      }
      {
        match.class = "^Slay the Spire 2$";
        workspace = "5 silent";
        scrolling_width = 0.5;
        immediate = true;
        content = "game";
        tag = "+game";
      }
      {
        match.tag = "game";
        decorate = false;
        no_shadow = true;
        rounding = 0;
        border_size = 0;
        no_dim = true;
      }
      {
        # Native Wine class: include launcher dialogs without enlarging menus.
        match.class = "(?i)^battle[.]net[.]exe$";
        float = true;
        fullscreen_state = "0 0";
      }
      {
        # Proton replaces the executable class with steam_app_<shortcut id>.
        # Match the launcher title as well so launched games keep their rules.
        match = {
          class = "(?i)^(battle[.]net[.]exe|steam_app_[0-9]+)$";
          initial_title = "(?i)^Battle[.]net(.*)$";
        };
        float = true;
        fullscreen_state = "0 0";
        immediate = false;
        content = "none";
        tag = "-game";
      }
      {
        match = {
          class = "(?i)^(battle[.]net[.]exe|steam_app_[0-9]+)$";
          initial_title = "(?i)^Battle[.]net$";
        };
        size = "70% 80%";
        center = true;
      }
      {
        match.initial_title = "World of Warcraft";
        workspace = "5 silent";
        scrolling_width = 0.8;
        fullscreen_state = "0 2";
        content = "game";
        tag = "+game";
      }
      {
        match.class = "^Minecraft.*$";
        scrolling_width = 0.75;
      }
      (centeredFadeRule {
        match.class = "org.prismlauncher.PrismLauncher";
        scrolling_width = 0.15;
        size = "60% 60%";
      })
      {
        match.class = "(discord|vesktop|signal|org.telegram.desktop)";
        workspace = "${socialWorkspace} silent";
        tile = true;
        tag = "+chat";
      }
      {
        match = {
          class = "^firefox$";
          title = ".*Facebook.*";
        };
        workspace = "${socialWorkspace} silent";
        tile = true;
        tag = "+chat";
      }
      {
        # The Discord main window establishes the locked communication slot.
        # `new` also bars it from accidentally joining another nearby group.
        match = {
          class = "^discord$";
          initial_title = "^Discord$";
          float = false;
        };
        group = "new lock";
      }
      {
        # Only tiled main windows from the other communication clients may
        # bypass that lock. Floating popouts are denied by the shared rule below.
        match = {
          class = "^(vesktop|signal|org\\.telegram\\.desktop)$";
          initial_title = "^(Vesktop|Signal|Telegram.*)$";
          float = false;
        };
        group = "invade";
      }
      {
        match = {
          class = "^firefox$";
          title = ".*YouTube.*";
        };
        scrolling_width = 0.45;
        content = "video";
      }
      {
        match = {
          class = "^steam$";
          initial_title = "^Steam$";
          title = "^Steam$";
          float = false;
        };
        workspace = "5 silent";
      }
      {
        match = {
          class = "^steam$";
          initial_title = "^Friends List$";
          title = "^Friends List$";
        };
        float = true;
      }
      (centeredFadeRule {
        match.class = "^(pwvucontrol|com.saivert.pwvucontrol)$";
        size = "65% 75%";
        tag = "+dialog";
      })
      {
        match.class = "mpv";
        content = "video";
        tag = "+media";
      }
      {
        match = {
          class = "firefox";
          title = ".* - YouTube.*";
        };
        content = "video";
      }
      {
        match.title = pipTitle;
        content = "video";
        tag = "+media";
      }
      {
        match.title = pipTitle;
        tag = "+pip";
      }
      {
        match.title = pipTitle;
        tag = "+no-focus-steal";
      }
      {
        match.title = pipTitle;
        float = true;
        pin = true;
        no_initial_focus = true;
        suppress_event = "activatefocus fullscreen";
        size = "monitor_h*0.889 monitor_h*0.5";
        move = "monitor_w-monitor_h*0.889-(monitor_w*0.03) monitor_h*0.05";
      }
      (centeredFadeRule {
        match = {
          class = "xdg-desktop-portal-gtk";
          title = "(Open|Save|Save As|Open File|Choose File)";
        };
        tag = "+dialog";
      })
      (centeredFadeRule {
        match.class = "file_chooser";
        tag = "+dialog";
      })
      (centeredFadeRule {
        match = {
          class = "com.mitchellh.ghostty";
          title = "termfilechooser";
        };
        tag = "+dialog";
      })
      (centeredFadeRule {
        match.modal = true;
        pin = true;
        tag = "+dialog";
      })
      (centeredFadeRule {
        match.title = "(pinentry.*|gcr-prompter|org.gnome.keyring.SystemPrompter)";
        pin = true;
        tag = "+attention";
      })
      (centeredFadeRule {
        match = {
          class = "(polkit-gnome-authentication-agent-1|xdg-desktop-portal-gtk|polkit-kde-authentication-agent-1)";
          title = "(Authenticate|Authentication Required|Authorization Required)";
        };
        pin = true;
        tag = "+attention";
      })
      (centeredFadeRule {
        match.initial_title = "(Splash|Loading|Updating|Splash Screen)";
        no_initial_focus = true;
        suppress_event = "activatefocus";
        tag = "+dialog";
      })
      (centeredFadeRule {
        match = {
          class = "steam";
          title = ".*Controller Layout$";
        };
        tag = "+dialog";
      })
      (centeredFadeRule {
        match.class = "com.gabm.satty";
        max_size = "1400 900";
        tag = "+dialog";
      })
      {
        match.class = "(org.keepassxc.KeePassXC|bitwarden|com.obsproject.Studio)";
        tag = "+privacy";
      }
      {
        match = {
          class = "firefox";
          title = ".*Private Browsing";
        };
        tag = "+privacy";
      }
      {
        match.title = "Bitwarden";
        tag = "+dialog";
      }
      {
        match.title = "Bitwarden";
        tag = "+privacy";
      }
      {
        match.title = "Sign in - Google Accounts — Mozilla Firefox";
        float = true;
      }
      {
        match = {
          class = "steam";
          initial_title = "Steam Big Picture Mode";
        };
        fullscreen_state = "2 2";
      }
      {
        match.class = "explorer.exe";
        workspace = "special:minimized silent";
      }
      {
        match.class = "tidal-hifi";
        workspace = "${mediaWorkspace} silent";
      }
      {
        match.float = true;
        # Floating dialogs and popups should remain independent surfaces, not tabs.
        group = "deny";
        max_size = "1900 1240";
        border_size = 6;
      }
      {
        match.tag = "privacy";
        no_screen_share = true;
      }
      {
        match.tag = "attention";
        stay_focused = true;
        dim_around = true;
      }
      {
        match.tag = "pip";
        focus_on_activate = false;
        opacity = "1.0 1.0";
      }
      {
        match.tag = "media";
        no_dim = true;
      }
      {
        match.content = "video";
        border_size = 0;
      }
      {
        match.tag = "low-latency";
        immediate = true;
      }
      # Client fullscreen owns the border so it returns automatically on exit.
      {
        match.fullscreen_state_client = 2;
        border_size = 0;
      }
      {
        match.group = true;
        rounding = 0;
      }
      {
        match = {
          float = false;
          workspace = "w[tv1]";
        };
        border_size = 0;
        rounding = 0;
      }
      {
        match = {
          float = false;
          workspace = "f[1]";
        };
        border_size = 0;
        rounding = 0;
      }
    ];
  };
}

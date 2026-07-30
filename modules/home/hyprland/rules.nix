{
  cfg,
  commands,
  lib,
}: let
  primary = cfg.desktop.primary;
  monitorWorkspace = cfg.desktop.monitorWorkspace or {};
  externalWorkspaces = monitorWorkspace.workspaces or [];
  isExternalWorkspace = workspace: builtins.elem workspace externalWorkspaces;

  centeredFadeRule = spec:
    spec
    // {
      float = true;
      center = true;
      animation = "fade";
    };

  pipTitle = "(Picture-in-Picture|Picture in picture|Picture-in-picture)";

  workspaceNames = [
    "1"
    "2"
    "3"
    "4"
    "5"
    "6"
    "7"
    "8"
    "9"
    "10"
    "special:minimized"
    "special:steam"
    "special:discord"
  ];
  workspaceStartups =
    {
      "1" = commands.workspaceOne;
      "2" = commands.browser;
    }
    // lib.optionalAttrs cfg.features.applications {
      "8" = commands.music;
      "special:discord" = commands.discord;
    }
    // lib.optionalAttrs cfg.features.gaming {
      "special:steam" = commands.steam;
    }
    // lib.optionalAttrs cfg.features.zsa {
      "9" = commands.keymapp;
    };
  workspaceOverrides = {
    "1" = {
      layout = "master";
      layout_opts.orientation = "center";
      persistent = true;
    };
    "2" = {
      default = true;
      layout = "master";
      layout_opts.orientation = "center";
      persistent = true;
    };
    "3" = {
      layout = "scrolling";
      persistent = true;
    };
    "4" = {
      layout = "scrolling";
      gaps_in = 0;
      gaps_out = 0;
      no_rounding = true;
      decorate = true;
      persistent = true;
    };
    "5" = {
      layout = "scrolling";
      gaps_in = 0;
      gaps_out = 0;
      no_rounding = true;
      no_shadow = true;
      decorate = false;
      persistent = true;
    };
  };
  baseWorkspaceRule = workspace:
    {
      inherit workspace;
    }
    // lib.optionalAttrs (! isExternalWorkspace workspace) {
      monitor = primary.selector;
    }
    // lib.optionalAttrs (builtins.hasAttr workspace workspaceStartups) {
      on_created_empty = workspaceStartups.${workspace};
    }
    // (workspaceOverrides.${workspace} or {});
in {
  settings = {
    workspace_rule = map baseWorkspaceRule workspaceNames;

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
        scrolling_width = 0.3;
      }
      {
        match.class = "(org.qutebrowser.qutebrowser|chromium-browser|Chromium|google-chrome|Google-chrome|chrome|vivaldi-stable|Vivaldi-stable|firefox|firefox-esr|librewolf|brave-browser|Brave-browser|microsoft-edge|Microsoft-edge)";
        # Just under 16:9 at the usable height of the ultrawide.
        scrolling_width = 0.45;
        suppress_event = "fullscreen fullscreenoutput maximize";
      }
      {
        match.class = "emacs";
        scrolling_width = 0.4;
      }
      {
        # Narrow, navigation-heavy apps work well as a companion column.
        match.class = "(thunar|org.gnome.Nautilus|dolphin|pcmanfm|org.keepassxc.KeePassXC|bitwarden)";
        scrolling_width = 0.3;
      }
      {
        # Notes and IDEs need enough line length without claiming the panel.
        match.class = "(obsidian|logseq|Code|code|codium|VSCodium|jetbrains-.+)";
        scrolling_width = 0.4;
      }
      {
        match.class = "(com.obsproject.Studio|tidal-hifi)";
        scrolling_width = 0.5;
      }
      {
        match.class = "mpv";
        scrolling_width = 0.5;
        tag = "+low-latency";
      }
      {
        match.xdg_tag = "proton-game";
        scrolling_width = 1;
        content = "game";
        workspace = "5 silent";
        tag = "+game";
      }
      {
        match.class = "^gamescope$";
        scrolling_width = 1;
        content = "game";
        workspace = "5 silent";
        tag = "+game";
      }
      {
        match.tag = "game";
        decorate = false;
        no_shadow = true;
        rounding = 0;
        border_size = 0;
        idle_inhibit = "always";
        no_dim = true;
      }
      {
        match.class = "battle.net.exe";
        size = "2000 1200";
        float = true;
        center = true;
      }
      {
        match.initial_title = "World of Warcraft";
        suppress_event = "fullscreen";
        fullscreen = true;
      }
      {
        match.class = "^Minecraft.*$";
        scrolling_width = 0.65;
      }
      (centeredFadeRule {
        match.class = "org.prismlauncher.PrismLauncher";
        scrolling_width = 0.15;
        size = "900, 480";
      })
      {
        match.class = "(discord|vesktop|signal|org.telegram.desktop)";
        workspace = "special:discord silent";
        tile = true;
        tag = "+chat";
      }
      {
        match = {
          class = "steam";
          title = "Steam";
        };
        workspace = "special:steam silent";
        tag = "+steam-shell";
      }
      {
        match = {
          workspace = "special:discord";
          class = "negative:^(discord|vesktop|signal|org\\.telegram\\.desktop)$";
        };
        workspace = "2 silent";
      }
      {
        match = {
          workspace = "special:steam";
          class = "negative:^steam$";
        };
        workspace = "5 silent";
      }
      (centeredFadeRule {
        match.class = "^(pwvucontrol|com.saivert.pwvucontrol)$";
        size = "1000, 700";
        tag = "+dialog";
      })
      {
        match.class = "mpv";
        content = "video";
        tag = "+media";
      }
      {
        match = {
          class = "chromium-browser";
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
        match.modal = true;
        pin = true;
        tag = "+dialog";
      })
      (centeredFadeRule {
        match.title = "(Sign in - Google Accounts.*|pinentry.*|gcr-prompter|org.gnome.keyring.SystemPrompter)";
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
          class = "(chromium-browser|vivaldi-stable)";
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
        match = {
          class = "steam";
          initial_title = "Steam Big Picture Mode";
        };
        fullscreen_state = "2 2";
      }
      {
        match.class = "tidal-hifi";
        workspace = "8 silent";
      }
      {
        match.class = "explorer.exe";
        workspace = "special:minimized silent";
      }
      {
        match.float = true;
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
        idle_inhibit = "always";
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

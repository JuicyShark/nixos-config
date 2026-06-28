{
  config,
  lib,
  ...
}: let
  cfg = config.modules.terminalMultiplexers.smartFocus;
  c = config.lib.stylix.colors;

  keyNames = {
    left = "Left";
    right = "Right";
    up = "Up";
    down = "Down";
  };

  directionActions = {
    left = "L";
    right = "R";
    up = "U";
    down = "D";
  };

  tmuxModNames = {
    CTRL = "C";
    ALT = "M";
  };

  zellijModNames = {
    CTRL = "Ctrl";
    ALT = "Alt";
  };

  keyName = direction: keyNames.${cfg.keys.${direction}};
  tmuxChord = direction: "${tmuxModNames.${cfg.tmux.mod}}-${keyName direction}";
  zellijChord = direction: "${zellijModNames.${cfg.zellij.mod}} ${keyName direction}";

  mkTmuxBind = direction: ''
    bind-key -n ${tmuxChord direction} select-pane -${directionActions.${direction}}
  '';
  mkZellijBind = direction: {
    bind = {
      _args = [(zellijChord direction)];
      MoveFocus = [keyNames.${direction}];
    };
  };
  mkZellijTabBind = tab: {
    bind = {
      _args = ["${zellijModNames.${cfg.zellij.mod}} ${toString tab}"];
      GoToTab = [tab];
    };
  };

  smartFocusBindingOptions = defaultMod: {
    mod = lib.mkOption {
      type = lib.types.enum ["CTRL" "ALT"];
      default = defaultMod;
      description = "Modifier Hyprland sends to this multiplexer for smart-focus pane movement.";
    };
  };
in {
  options.modules.terminalMultiplexers.smartFocus = {
    keys = {
      left = lib.mkOption {
        type = lib.types.enum ["left" "right" "up" "down"];
        default = "left";
        description = "Terminal key sent for smart-focus left movement.";
      };
      right = lib.mkOption {
        type = lib.types.enum ["left" "right" "up" "down"];
        default = "right";
        description = "Terminal key sent for smart-focus right movement.";
      };
      up = lib.mkOption {
        type = lib.types.enum ["left" "right" "up" "down"];
        default = "up";
        description = "Terminal key sent for smart-focus up movement.";
      };
      down = lib.mkOption {
        type = lib.types.enum ["left" "right" "up" "down"];
        default = "down";
        description = "Terminal key sent for smart-focus down movement.";
      };
    };

    tmux = smartFocusBindingOptions "CTRL";
    zellij = smartFocusBindingOptions "ALT";
  };

  config = {
    programs.tmux = {
      enable = true;
      newSession = true;
      mouse = true;
      keyMode = "vi";
      terminal = "tmux-256color";
      shortcut = "a";
      escapeTime = 0;
      historyLimit = 50000;
      baseIndex = 1;
      customPaneNavigationAndResize = true;
      extraConfig = lib.mkAfter ''
        set -g renumber-windows on
        set -g set-clipboard on
        set -g focus-events on
        set -g allow-rename off
        set -g automatic-rename on
        set -g detach-on-destroy off
        set -g display-time 2500
        set -g status-interval 5
        set -g status-position bottom
        set -g status-justify left
        set -g status-style "bg=#${c.base00},fg=#${c.base05}"
        set -g message-style "bg=#${c.base0D},fg=#${c.base00},bold"
        set -g mode-style "bg=#${c.base02},fg=#${c.base06},bold"
        set -g pane-border-style "fg=#${c.base02}"
        set -g pane-active-border-style "fg=#${c.base0D}"
        set -g window-status-separator ""
        set -g window-status-format " #[fg=#${c.base04}]#I:#W#{?window_flags,#[fg=#${c.base0A}]#F,} "
        set -g window-status-current-format "#[bg=#${c.base0D},fg=#${c.base00},bold] #I:#W#{?window_flags,#F,} "
        set -g status-left-length 70
        set -g status-left "#[bg=#${c.base0B},fg=#${c.base00},bold] #S #[bg=#${c.base02},fg=#${c.base05}] win #I #[bg=#${c.base01}] pane #P "
        set -g status-right-length 140
        set -g status-right "#[fg=#${c.base0A}]prefix #{?client_prefix,ON,off} #[fg=#${c.base03}]| #[fg=#${c.base05}]C-a ? help #[fg=#${c.base03}]| #[fg=#${c.base05}]c new #[fg=#${c.base03}]| #[fg=#${c.base05}]%/\" split #[fg=#${c.base03}]| #[fg=#${c.base05}]arrows panes #[fg=#${c.base03}]| #[fg=#${c.base04}]%H:%M"

        bind-key r source-file ~/.tmux.conf \; display-message "tmux config reloaded"
        bind-key | split-window -h -c "#{pane_current_path}"
        bind-key - split-window -v -c "#{pane_current_path}"
        bind-key c new-window -c "#{pane_current_path}"
        bind-key h select-pane -L
        bind-key j select-pane -D
        bind-key k select-pane -U
        bind-key l select-pane -R
        bind-key H resize-pane -L 5
        bind-key J resize-pane -D 3
        bind-key K resize-pane -U 3
        bind-key L resize-pane -R 5

        ${lib.concatMapStrings mkTmuxBind ["left" "down" "up" "right"]}
      '';
    };

    programs.zellij = {
      enable = true;
      enableZshIntegration = false;
      attachExistingSession = false;
      settings.keybinds.shared_except = {
        _args = ["locked"];
        _children = (map mkZellijBind ["left" "down" "up" "right"]) ++ (map mkZellijTabBind [1 2 3 4 5]);
      };
      layouts = {
        dev = {
          layout = {
            _children = [
              {
                default_tab_template = {
                  _children = [
                    {
                      pane = {
                        borderless = true;
                        plugin = {
                          location = "zellij:tab-bar";
                        };
                        size = 1;
                      };
                    }
                    {
                      children = {};
                    }
                    {
                      pane = {
                        borderless = true;
                        plugin = {
                          location = "zellij:status-bar";
                        };
                        size = 2;
                      };
                    }
                  ];
                };
              }
              {
                tab = {
                  _children = [
                    {
                      pane = {
                        command = "nvim";
                      };
                    }
                  ];
                  _props = {
                    focus = true;
                    name = "Project";
                  };
                };
              }
              {
                tab = {
                  _children = [
                    {
                      pane = {
                        command = "lazygit";
                      };
                    }
                  ];
                  _props = {
                    name = "Git";
                  };
                };
              }
              {
                tab = {
                  _children = [
                    {
                      pane = {
                        command = "yazi";
                      };
                    }
                  ];
                  _props = {
                    name = "Files";
                  };
                };
              }
              {
                tab = {
                  _children = [
                    {
                      pane = {
                        command = "zsh";
                      };
                    }
                  ];
                  _props = {
                    name = "Shell";
                  };
                };
              }
            ];
          };
        };
      };
    };
  };
}

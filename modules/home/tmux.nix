{
  config,
  lib,
  ...
}: let
  cfg = config.modules.terminalMultiplexers.smartFocus;

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
  zellijFocusAction = direction:
    if direction == "left" || direction == "right"
    then "MoveFocusOrTab"
    else "MoveFocus";

  mkTmuxBind = direction: ''
    bind-key -n ${tmuxChord direction} select-pane -${directionActions.${direction}}
  '';
  mkZellijBind = direction: {
    bind = {
      _args = [(zellijChord direction)];
      ${zellijFocusAction direction} = [keyNames.${direction}];
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
      baseIndex = 1;
      customPaneNavigationAndResize = true;
      extraConfig = lib.mkAfter (lib.concatMapStrings mkTmuxBind ["left" "down" "up" "right"]);
    };

    programs.zellij = {
      enable = true;
      enableZshIntegration = true;
      attachExistingSession = true;
      settings.keybinds.shared_except = {
        _args = ["locked"];
        _children = map mkZellijBind ["left" "down" "up" "right"];
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

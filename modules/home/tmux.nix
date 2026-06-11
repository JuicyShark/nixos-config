_: {
  programs.tmux = {
    enable = true;
    newSession = true;
    mouse = true;
    keyMode = "vi";
    baseIndex = 1;
    customPaneNavigationAndResize = true;
  };
  programs.zellij = {
    enable = true;
    enableZshIntegration = true;
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
}

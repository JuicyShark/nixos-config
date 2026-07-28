{
  config,
  lib,
  ...
}: let
  cfg = config.modules.terminalMultiplexers.smartFocus;
  c =
    config.lib.stylix.colors
    or {
      base00 = "1d2021";
      base01 = "282828";
      base02 = "3c3836";
      base03 = "665c54";
      base04 = "bdae93";
      base05 = "d5c4a1";
      base06 = "ebdbb2";
      base0A = "d79921";
      base0B = "98971a";
      base0D = "458588";
    };

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

  keyName = direction: keyNames.${cfg.keys.${direction}};
  tmuxChord = direction: "${tmuxModNames.${cfg.tmux.mod}}-${keyName direction}";

  mkTmuxBind = direction: ''
    bind-key -n ${tmuxChord direction} select-pane -${directionActions.${direction}}
  '';

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
  };

  config = {
    programs.tmux = {
      enable = true;
      newSession = true;
      mouse = true;
      keyMode = "emacs";
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
        bind-key Left select-pane -L
        bind-key Down select-pane -D
        bind-key Up select-pane -U
        bind-key Right select-pane -R
        bind-key -r S-Left resize-pane -L 5
        bind-key -r S-Down resize-pane -D 3
        bind-key -r S-Up resize-pane -U 3
        bind-key -r S-Right resize-pane -R 5

        ${lib.concatMapStrings mkTmuxBind ["left" "down" "up" "right"]}
      '';
    };
  };
}

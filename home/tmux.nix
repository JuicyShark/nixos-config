{
  pkgs,
  lib,
  ...
}: let
  smartFocusAction = import ../lib/smart-focus-action.nix {inherit pkgs;};
  smartFocusActionExe = lib.getExe smartFocusAction;
  focusCommand = direction: "${smartFocusActionExe} ${direction} compositor-only";
in {
  programs.tmux = {
    enable = true;
    keyMode = "vi";
    clock24 = true;
    terminal = "tmux-256color";
    escapeTime = 0;
    historyLimit = 100000;
    baseIndex = 1;

    plugins = with pkgs.tmuxPlugins; [sensible];

    extraConfig = ''
      set -as terminal-features ',xterm-256color:RGB,screen-256color:RGB,tmux-256color:RGB'
      set -g set-clipboard on
      set -ga update-environment "DISPLAY WAYLAND_DISPLAY XDG_RUNTIME_DIR SSH_AUTH_SOCK COLORTERM TERM HYPRLAND_INSTANCE_SIGNATURE NIRI_SOCKET SMART_FOCUS_COMPOSITOR SMART_FOCUS_TERMINAL_CLASSES SMART_FOCUS_DEBUG"

      set -g mouse on
      set -g focus-events on
      set -g renumber-windows on

      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"

      bind -n C-Left if-shell -F "#{pane_at_left}" "run-shell -b '${focusCommand "l"}'" "select-pane -L"
      bind -n C-Down if-shell -F "#{pane_at_bottom}" "run-shell -b '${focusCommand "d"}'" "select-pane -D"
      bind -n C-Up if-shell -F "#{pane_at_top}" "run-shell -b '${focusCommand "u"}'" "select-pane -U"
      bind -n C-Right if-shell -F "#{pane_at_right}" "run-shell -b '${focusCommand "r"}'" "select-pane -R"
    '';
  };
}

{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}: let
  inherit (osConfig.modules.shell.atuin) syncUrl;
  atuin = lib.getExe config.programs.atuin.package;
  codex = lib.getExe pkgs.codex;
  jq = lib.getExe pkgs.jq;
  agentHook = {
    matcher = "^Bash$";
    hooks = [
      {
        type = "command";
        command = "${atuin} hook codex";
      }
    ];
  };
in {
  programs = {
    atuin = {
      enable = true;
      daemon.enable = true;
      settings =
        {
          style = "compact";
          inline_height = 18;
          search_mode = "daemon-fuzzy";
          search_mode_shell_up_key_binding = "daemon-fuzzy";
          filter_mode = "global";
          filter_mode_shell_up_key_binding = "directory";
          show_preview = false;
          show_help = false;
          show_tabs = false;
          sync_frequency = "10m";
          auto_sync = false;
          enter_accept = false;
          keymap_mode = "auto";
          daemon = {
            enabled = true;
            autostart = false;
            sync_frequency = 600;
          };
        }
        // (
          if syncUrl == ""
          then {}
          else {sync_address = syncUrl;}
        );
    };

    # Capture terminal output for `atuin_output`. This must precede Home
    # Manager's normal shell integration so the proxy owns the outer PTY.
    zsh.initContent = lib.mkOrder 100 ''
      eval "$(${atuin} pty-proxy init zsh)"
    '';
    bash.bashrcExtra = lib.mkBefore ''
      eval "$(${atuin} pty-proxy init bash)"
    '';

    mcp = {
      enable = true;
      servers.atuin = {
        command = atuin;
        args = ["mcp"];
      };
    };

    # Keep Codex's broader config user-owned; Home Manager owns only Atuin's
    # lifecycle hooks and the MCP stanza converged below.
    codex = {
      enable = true;
      package = null;
      hooks = {
        PreToolUse = [agentHook];
        PostToolUse = [agentHook];
        PostToolUseFailure = [agentHook];
      };
    };
  };

  home = {
    file = {
      ".codex/hooks.json".force = true;
    };

    activation.ensureAtuinCodexMcp = lib.hm.dag.entryAfter ["writeBoundary"] ''
      current="$(${codex} mcp get atuin --json 2>/dev/null || true)"
      if ! printf '%s' "$current" | ${jq} -e \
        --arg command ${lib.escapeShellArg atuin} \
        '.transport.type == "stdio" and .transport.command == $command and .transport.args == ["mcp"]' \
        >/dev/null 2>&1; then
        if [ -n "$current" ]; then
          run ${codex} mcp remove atuin
        fi
        run ${codex} mcp add atuin -- ${lib.escapeShellArg atuin} mcp
      fi
    '';
  };
}

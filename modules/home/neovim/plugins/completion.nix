_: {
  programs.nixvim.plugins = {
    # Blink owns LSP capabilities and the completion UI. It uses Neovim's native
    # vim.snippet engine while friendly-snippets supplies VSCode-style snippets.
    blink-cmp = {
      enable = true;
      setupLspCapabilities = true;
      settings = {
        keymap = {
          preset = "enter";
          "<C-Space>" = [
            "show"
            "show_documentation"
            "hide_documentation"
          ];
          "<C-e>" = [
            "cancel"
            "fallback"
          ];
          "<C-d>" = [
            "scroll_documentation_down"
            "fallback"
          ];
          "<C-u>" = [
            "scroll_documentation_up"
            "fallback"
          ];
        };
        appearance = {
          nerd_font_variant = "normal";
        };
        sources = {
          default = [
            "lsp"
            "path"
            "snippets"
            "buffer"
          ];
          providers = {
            buffer = {
              min_keyword_length = 3;
              score_offset = -4;
            };
            lsp = {
              fallbacks = ["buffer"];
              score_offset = 6;
            };
            path.score_offset = 3;
            snippets = {
              min_keyword_length = 2;
              score_offset = 2;
            };
          };
        };
        completion = {
          accept.auto_brackets = {
            enabled = true;
            semantic_token_resolution.enabled = false;
          };
          documentation = {
            auto_show = true;
            auto_show_delay_ms = 250;
            window.border = "rounded";
          };
          list.selection = {
            preselect = false;
            auto_insert = false;
          };
          menu = {
            border = "rounded";
            winblend = 0;
            winhighlight = "Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None";
            draw = {
              cursorline_priority = 0;
              treesitter = [];
            };
          };
        };
        signature.enabled = true;
      };
    };

    friendly-snippets.enable = true;
  };
}

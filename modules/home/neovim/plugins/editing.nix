{
  lib,
  pkgs,
  ...
}: {
  imports = [../keymaps/navigation.nix ../keymaps/buffers.nix];

  programs.nixvim = {
    plugins = {
      # Sticky scope header — useful when reading unfamiliar C/Rust source.
      treesitter-context.enable = true;

      nix.enable = true;
      treesitter = {
        enable = true;
        nixvimInjections = true;
        nixGrammars = true;
        grammarPackages = with pkgs.tree-sitter-grammars; [
          tree-sitter-nix
          tree-sitter-bash
          tree-sitter-regex
          tree-sitter-vim
          tree-sitter-norg
          tree-sitter-norg-meta
          tree-sitter-zig
          tree-sitter-rust
          tree-sitter-c
          tree-sitter-cpp
          tree-sitter-cmake
          tree-sitter-make
          tree-sitter-toml
          tree-sitter-lua
          tree-sitter-javascript
          tree-sitter-typescript
          tree-sitter-html
          tree-sitter-markdown
          tree-sitter-markdown-inline
          tree-sitter-css
          tree-sitter-json
          tree-sitter-python
          tree-sitter-ledger
          tree-sitter-godot-resource
        ];
        languageRegister = {
          norg = "norg";
          css = "css";
        };
        settings = {
          highlight.enable = true;
          incremental_selection.enable = true;
          indent.enable = false;
        };
      };

      treesitter-textobjects = {
        enable = true;
        settings = {
          select = {
            enable = true;
            lookahead = true;
            keymaps = {
              "af" = "@function.outer";
              "if" = "@function.inner";
              "ac" = "@class.outer";
              "ic" = "@class.inner";
              "aa" = "@parameter.outer";
              "ia" = "@parameter.inner";
              "ai" = "@conditional.outer";
              "ii" = "@conditional.inner";
              "al" = "@loop.outer";
              "il" = "@loop.inner";
            };
          };
          move = {
            enable = true;
            set_jumps = true;
            goto_next_start = {
              "]m" = "@function.outer";
              "]]" = "@class.outer";
              "]a" = "@parameter.inner";
            };
            goto_next_end = {
              "]M" = "@function.outer";
              "][" = "@class.outer";
            };
            goto_previous_start = {
              "[m" = "@function.outer";
              "[[" = "@class.outer";
              "[a" = "@parameter.inner";
            };
            goto_previous_end = {
              "[M" = "@function.outer";
              "[]" = "@class.outer";
            };
          };
          swap = {
            enable = true;
            swap_next = {
              "<leader>sa" = "@parameter.inner";
            };
            swap_previous = {
              "<leader>sA" = "@parameter.inner";
            };
          };
        };
      };

      mini = {
        enable = true;
        modules = {
          ai = {
            n_lines = 500;
            custom_textobjects = {
              o.__raw = "require('mini.ai').gen_spec.treesitter({ a = '@block.outer', i = '@block.inner' })";
              F.__raw = "require('mini.ai').gen_spec.treesitter({ a = '@function.outer', i = '@function.inner' })";
              C.__raw = "require('mini.ai').gen_spec.treesitter({ a = '@class.outer', i = '@class.inner' })";
            };
          };
          align = {};
          animate = {
            cursor = {
              enable = true;
              timing.__raw = ''require("mini.animate").gen_timing.linear({ duration = 125, unit = "total" })'';
            };
            scroll.enable = false;
            resize.enable = false;
            open.enable = false;
            close.enable = false;
          };
          hipatterns.highlighters.hex_color.__raw = "require('mini.hipatterns').gen_highlighter.hex_color()";
          splitjoin = {};
        };
      };

      # Project-wide replacement stays reviewable in a normal buffer and uses
      # the same ripgrep implementation as the rest of the editor workflow.
      grug-far = {
        enable = true;
        settings = {
          engine = "ripgrep";
          engines.ripgrep.path = lib.getExe pkgs.ripgrep;
        };
      };

      # Keep quickfix as a first-class editable result buffer. Trouble remains
      # the diagnostics overview, while Quicker owns qf/loclist interaction.
      quicker.enable = true;

      vim-surround.enable = true;

      nvim-autopairs = {
        enable = true;
        settings.map_cr = true;
      };

      flash = {
        enable = true;
        settings = {
          modes = {
            search.enabled = true;
            char.enabled = true;
            treesitter.enabled = true;
          };
          label = {
            uppercase = false;
            rainbow.enabled = true;
          };
        };
      };
    };
  };
}

{
  inputs,
  config,
  nixosConfig,
  pkgs,
  ...
}: let
  inherit (nixosConfig._module.specialArgs) nix-config;
  inherit (nix-config.packages.${pkgs.system}) vim-hy3-nav;
in {
  imports = [nix-config.inputs.nixvim.homeManagerModules.nixvim];
  home.packages = with pkgs; [
    alejandra
  ];
  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    vimdiffAlias = true;
    viAlias = true;
    vimAlias = true;
    withNodeJs = false;
    withRuby = false;

    globals = {
      mapleader = " ";
      maplocalleader = "<C-Space>";

      loaded_ruby_provider = 0;
      loaded_perl_provider = 0;
      loaded_python_provider = 0;
      loaded_npm_provider = 0;
    };

    opts = {
      # Folds
      foldmethod = "syntax";
      #fold = 2;
      foldminlines = 6;
      foldnestmax = 3;

      # Whitespace
      tabstop = 2;
      shiftwidth = 2;
      expandtab = true;
      autoindent = true;
      copyindent = true;

      linebreak = true;
      clipboard = "unnamedplus";
      cursorline = true;
      number = true;
      relativenumber = true;
      signcolumn = "number";

      updatetime = 300;
      termguicolors = true;
      mouse = "a";
      hidden = true;

      scrolloff = 3;

      # Misc
      swapfile = false;
    };

    opts.completeopt = ["menu" "menuone" "noselect"];
    extraPackages = with pkgs; [
      lua-language-server
      nil
      rust-analyzer
      vscode-langservers-extracted

      prettierd
      nixfmt-rfc-style
      stylua
    ];
    extraPlugins = [
      (pkgs.vimUtils.buildVimPlugin {
        name = "vim-hy3-nav";
        src = vim-hy3-nav;
      })
      pkgs.vimPlugins.neorg-telescope
    ];

    keymaps = [
      {
        # [F]ind things, mainly uses Telescope
        mode = ["n" "v"];
        key = "<leader>ff";
        action = "<cmd>Telescope find_files<CR>";
        options = {desc = "[F]ind [F]iles";};
      }
      {
        mode = ["n" "v" "i"];
        key = "<C-f>";
        action = "<cmd>Tele find_files<CR>";
        options = {
          desc = "[F]ind [F]iles";
          silent = true;
          nowait = true;
        };
      }
      {
        mode = ["n" "v" "i"];
        key = "<C-f>";
        action = "<cmd>Telescope find_files<CR>";
        options = {
          desc = "[F]ind [F]iles";
          silent = true;
          nowait = true;
        };
      }
      {
        mode = ["n" "v"];
        key = "<leader>fh";
        action = "<cmd>Telescope harpoon marks<CR>";
        options = {
          desc = "[F]ind [H]arpoons";
          silent = true;
          nowait = true;
        };
      }
      {
        mode = ["n" "v" "i"];
        key = "<C-h>";
        action = "<cmd>Telescope harpoon marks<CR>";
        options = {
          desc = "[F]ind [H]arpoons";
          silent = true;
          nowait = true;
        };
      }
      {
        mode = ["n" "v"];
        key = "<leader>fg";
        action = "<cmd>Telescope live_grep<CR>";
        options = {
          desc = "[F]ind w/ [G]rep";
          nowait = true;
        };
      }
      {
        mode = ["n" "v"];
        key = "<leader>fb";
        action = "<cmd>Telescope buffers<CR>";
        options = {
          desc = "[F]ind [B]uffers";
          nowait = true;
        };
      }
      {
        mode = ["n" "v"];
        key = "<leader>f?";
        action = "<cmd>Telescope help_tags<CR>";
        options = {
          desc = "The [F]uck[?]";
          nowait = true;
        };
      }
      {
        mode = ["n" "v"];
        key = "<leader>?";
        action = "<cmd>Telescope help_tags<CR>";
        options = {silent = true;};
      }
      {
        mode = ["n" "v"];
        key = "<leader>ft";
        action = "<cmd>TodoTrouble<CR>";
        options = {
          desc = "[F]ind [T]odo's";
          nowait = true;
        };
      }
      {
        mode = ["n" "v"];
        key = "<leader>d";
        action = "<cmd>Trouble<CR>";
        options = {
          desc = "Grep";
          nowait = true;
        };
      }
      # Git
      {
        mode = ["n" "v"];
        key = "<leader>gc";
        action = "<cmd>Neogit commit<CR>";
        options = {desc = "[G]it [C]ompete";};
      }
      # Misc
      {
        mode = "n";
        key = "<leader>.";
        action = "<cmd>NvimTreeToggle<CR>";
        options.desc = "Open Explorer";
      }
      {
        mode = ["n" "v"];
        key = "<Down>";
        options.silent = true;
        options.noremap = true;
        action = "gj";
      }
      {
        mode = ["n" "v"];
        key = "<Up>";
        options.silent = true;
        options.noremap = true;
        action = "gk";
      }

      ## [N]eorg / [N]otes Binds
      {
        mode = "n";
        key = "<leader>nt";
        action = "<cmd>Neorg journal today<CR>";
        options = {desc = "Open Journal";};
      }
      {
        mode = "n";
        key = "<leader>nn";
        action = "<Plug>(neorg.tempus.insert-date-insert-mode)";
        options = {
          #buffer = "norg";
          desc = "Insert Date";
        };
      }
    ];

    plugins = {
      web-devicons.enable = true;
      which-key = {
        enable = true;
        # show_help = true;
        settings = {
          plugins = {
            # marks = true;
            registers = true;
            presets = {
              g = true;
              motions = true;
              nav = false;
              operators = true;
              textObjects = true;
              windows = false;
              z = true;
            };
            spelling = {
              enabled = true;
              suggestions = 8;
            };
          };
          layout = {
            align = "center";
            height = {
              max = 20;
              min = 6;
            };
            width = {
              max = 75;
              min = 45;
            };
          };
          # hidden = ["<silent>" "<cmd>" "<Cmd>" "<CR>" "^:" "^ " "^call " "^lua "];
          triggersNoWait = ["`" "'" "g`" "g'" ''"'' "<c-r>" "z="];
          /*
          registrations = {
            "<leader>n" = "[N]otes";
            "<leader>f" = "[F]ind";
            "<leader>h" = "[H]arpoon that B*";
            "<leader>g" = "[G]it";
          };
          */
        };
      };
      rustaceanvim.enable = false;
      telescope = {
        enable = true;

        settings.defaults = {
          file_ignore_patterns = [
            "^.git/"
            "^.mypy_cache/"
            "^__pycache__/"
            "^output/"
            "^result/"
            "^data/"
            "%.ipynb"
          ];
          set_env.COLORTERM = "truecolor";
          pickers.find_files.hidden = true;
        };
      };
      neorg.enable = true;
      harpoon = {
        enable = false;
        enableTelescope = true;
        markBranch = true;

        keymaps = {
          addFile = "<C-a>";
          navFile = {
            "1" = "<C-1>";
            "2" = "<C-2>";
            "3" = "<C-3>";
            "4" = "<C-4>";
          };
          navNext = "<C-e>";
          navPrev = "<C-q>";
          toggleQuickMenu = "<C-w>";
        };
      };

      # TODO setup FOLKE plugins
      trouble = {
        enable = true;
        settings = {
          auto_fold = true;
          #auto_open = true;
          posistion = "bottom";
        };
      };
      # File Explorer
      nvim-tree = {
        enable = true;
        autoReloadOnWrite = true;
        autoClose = true;
        disableNetrw = true;
        hijackCursor = true;
        hijackUnnamedBufferWhenOpening = true;
        openOnSetup = true;
        openOnSetupFile = true;
      };

      noice = {
        enable = true;
        settings = {
          cmdline.view = "cmdline";

          notify = {
            enabled = false;
            view = "notify";
          };

          lsp = {
            override = {
              "cmp.entry.get_documentation" = true;
              "vim.lsp.util.convert_input_to_markdown_lines" = true;
              "vim.lsp.util.stylize_markdown" = true;
            };
            documentation = {
              opts = {
                format = ["{message}"];
                lang = "markdown";
                render = "plain";
                replace = true;
                win_options = {
                  concealcursor = "n";
                  conceallevel = 3;
                };
              };
              view = "hover";
            };
            progress = {
              enabled = true;
              format = "lsp_progress";
              formatDone = "lsp_progress";
              throttle = 1000 / 30;
              view = "mini";
            };
            message = {
              enabled = false;
              view = "notify";
            };
          };
          markdown = {
            highlights = {
              "@%S+" = "@parameter";
              "^%s*(Parameters:)" = "@text.title";
              "^%s*(Return:)" = "@text.title";
              "^%s*(See also:)" = "@text.title";
              "{%S-}" = "@parameter";
              "|%S-|" = "@text.reference";
            };
            hover = {
              "%[.-%]%((%S-)%)" = {__raw = "require('noice.util').open";};
              "|(%S-)|" = {__raw = "vim.cmd.help";};
            };
          };
          popupmenu = {
            enabled = true;
            backend = "nui";
          };
        };
      };

      headlines = {
        enable = true;
        settings.norg = {
          headline_highlights = ["Headline"];
          bullet_highlights = [
            "@neorg.headings.1.prefix"
            "@neorg.headings.2.prefix"
            "@neorg.headings.3.prefix"
            "@neorg.headings.4.prefix"
            "@neorg.headings.5.prefix"
            "@neorg.headings.6.prefix"
          ];
          bullets = ["◉" "○" "✸" "✿"];
          codeblock_highlight = "CodeBlock";
          dash_highlight = "Dash";
          dash_string = "-";
          doubledash_highlight = "DoubleDash";
          doubledash_string = "=";
          quote_highlight = "Quote";
          quote_string = "┃";
          fat_headlines = true;
          fat_headline_upper_string = "▃";
          fat_headline_lower_string = "🬂";
        };
      };
      gitsigns.enable = true;

      notify = {
        enable = false;
        settings = {
          fps = 120;
          level = "info";
          maxHeight = 42;
          maxWidth = 35;
          minimumWidth = 200;
          render = "default";
          timeout = 3750;
          topDown = true;
        };
      };
      nix.enable = true;
      illuminate.enable = true;
      treesitter = {
        enable = true;
        folding = true;
        nixvimInjections = true;
        nodejsPackage = null;
        nixGrammars = true;
        grammarPackages = with pkgs.tree-sitter-grammars; [
          tree-sitter-norg
          tree-sitter-norg-meta
          tree-sitter-zig
          tree-sitter-rust
          tree-sitter-toml
          tree-sitter-lua
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
          indent.enable = true;
        };
      };
      startup = {
        enable = true;
        theme = "dashboard";
      };
      cmp = {
        enable = true;
        autoEnableSources = true;
        settings = {
          #snippet.expand = "function(args) require('luasnip').lsp_expand(args.body) end";

          mapping = {
            "<C-d>" = "cmp.mapping.scroll_docs(-4)";
            "<C-f>" = "cmp.mapping.scroll_docs(4)";
            "<C-Space>" = "cmp.mapping.complete()";
            "<C-e>" = "cmp.mapping.close()";
            "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
            "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
            "<CR>" = "cmp.mapping.confirm({ select = true })";
          };
          sources = [
            {name = "nvim_lsp";}
            {name = "path";}
            {name = "buffer";}
            {name = "neorg";}
          ];
        };
      };
      cmp-rg.enable = true;
      cmp-nvim-lsp.enable = true;
      lsp-format.enable = true;
      # LSP
      lsp = {
        enable = true;
        keymaps = {
          silent = true;
          diagnostic = {
            # Navigate in diagnostics
            "<leader>k" = "goto_prev";
            "<leader>j" = "goto_next";
          };

          lspBuf = {
            gd = "definition";
            gD = "references";
            gt = "type_definition";
            gi = "implementation";
            K = "hover";
            "<F2>" = "rename";
          };
        };
        servers = {
          nil_ls = {
            enable = true;
            settings = {
              formatting.command = ["alejandra"];
            };
          };
          lua_ls.enable = false;
          rust_analyzer = {
            enable = true;
            filetypes = ["toml" "rs"];
            installCargo = false;
            installRustc = false;
          };
        };
      };
      lspkind = {
        enable = true;
        cmp = {
          enable = true;
          menu = {
            nvim_lsp = "[LSP]";
            nvim_lua = "[api]";
            path = "[path]";
            #   luasnip = "[snip]";
            buffer = "[buffer]";
            neorg = "[neorg]";
          };
        };
      };
      yazi.enable = true;
      vim-surround.enable = true;
      todo-comments.enable = true;
      lualine.enable = false;
      auto-save.enable = true;
      auto-save.settings.debounce_delay = 100000;

      dap.enable = true;
    };
    autoCmd = [
      {
        event = "BufWrite";
        command = "%s/\\s\\+$//e";
        desc = "Remove Whitespaces";
      }
      {
        event = "FileType";
        pattern = ["norg"];
        command = "setlocal conceallevel=1";
        desc = "Conceal Syntax Attribute";
      }
      {
        event = "FileType";
        pattern = ["norg"];
        command = "setlocal concealcursor=n";
        desc = "Conceal line when not editing";
      }
      {
        event = "FileType";
        pattern = "help";
        command = "wincmd L";
      }
    ];
  };
}

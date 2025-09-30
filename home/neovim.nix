{
  lib,
  inputs,
  config,
  osConfig,
  nixosConfig,
  pkgs,
  ...
}:
let
  inherit (nixosConfig._module.specialArgs) nix-config;
  inherit (nix-config.packages.${pkgs.system}) vim-hypr-nav;
in
{
  imports = [ nix-config.inputs.nixvim.homeModules.nixvim ];
  home.packages = with pkgs; [ nixfmt-rfc-style ];

  programs.nixvim = {
    enable = true;
    defaultEditor = lib.mkIf (
      osConfig.modules.desktop.enable == false && osConfig.modules.desktop.apps.emacs == false
    ) true;
    vimdiffAlias = true;
    viAlias = true;
    vimAlias = true;
    withNodeJs = false;
    withRuby = false;
    dependencies.nodejs.enable = false;
    globals = {
      mapleader = " ";
      maplocalleader = "<C-Space>";

      loaded_ruby_provider = 0;
      loaded_perl_provider = 0;
      loaded_python_provider = 0;
      loaded_npm_provider = 0;
    };

    opts = {
      # Code folding settings (prevent auto-folding on file open)
      foldmethod = "expr";
      foldexpr = "nvim_treesitter#foldexpr()";
      foldenable = false; # Don't fold by default when opening files
      foldlevel = 99; # Open all folds by default
      foldlevelstart = 99; # Start with all folds open

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
      signcolumn = "yes";
      updatetime = 250;

      termguicolors = true;
      mouse = "a";
      hidden = true;

      scrolloff = 3;

      # Misc
      swapfile = false;
    };

    opts.completeopt = [
      "menu"
      "menuone"
      "noselect"
    ];
    extraPackages = with pkgs; [
      lua-language-server
      nil
      rust-analyzer
      vscode-langservers-extracted

      prettierd
      nixfmt-rfc-style
      stylua
    ];
    extraConfigLua = ''
      -- Enhanced dashboard configuration to match your LazyVim setup
      require('dashboard').setup({
        theme = 'hyper',
        config = {
          week_header = {
            enable = true,
          },
          shortcut = {
            {
              desc = ' Find Files',
              group = 'Label', 
              action = 'Telescope find_files',
              key = 'f',
            },
            {
              desc = ' Recent Files',
              group = 'Number',
              action = 'Telescope oldfiles',
              key = 'r', 
            },
            {
              desc = ' Find Text',
              group = 'DiagnosticHint',
              action = 'Telescope live_grep',
              key = 'g',
            },
            {
              desc = ' Terminal',
              group = 'Function', 
              action = 'ToggleTerm direction=float',
              key = 't',
            },
            {
              desc = ' Config',
              group = 'Constant',
              action = function()
                vim.cmd('edit /mnt/smol/nixos-config')
              end,
              key = 'c',
            },
            {
              desc = ' Git Status',
              group = 'Special',
              action = 'LazyGit', 
              key = 'G',
            },
            {
              desc = ' Quit',
              group = 'Error',
              action = 'qa',
              key = 'q',
            },
          },
          footer = function()
            return {
              '⚡ NixVim loaded with Nix packages - No more Mason!',
              '📁 ' .. vim.fn.getcwd(),
            }
          end,
        },
      })
      -- Enhanced diagnostic configuration
      vim.diagnostic.config({
        virtual_text = {
          spacing = 4,
          prefix = '●',
          source = 'if_many',
        },
        float = {
          focusable = false,
          close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
          border = 'rounded',
          source = 'always',
          prefix = "",
          scope = 'cursor',
        },
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      })

      -- Auto-show diagnostic on cursor hold
      vim.api.nvim_create_autocmd({ "CursorHold" }, {
        pattern = "*",
        callback = function()
          vim.diagnostic.open_float(nil, { focus = false })
        end,
      })

      -- Auto-pairs integration with nvim-cmp
      local cmp_autopairs = require('nvim-autopairs.completion.cmp')
      local cmp = require('cmp')
      cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())
    '';
    extraPlugins = [
      (pkgs.vimUtils.buildVimPlugin {
        name = "vim-sway-nav";
        src = /home/juicy/projects/vim-hypr-nav;
      })
      pkgs.vimPlugins.neorg-telescope
    ];

    keymaps = [
      {
        mode = "n";
        key = "<A-left>";
        action = "<cmd>bprevious<cr>";
        options.desc = "Prev Buffer";
      }
      {
        mode = "n";
        key = "<A-right>";
        action = "<cmd>bnext<cr>";
        options.desc = "Next Buffer";
      }
      {
        mode = "n";
        key = "<A-h>";
        action = "<cmd>bprevious<cr>";
        options.desc = "Prev Buffer";
      }
      {
        mode = "n";
        key = "<A-l>";
        action = "<cmd>bnext<cr>";
        options.desc = "Next Buffer";
      }

      # Buffer deletion (snacks)
      {
        mode = "n";
        key = "<A-w>";
        action.__raw = "function() Snacks.bufdelete() end";
        options.desc = "Delete Buffer";
      }

      # File explorer toggle (snacks)
      {
        mode = "n";
        key = "<leader>e";
        action.__raw = "function() Snacks.explorer() end";
        options.desc = "Explorer (snacks)";
      }
      {
        mode = "n";
        key = "<leader>.";
        action.__raw = "function() Snacks.explorer() end";
        options.desc = "Explorer (snacks)";
      }
      # Window navigation with Ctrl + arrow keys
      {
        mode = "n";
        key = "<C-Left>";
        action = "<C-w>h";
        options.desc = "Go to left window";
      }
      {
        mode = "n";
        key = "<C-Down>";
        action = "<C-w>j";
        options.desc = "Go to lower window";
      }
      {
        mode = "n";
        key = "<C-Up>";
        action = "<C-w>k";
        options.desc = "Go to upper window";
      }
      {
        mode = "n";
        key = "<C-Right>";
        action = "<C-w>l";
        options.desc = "Go to right window";
      }

      # Window split with Alt-v (vertical split and move current buffer to right)
      {
        mode = "n";
        key = "<A-v>";
        action = "<cmd>vsplit<cr><C-w>l";
        options.desc = "Vertical split and move right";
      }

      # Terminal toggle (from your toggleterm config)
      {
        mode = "n";
        key = "<A-t>";
        action = "<cmd>ToggleTerm direction=float<cr>";
        options.desc = "Toggle Floating Terminal";
      }
      {
        mode = "t";
        key = "<Esc>";
        action = ''<C-\><C-N>'';
        options.desc = "Unfocus terminal";
      }
      {
        mode = "t";
        key = "<A-t>";
        action = "<cmd>ToggleTerm direction=float<cr>";
        options.desc = "Toggle terminal from terminal mode";
      }
      {
        # [F]ind things, mainly uses Telescope
        mode = [
          "n"
          "v"
        ];
        key = "<leader>ff";
        action = "<cmd>Telescope find_files<CR>";
        options = {
          desc = "[F]ind [F]iles";
        };
      }
      {
        mode = [
          "n"
          "v"
          "i"
        ];
        key = "<C-f>";
        action = "<cmd>Tele find_files<CR>";
        options = {
          desc = "[F]ind [F]iles";
          silent = true;
          nowait = true;
        };
      }
      {
        mode = [
          "n"
          "v"
          "i"
        ];
        key = "<C-f>";
        action = "<cmd>Telescope find_files<CR>";
        options = {
          desc = "[F]ind [F]iles";
          silent = true;
          nowait = true;
        };
      }

      {
        mode = [
          "n"
          "v"
        ];
        key = "<leader>fg";
        action = "<cmd>Telescope live_grep<CR>";
        options = {
          desc = "[F]ind w/ [G]rep";
          nowait = true;
        };
      }
      {
        mode = [
          "n"
          "v"
        ];
        key = "<leader>fb";
        action = "<cmd>Telescope buffers<CR>";
        options = {
          desc = "[F]ind [B]uffers";
          nowait = true;
        };
      }
      {
        mode = [
          "n"
          "v"
        ];
        key = "<leader>f?";
        action = "<cmd>Telescope help_tags<CR>";
        options = {
          desc = "The [F]uck[?]";
          nowait = true;
        };
      }
      {
        mode = [
          "n"
          "v"
        ];
        key = "<leader>?";
        action = "<cmd>Telescope help_tags<CR>";
        options = {
          silent = true;
        };
      }
      {
        mode = [
          "n"
          "v"
        ];
        key = "<leader>ft";
        action = "<cmd>TodoTrouble<CR>";
        options = {
          desc = "[F]ind [T]odo's";
          nowait = true;
        };
      }
      {
        mode = [
          "n"
          "v"
        ];
        key = "<leader>d";
        action = "<cmd>Trouble<CR>";
        options = {
          desc = "Grep";
          nowait = true;
        };
      }
      # Git
      {
        mode = [
          "n"
          "v"
        ];
        key = "<leader>gc";
        action = "<cmd>Neogit commit<CR>";
        options = {
          desc = "[G]it [C]ompete";
        };
      }
      # Misc
      {
        mode = [
          "n"
          "v"
        ];
        key = "<Down>";
        options.silent = true;
        options.noremap = true;
        action = "gj";
      }
      {
        mode = [
          "n"
          "v"
        ];
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
        options = {
          desc = "Open Journal";
        };
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
          triggersNoWait = [
            "`"
            "'"
            "g`"
            "g'"
            ''"''
            "<c-r>"
            "z="
          ];

        };
      };
      rustaceanvim.enable = false;

      # Formatting with conform (from your formatting.lua)
      conform-nvim = {
        enable = true;
        settings = {
          formatters_by_ft = {
            lua = [ "stylua" ];
            #python = [ "black" ];
          };
          formatters = {
            stylua = {
              command = "stylua";
            };
          };
        };
      };
      # Terminal (from your toggleterm.lua)
      toggleterm = {
        enable = true;
        settings = {
          hidden = true;
          start_in_insert = true;
          insert_mappings = true;
          terminal_mappings = true;
          direction = "float";
          on_open.__raw = ''
            function(term)
              vim.cmd("startinsert!")
            end
          '';
        };
      };

      telescope = {
        enable = true;
        keymaps = {
          "<leader>ff" = "find_files";
          "<leader>fg" = "live_grep";
          "<leader>fb" = "buffers";
          "<leader>fh" = "help_tags";
          "<leader>fr" = "oldfiles";
        };
        settings.defaults = {
          vimgrep_arguments = [
            "rg"
            "--color=never"
            "--no-heading"
            "--with-filename"
            "--line-number"
            "--column"
            "--smart-case"
          ];
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
          pickers.find_files = {
            find_command = [
              "fd"
              "--type"
              "f"
              "--strip-cwd-prefix"
            ];
            hidden = true;
          };
        };
      };
      neorg.enable = true;

      dashboard = {
        enable = true;
        settings = {
          theme = "hyper";
          config = {
            week_header = {
              enable = true;
            };
          };
        };
      };
      snacks = {
        enable = true;
        settings = {
          bigfile.enabled = true;
          notifier.enabled = true;
          quickfile.enabled = true;
          statuscolumn.enabled = true;
          words.enabled = true;
          explorer.enabled = true; # Enable file explorer
          image.enabled = true;
          input.enabled = true;
          picker.enabled = true;
          scroll.enabled = true;
          dim = {
            scope = {
              min_size = 5;
              max_size = 20;
              siblings = true;
            };
            animate = {
              enabled.__raw = "vim.fn.has('nvim-0.10') == 1";
              easing = "outQuad";
              duration = {
                step = 20;
                total = 300;
              };
            };
            filter.__raw = ''
              function(buf)
                return vim.g.snacks_dim ~= false and vim.b[buf].snacks_dim ~= false and vim.bo[buf].buftype == ""
              end
            '';
          };
          indent = {
            animate = {
              enabled.__raw = "vim.fn.has(\"nvim-0.10\") == 1";
              style = "out";
              easing = "linear";
              duration = {
                step = 20;
                total = 500;
              };
            };
            scope = {
              enabled = true;
              priority = 200;
              char = "|";
              underline = false;
              only_current = false;
            };
          };
        };
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
                format = [ "{message}" ];
                lang = "markdown";
                render = "plain";
                replace = true;
                win_options = {

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
              "%[.-%]%((%S-)%)" = {
                __raw = "require('noice.util').open";
              };
              "|(%S-)|" = {
                __raw = "vim.cmd.help";
              };
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
          headline_highlights = [ "Headline" ];
          bullet_highlights = [
            "@neorg.headings.1.prefix"
            "@neorg.headings.2.prefix"
            "@neorg.headings.3.prefix"
            "@neorg.headings.4.prefix"
            "@neorg.headings.5.prefix"
            "@neorg.headings.6.prefix"
          ];
          bullets = [
            "◉"
            "○"
            "✸"
            "✿"
          ];
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

      nix.enable = true;
      #illuminate.enable = true;
      treesitter = {
        enable = true;
        folding = true;
        nixvimInjections = true;
        nixGrammars = true;
        grammarPackages = with pkgs.tree-sitter-grammars; [
          tree-sitter-bash
          tree-sitter-regex
          tree-sitter-vim
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

      # Git integration
      lazygit.enable = true;
      gitsigns.enable = true;

      # UI enhancements
      lualine.enable = true;
      bufferline.enable = true;

      # Text manipulation
      vim-surround.enable = true; # vim-surround functionality
      comment.enable = true; # Smart commenting with gcc/gbc

      # Additional useful plugins
      #indent-blankline.enable = true; # Show indentation guides
      nvim-autopairs.enable = true; # Auto close brackets/quotes
      leap.enable = true; # Fast motion plugin (like easymotion)

      # Code folding
      nvim-ufo = {
        enable = true;
        settings = {
          provider_selector.__raw = ''
            function(bufnr, filetype, buftype)
              return {'treesitter', 'indent'}
            end
          '';
          open_fold_hl_timeout = 150;
          close_fold_kinds_for_ft = {
            default = { }; # Don't auto-close any folds by default
          };
        };
      };

      # Enhanced completion system with nvim-cmp
      cmp = {
        enable = true;
        settings = {
          /*
            snippet = {
              expand = ''
                function(args)
                  require('luasnip').lsp_expand(args.body)
                end
              '';
            };
          */
          mapping = {
            "<Tab>".__raw =
              "cmp.mapping(cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }), {'i', 's'})";
            "<S-Tab>".__raw =
              "cmp.mapping(cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }), {'i', 's'})";
            "<CR>".__raw = "cmp.mapping.confirm({ select = false })";
            "<C-Space>".__raw = "cmp.mapping.complete()";
            "<C-e>".__raw = "cmp.mapping.abort()";
            "<C-d>".__raw = "cmp.mapping.scroll_docs(4)";
            "<C-u>".__raw = "cmp.mapping.scroll_docs(-4)";
          };
          sources = [
            {
              name = "nvim_lsp";
              priority = 1000;
            }
            # { name = "luasnip"; priority = 750; keyword_length = 2; }
            {
              name = "buffer";
              priority = 500;
              keyword_length = 3;
            }
            {
              name = "path";
              priority = 300;
            }
            {
              name = "crates";
              priority = 400;
            } # For Rust crates
          ];
          window = {
            completion.__raw = "cmp.config.window.bordered()";
            documentation.__raw = "cmp.config.window.bordered()";
          };
          formatting = {
            fields = [
              "kind"
              "abbr"
              "menu"
            ];
            format = ''
              function(entry, vim_item)
                local kind_icons = {
                  Text = "󰉿",
                  Method = "󰆧",
                  Function = "󰊕",
                  Constructor = "",
                  Field = "󰜢",
                  Variable = "󰀫",
                  Class = "󰠱",
                  Interface = "",
                  Module = "",
                  Property = "󰜢",
                  Unit = "󰑭",
                  Value = "󰎠",
                  Enum = "",
                  Keyword = "󰌋",
                  Snippet = "",
                  Color = "󰏘",
                  File = "󰈙",
                  Reference = "󰈇",
                  Folder = "󰉋",
                  EnumMember = "",
                  Constant = "󰏿",
                  Struct = "󰙅",
                  Event = "",
                  Operator = "󰆕",
                  TypeParameter = ""
                }
                vim_item.kind = string.format('%s %s', kind_icons[vim_item.kind], vim_item.kind)
                vim_item.menu = ({
                  nvim_lsp = "[LSP]",
                  
                  buffer = "[Buffer]",
                  path = "[Path]",
                  crates = "[Crates]",
                })[entry.source.name]
                return vim_item
              end
            '';
          };
        };
      };

      cmp-rg.enable = true;
      cmp-nvim-lsp.enable = true;
      cmp-buffer.enable = true;
      cmp-path.enable = true;
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
              formatting.command = [ "nixfmt" ];
            };
          };
          lua_ls.enable = false;
          rust_analyzer = {
            enable = true;
            filetypes = [
              "toml"
              "rs"
            ];
            installCargo = false;
            installRustc = false;
          };
        };
      };
      /*
        lspkind = {
          enable = true;
          settings.cmp = {
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
      */
      #yazi.enable = true;
      #vim-surround.enable = true;
      todo-comments.enable = true;
      auto-save.enable = true;
      auto-save.settings.debounce_delay = 100000;

      dap.enable = true;
    };
  };

}

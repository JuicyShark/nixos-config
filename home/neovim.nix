{
  lib,
  config,
  osConfig,
  nixosConfig,
  pkgs,
  ...
}: let
  inherit (nixosConfig._module.specialArgs) nix-config;
in {
  imports = [nix-config.inputs.nixvim.homeModules.nixvim];
  home.packages = with pkgs; [
    nixfmt
    lsof
    glib
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor =
      lib.mkIf (
        builtins.elem "desktop" osConfig.modules.system.roles
        == false
        && builtins.elem "desktop-emacs" osConfig.modules.system.roles == false
      )
      true;
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
      loaded_python3_provider = 0;
      loaded_node_provider = 0;
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
      autoread = true;

      scrolloff = 3;
      splitright = true;
      splitbelow = true;
      ignorecase = true;
      smartcase = true;
      inccommand = "split";
      undofile = true;

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
      bash-language-server
      shellcheck
      shfmt
      tree-sitter

      prettierd
      nixfmt
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
              desc = ' Buffers',
              group = 'Function',
              action = 'Telescope buffers',
              key = 'b',
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

      -- opencode.nvim configuration
      vim.g.opencode_opts = vim.tbl_deep_extend("force", vim.g.opencode_opts or {}, {
        provider = {
          enabled = "snacks",
          terminal = {
            split = "right",
          },
          snacks = {
            win = {
              position = "right",
            },
          },
        },
      })

      vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        callback = function()
          if Snacks and Snacks.picker and Snacks.input then
            vim.ui.select = Snacks.picker.select
            vim.ui.input = Snacks.input
          end
        end,
      })

    '';
    extraPlugins = [
      pkgs.vimPlugins.neorg-telescope
      pkgs.vimPlugins.vim-tmux-navigator
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
      # Unified split movement: Ctrl+Arrow in all modes.
      {
        mode = "n";
        key = "<C-Left>";
        action = "<cmd>TmuxNavigateLeft<CR>";
        options.desc = "Focus left split";
      }
      {
        mode = "n";
        key = "<C-Down>";
        action = "<cmd>TmuxNavigateDown<CR>";
        options.desc = "Focus lower split";
      }
      {
        mode = "n";
        key = "<C-Up>";
        action = "<cmd>TmuxNavigateUp<CR>";
        options.desc = "Focus upper split";
      }
      {
        mode = "n";
        key = "<C-Right>";
        action = "<cmd>TmuxNavigateRight<CR>";
        options.desc = "Focus right split";
      }
      {
        mode = "v";
        key = "<C-Left>";
        action = "<cmd>TmuxNavigateLeft<CR>";
        options.desc = "Focus left split (visual)";
      }
      {
        mode = "v";
        key = "<C-Down>";
        action = "<cmd>TmuxNavigateDown<CR>";
        options.desc = "Focus lower split (visual)";
      }
      {
        mode = "v";
        key = "<C-Up>";
        action = "<cmd>TmuxNavigateUp<CR>";
        options.desc = "Focus upper split (visual)";
      }
      {
        mode = "v";
        key = "<C-Right>";
        action = "<cmd>TmuxNavigateRight<CR>";
        options.desc = "Focus right split (visual)";
      }
      {
        mode = "i";
        key = "<C-Left>";
        action = "<C-o><C-w>h";
        options.desc = "Focus left split (insert)";
      }
      {
        mode = "i";
        key = "<C-Down>";
        action = "<C-o><C-w>j";
        options.desc = "Focus lower split (insert)";
      }
      {
        mode = "i";
        key = "<C-Up>";
        action = "<C-o><C-w>k";
        options.desc = "Focus upper split (insert)";
      }
      {
        mode = "i";
        key = "<C-Right>";
        action = "<C-o><C-w>l";
        options.desc = "Focus right split (insert)";
      }
      {
        mode = "t";
        key = "<C-Left>";
        action = ''<C-\><C-N><C-w>h'';
        options.desc = "Focus left split (terminal)";
      }
      {
        mode = "t";
        key = "<C-Down>";
        action = ''<C-\><C-N><C-w>j'';
        options.desc = "Focus lower split (terminal)";
      }
      {
        mode = "t";
        key = "<C-Up>";
        action = ''<C-\><C-N><C-w>k'';
        options.desc = "Focus upper split (terminal)";
      }
      {
        mode = "t";
        key = "<C-Right>";
        action = ''<C-\><C-N><C-w>l'';
        options.desc = "Focus right split (terminal)";
      }

      # Tmux-only pane/window creation from Neovim
      {
        mode = "n";
        key = "<A-v>";
        action.__raw = ''
          function()
                    if vim.env.TMUX == nil or vim.env.TMUX == "" then
                      vim.notify("Tmux-only split: run Neovim inside tmux", vim.log.levels.WARN)
                      return
                    end
                    vim.fn.jobstart({ "tmux", "split-window", "-h", "-c", "#{pane_current_path}" }, { detach = true })
                  end'';
        options.desc = "Tmux split vertical";
      }
      {
        mode = "n";
        key = "<A-h>";
        action.__raw = ''
          function()
                    if vim.env.TMUX == nil or vim.env.TMUX == "" then
                      vim.notify("Tmux-only split: run Neovim inside tmux", vim.log.levels.WARN)
                      return
                    end
                    vim.fn.jobstart({ "tmux", "split-window", "-v", "-c", "#{pane_current_path}" }, { detach = true })
                  end'';
        options.desc = "Tmux split horizontal";
      }
      {
        mode = "n";
        key = "<A-n>";
        action.__raw = ''
          function()
                    if vim.env.TMUX == nil or vim.env.TMUX == "" then
                      vim.notify("Tmux-only window: run Neovim inside tmux", vim.log.levels.WARN)
                      return
                    end
                    vim.fn.jobstart({ "tmux", "new-window", "-d", "-c", "#{pane_current_path}" }, { detach = true })
                  end'';
        options.desc = "Tmux new window (detached)";
      }
      {
        mode = "n";
        key = "<C-w>v";
        action = "<A-v>";
        options.desc = "Tmux split vertical";
      }
      {
        mode = "n";
        key = "<C-w>s";
        action = "<A-h>";
        options.desc = "Tmux split horizontal";
      }
      {
        mode = "n";
        key = "<C-w>n";
        action = "<A-n>";
        options.desc = "Tmux new window";
      }

      {
        mode = "t";
        key = "<Esc>";
        action = ''<C-\><C-N>'';
        options.desc = "Unfocus terminal";
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
        mode = "n";
        key = "<leader>xx";
        action = "<cmd>Trouble diagnostics toggle<CR>";
        options = {
          desc = "Workspace diagnostics";
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
      {
        mode = [
          "n"
          "v"
        ];
        key = "<leader>oa";
        action = "<cmd>lua require('opencode').ask('@this: ', { submit = true })<cr>";
        options.desc = "OpenCode ask";
      }
      {
        mode = [
          "n"
          "v"
        ];
        key = "<leader>oo";
        action.__raw = "function() require('opencode').select() end";
        options.desc = "OpenCode select";
      }
      {
        mode = "n";
        key = "<leader>ot";
        action = "<cmd>lua require('opencode').toggle()<cr>";
        options.desc = "OpenCode toggle";
      }
      {
        mode = [
          "n"
          "v"
        ];
        key = "go";
        action.__raw = "function() return require('opencode').operator('@this ') end";
        options = {
          desc = "OpenCode add range";
          expr = true;
        };
      }
      {
        mode = "n";
        key = "goo";
        action.__raw = "function() return require('opencode').operator('@this ') .. '_' end";
        options = {
          desc = "OpenCode add line";
          expr = true;
        };
      }
      {
        mode = "n";
        key = "<S-C-u>";
        action.__raw = "function() require('opencode').command('session.half.page.up') end";
        options.desc = "OpenCode scroll up";
      }
      {
        mode = "n";
        key = "<S-C-d>";
        action.__raw = "function() require('opencode').command('session.half.page.down') end";
        options.desc = "OpenCode scroll down";
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
      opencode = {
        enable = true;
        autoLoad = true;
        setup = {
          user_commands = {
            "OpenCode" = "toggle";
          };
        };
      };
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
          format_on_save = {
            lsp_fallback = true;
            timeout_ms = 2000;
          };
          formatters_by_ft = {
            lua = ["stylua"];
            nix = ["nixfmt"];
            #python = [ "black" ];
          };
          formatters = {
            nixfmt = {
              command = "nixfmt";
            };
            stylua = {
              command = "stylua";
            };
          };
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
          image.enabled = false;
          input.enabled = true;
          picker.enabled = true;
          picker.layout = "telescope";
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
                format = ["{message}"];
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
          headline_highlights = ["Headline"];
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
        folding.enable = true;
        nixvimInjections = true;
        nixGrammars = true;
        grammarPackages = with pkgs.tree-sitter-grammars; [
          tree-sitter-bash
          tree-sitter-regex
          tree-sitter-vim
          #tree-sitter-norg
          #tree-sitter-norg-meta
          tree-sitter-zig
          tree-sitter-rust
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
          #norg = "norg";
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
            default = {}; # Don't auto-close any folds by default
          };
        };
      };

      # Enhanced completion system with nvim-cmp
      cmp = {
        enable = true;
        settings = {
          mapping = {
            "<Tab>".__raw = "cmp.mapping(cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }), {'i', 's'})";
            "<S-Tab>".__raw = "cmp.mapping(cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }), {'i', 's'})";
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
            {
              name = "luasnip";
              priority = 750;
              keyword_length = 2;
            }
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
      cmp_luasnip.enable = true;
      luasnip.enable = true;
      friendly-snippets.enable = true;
      # LSP
      lsp = {
        enable = true;
        keymaps = {
          silent = true;
          diagnostic = {
            # Navigate in diagnostics
            "<leader>k" = "goto_prev";
            "<leader>j" = "goto_next";
            "[d" = "goto_prev";
            "]d" = "goto_next";
          };

          lspBuf = {
            gd = "definition";
            gD = "references";
            gt = "type_definition";
            gi = "implementation";
            K = "hover";
            "<F2>" = "rename";
            "<leader>ca" = "code_action";
            "<leader>fm" = "format";
          };
        };
        servers = {
          nil_ls = {
            enable = true;
            settings = {
              formatting.command = ["nixfmt"];
            };
          };
          lua_ls.enable = false;
          rust_analyzer = {
            enable = true;
            filetypes = [
              "rust"
            ];
            installCargo = false;
            installRustc = false;
          };
          bashls.enable = true;
          ts_ls.enable = true;
          jsonls.enable = true;
          cssls.enable = true;
          html.enable = true;
        };
      };

      trouble.enable = true;

      godot.enable = true;
      todo-comments = {
        enable = true;
        settings = {
          keywords = {
            TODO = {
              icon = " ";
              color = "info";
              alt = [
                "WANT"
                "NEED"
                "TASK"
              ];
            };
            FIXME = {
              icon = " ";
              color = "error";
              alt = [
                "FIX"
                "BUG"
                "ISSUE"
              ];
            };
            NOTE = {
              icon = "󰏫 ";
              color = "hint";
              alt = [
                "INFO"
                "DOC"
              ];
            };
            BUG = {
              icon = " ";
              color = "error";
            };
            HACK = {
              icon = " ";
              color = "warning";
            };
          };
        };
      };
      auto-save.enable = true;
      auto-save.settings.debounce_delay = 100000;

      dap.enable = true;
    };
  };
}

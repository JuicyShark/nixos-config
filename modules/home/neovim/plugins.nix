# All plugin declarations
{pkgs, ...}: {
  programs.nixvim = {
    extraPlugins = [
      pkgs.vimPlugins.diffview-nvim
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
          spec = [
            {
              __unkeyed-1 = "<leader>f";
              group = "Find";
            }
            {
              __unkeyed-1 = "<leader>g";
              group = "Git";
            }
            {
              __unkeyed-1 = "<leader>n";
              group = "Notes";
            }
            {
              __unkeyed-1 = "<leader>r";
              group = "Run";
            }
            {
              __unkeyed-1 = "<leader>t";
              group = "Terminal";
            }
            {
              __unkeyed-1 = "<leader>x";
              group = "Trouble";
            }
            {
              __unkeyed-1 = "<leader>s";
              group = "Swap";
            }
            {
              __unkeyed-1 = "<leader>c";
              group = "Code";
            }
            {
              __unkeyed-1 = "<leader>b";
              group = "Bytes";
            }
            {
              __unkeyed-1 = "<leader>d";
              group = "Debug";
            }
            {
              __unkeyed-1 = "<leader>u";
              group = "UI toggles";
            }
          ];
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
      rustaceanvim = {
        enable = true;
        settings = {
          server = {
            default_settings = {
              rust-analyzer = {
                inlayHints = {
                  lifetimeElisionHints.enable = "always";
                  closureReturnTypeHints.enable = "always";
                  parameterHints.enable = true;
                  typeHints.enable = true;
                };
                check.command = "clippy";
                cargo.features = "all";
              };
            };
          };
        };
      };

      # Cargo.toml inline version hints / upgrade actions
      crates = {
        enable = true;
        settings = {
          completion = {
            cmp.enabled = true;
            crates.enabled = true;
          };
          lsp = {
            enabled = true;
            actions = true;
            completion = true;
            hover = true;
          };
        };
      };

      # Sticky scope header — reading unfamiliar C / Rust source
      treesitter-context.enable = true;

      # DAP UI + inline variable values
      dap-ui.enable = true;
      dap-virtual-text.enable = true;

      # Task runner + one-key compile/run/test (CMake / Make / single-file / cargo / …)
      overseer = {
        enable = true;
        settings = {
          task_list = {
            direction = "bottom";
            min_height = 12;
            max_height = 18;
            default_detail = 1;
          };
        };
      };
      compiler = {
        enable = true;
        settings = {
          close_results_on_toggle_debug = true;
        };
      };

      # Filetype-driven linters
      lint = {
        enable = true;
        lintersByFt = {
          c = ["cppcheck"];
          cpp = ["cppcheck"];
          nix = ["statix" "deadnix"];
          sh = ["shellcheck"];
          bash = ["shellcheck"];
        };
      };

      # Formatting with conform (from your formatting.lua)
      conform-nvim = {
        enable = true;
        settings = {
          format_on_save.__raw = ''
            function(bufnr)
              if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
                return
              end
              return { lsp_fallback = true, timeout_ms = 2000 }
            end
          '';
          formatters_by_ft = {
            lua = ["stylua"];
            nix = ["alejandra"];
            c = ["clang_format"];
            cpp = ["clang_format"];
            rust = ["rustfmt"];
            sh = ["shfmt"];
            bash = ["shfmt"];
            #python = [ "black" ];
          };
          formatters = {
            alejandra = {
              command = "alejandra";
            };
            stylua = {
              command = "stylua";
            };
          };
        };
      };
      telescope.enable = false;
      neorg = {
        enable = true;
        settings.load = {
          "core.defaults".__empty = null;
          "core.concealer".__empty = null;
          "core.dirman".config = {
            default_workspace = "notes";
            workspaces.notes = "~/notes";
          };
          "core.journal".config = {
            workspace = "notes";
            journal_folder = "journal";
            strategy = "nested";
          };
          "core.tempus".__empty = null;
          "core.keybinds".config.default_keybinds = false;
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
          dashboard = {
            enabled = true;
            autoshow = true;
            width = 60;
            preset = {
              keys = [
                {
                  icon = "󰈞 ";
                  key = "f";
                  desc = "Find File";
                  action.__raw = "function() Snacks.picker.files() end";
                }
                {
                  icon = "󰊄 ";
                  key = "g";
                  desc = "Grep Text";
                  action.__raw = "function() Snacks.picker.grep() end";
                }
                {
                  icon = "󰋚 ";
                  key = "r";
                  desc = "Recent Files";
                  action.__raw = "function() Snacks.picker.recent() end";
                }
                {
                  icon = "󰈔 ";
                  key = "b";
                  desc = "Buffers";
                  action.__raw = "function() Snacks.picker.buffers() end";
                }
                {
                  icon = " ";
                  key = "c";
                  desc = "Nix Config";
                  action.__raw = "function() vim.cmd('edit ' .. (vim.env.FLAKE or vim.fn.expand('~/nixos-config'))) end";
                }
                {
                  icon = "󰊢 ";
                  key = "G";
                  desc = "LazyGit";
                  action = ":LazyGit";
                }
                {
                  icon = "󰗼 ";
                  key = "q";
                  desc = "Quit";
                  action = ":qa";
                }
              ];
              header.__raw = ''
                table.concat({
                  "                                       ",
                  "  ███╗   ██╗██╗██╗  ██╗██╗   ██╗██╗███╗   ███╗ ",
                  "  ████╗  ██║██║╚██╗██╔╝██║   ██║██║████╗ ████║ ",
                  "  ██╔██╗ ██║██║ ╚███╔╝ ██║   ██║██║██╔████╔██║ ",
                  "  ██║╚██╗██║██║ ██╔██╗ ╚██╗ ██╔╝██║██║╚██╔╝██║ ",
                  "  ██║ ╚████║██║██╔╝ ██╗ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
                  "  ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
                  "                                       ",
                }, "\n")
              '';
            };
            sections = [
              {
                section = "header";
                padding = 2;
              }
              {
                section = "keys";
                gap = 1;
                padding = 1;
              }
              {
                section = "recent_files";
                title = "󰋚 Recent Files";
                limit = 5;
                padding = 1;
              }
              {
                section = "projects";
                title = " Projects";
                limit = 5;
                padding = 1;
              }
              {
                text.__raw = ''
                  (function()
                    local day = os.date("%A, %B %d %Y")
                    local time = os.date("%H:%M")
                    return "  " .. day .. "  󰥔 " .. time
                  end)()
                '';
                align = "center";
                padding = 1;
              }
            ];
          };
          explorer.enabled = true; # Enable file explorer
          image.enabled = false;
          terminal.enabled = true;
          input.enabled = true;
          picker = {
            enabled = true;
            layout = "telescope";
            sources = {
              files = {
                hidden = true;
              };
            };
            formatters = {
              file = {
                truncate = 80;
              };
            };
            win = {
              input = {
                keys = {
                  "<Esc>".__raw = "{ 'close', mode = { 'n', 'i' } }";
                };
              };
            };
          };
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
          tree-sitter-nix
          tree-sitter-bash
          tree-sitter-regex
          tree-sitter-vim
          #tree-sitter-norg
          #tree-sitter-norg-meta
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
          #norg = "norg";
          css = "css";
        };
        settings = {
          highlight.enable = true;
          incremental_selection.enable = true;
          indent.enable = true;
        };
      };

      # Treesitter text objects
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

      # Enhanced text objects
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
        };
      };

      # Git integration
      lazygit.enable = true;
      gitsigns.enable = true;

      # UI enhancements
      lualine = {
        enable = true;
        settings = {
          options = {
            globalstatus = true;
            disabled_filetypes.statusline = ["dashboard" "snacks_dashboard"];
          };
          sections = {
            lualine_a = ["mode"];
            lualine_b = ["branch" "diff" "diagnostics"];
            lualine_c = [
              {
                __unkeyed-1 = "filename";
                path = 1;
              }
            ];
            lualine_x = ["filetype"];
            lualine_y = [
              {
                __unkeyed-1.__raw = ''
                  function()
                    local clients = vim.lsp.get_clients({ bufnr = 0 })
                    if #clients == 0 then return "" end
                    local names = {}
                    for _, c in ipairs(clients) do
                      table.insert(names, c.name)
                    end
                    return " " .. table.concat(names, ",")
                  end
                '';
              }
              "progress"
            ];
            lualine_z = ["location" "selectioncount"];
          };
        };
      };
      bufferline.enable = true;

      # Text manipulation
      vim-surround.enable = true; # vim-surround functionality
      comment.enable = true; # Smart commenting with gcc/gbc

      # Additional useful plugins
      #indent-blankline.enable = true; # Show indentation guides
      nvim-autopairs.enable = true; # Auto close brackets/quotes
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
              formatting.command = ["alejandra"];
            };
          };
          lua_ls.enable = true;
          # rust-analyzer is managed by rustaceanvim; do not double-enable here.
          clangd = {
            enable = true;
            extraOptions = {
              cmd = [
                "clangd"
                "--background-index"
                "--clang-tidy"
                "--header-insertion=iwyu"
              ];
            };
          };
          bashls.enable = true;
          ts_ls = {
            enable = true;
            filetypes = [
              "javascript"
              "typescript"
              "javascriptreact"
              "typescriptreact"
            ];
          };
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
              icon = " ";
              color = "info";
              alt = [
                "WANT"
                "NEED"
                "TASK"
              ];
            };
            FIXME = {
              icon = " ";
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
              icon = " ";
              color = "error";
            };
            HACK = {
              icon = " ";
              color = "warning";
            };
          };
        };
      };
      dap.enable = true;
    };
  };
}

{pkgs, ...}: {
  programs.nixvim = {
    highlightOverride = {
      Comment = {
        italic = true;
      };
      DiagnosticFloatingError = {
        italic = true;
      };
      DiagnosticFloatingWarn = {
        italic = true;
      };
      DiagnosticFloatingInfo = {
        italic = true;
      };
      DiagnosticFloatingHint = {
        italic = true;
      };
      "@comment" = {
        italic = true;
      };
      "@lsp.type.comment" = {
        italic = true;
      };
      "@lsp.type.variable" = {
        fg = "#fb4934";
      };
      "@lsp.type.parameter" = {
        fg = "#fb4934";
      };
      "@lsp.type.property" = {
        fg = "#83a598";
      };
      "@lsp.type.function" = {
        fg = "#83a598";
      };
      "@lsp.type.method" = {
        fg = "#83a598";
      };
      "@lsp.type.macro" = {
        fg = "#83a598";
      };
      "@lsp.type.namespace" = {
        fg = "#d3869b";
      };
      "@lsp.type.type" = {
        fg = "#fabd2f";
      };
      "@lsp.type.typeParameter" = {
        fg = "#fabd2f";
      };
      "@lsp.type.enum" = {
        fg = "#fabd2f";
      };
      "@lsp.type.enumMember" = {
        fg = "#fe8019";
      };
      "@lsp.type.keyword" = {
        fg = "#d3869b";
      };
      "@lsp.type.string" = {
        fg = "#b8bb26";
      };
      "@lsp.type.number" = {
        fg = "#fe8019";
      };
      "@lsp.type.boolean" = {
        fg = "#fe8019";
      };
      "@lsp.mod.deprecated" = {
        strikethrough = true;
        italic = true;
      };
    };

    plugins = {
      web-devicons.enable = true;
      "sqlite-lua".enable = true;
      trouble.enable = true;

      which-key = {
        enable = true;
        settings = {
          plugins = {
            presets = {
              nav = false;
              windows = false;
            };
            spelling.suggestions = 8;
          };
          spec = [
            {
              __unkeyed-1 = "<leader>e";
              group = "Explorer";
            }
            {
              __unkeyed-1 = "<leader>f";
              group = "Files";
            }
            {
              __unkeyed-1 = "<leader>g";
              group = "Git";
            }
            {
              __unkeyed-1 = "<leader>h";
              group = "Help";
            }
            {
              __unkeyed-1 = "<leader>n";
              group = "Notes";
            }
            {
              __unkeyed-1 = "<leader>m";
              group = "Mode";
            }
            {
              __unkeyed-1 = "<leader>r";
              group = "Run";
            }
            {
              __unkeyed-1 = "<leader>t";
              group = "Toggles";
            }
            {
              __unkeyed-1 = "<leader>x";
              group = "Diagnostics";
            }
            {
              __unkeyed-1 = "<leader>s";
              group = "Search / Swap";
            }
            {
              __unkeyed-1 = "<leader>c";
              group = "Code";
            }
            {
              __unkeyed-1 = "<leader>b";
              group = "Buffers";
            }
            {
              __unkeyed-1 = "<leader>d";
              group = "Debug";
            }
            {
              __unkeyed-1 = "<leader>p";
              group = "Project";
            }
            {
              __unkeyed-1 = "<leader>o";
              group = "Open";
            }
            {
              __unkeyed-1 = "<leader>i";
              group = "Inspect";
            }
          ];
          layout = {
            width = {
              max = 75;
              min = 45;
            };
          };
          win.height = {
            max = 20;
            min = 6;
          };
        };
      };

      snacks = {
        enable = true;
        settings = {
          bigfile.enabled = true;
          notifier.enabled = true;
          quickfile.enabled = true;
          statuscolumn.enabled = false;
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
          explorer.enabled = true;
          image.enabled = false;
          terminal.enabled = true;
          input.enabled = true;
          picker = {
            enabled = true;
            layout = "telescope";
            db.sqlite3_path = "${pkgs.sqlite.out}/lib/libsqlite3.so";
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
              enabled = true;
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
              enabled = true;
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
              throttle = 33;
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
    };
  };
}

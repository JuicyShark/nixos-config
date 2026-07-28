{
  lib,
  pkgs,
  ...
}: {
  programs.nixvim = {
    extraPlugins = [
      pkgs.vimPlugins.otter-nvim
    ];

    diagnostic.settings = {
      virtual_text = false;
      virtual_lines.current_line = true;
      float = {
        focusable = false;
        close_events = [
          "BufLeave"
          "CursorMoved"
          "InsertEnter"
          "FocusLost"
        ];
        border = "rounded";
        source = "always";
        prefix = "";
        scope = "line";
      };
      signs = true;
      underline = true;
      update_in_insert = false;
      severity_sort = true;
    };

    lsp = {
      inlayHints.enable = true;
      onAttach = ''
        -- Keep paired ranges, such as HTML start/end tags, synchronized when
        -- the attached language server supports linked editing.
        if client:supports_method("textDocument/linkedEditingRange", bufnr) then
          vim.lsp.linked_editing_range.enable(true, {
            client_id = client.id,
          })
        end

        local prefer_treesitter = {
          basedpyright = true,
          clangd = true,
          gdscript = true,
          gopls = true,
          marksman = true,
          ruff = true,
          taplo = true,
          yamlls = true,
        }

        if prefer_treesitter[client.name] then
          vim.lsp.semantic_tokens.enable(false, {
            bufnr = bufnr,
            client_id = client.id,
          })
        end
      '';
      keymaps = [
        {
          mode = "n";
          key = "[d";
          action.__raw = "function() vim.diagnostic.jump({ count = -1, float = true }) end";
          options = {
            desc = "Previous diagnostic";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "]d";
          action.__raw = "function() vim.diagnostic.jump({ count = 1, float = true }) end";
          options = {
            desc = "Next diagnostic";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "gd";
          lspBufAction = "definition";
          options = {
            desc = "Definition";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "gD";
          lspBufAction = "references";
          options = {
            desc = "References";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "gt";
          lspBufAction = "type_definition";
          options = {
            desc = "Type definition";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "gi";
          lspBufAction = "implementation";
          options = {
            desc = "Implementation";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "k";
          lspBufAction = "hover";
          options = {
            desc = "Hover";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "K";
          lspBufAction = "hover";
          options = {
            desc = "Hover";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "<F2>";
          lspBufAction = "rename";
          options = {
            desc = "Rename";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "<leader>ca";
          lspBufAction = "code_action";
          options = {
            desc = "Code action";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "<leader>cf";
          lspBufAction = "format";
          options = {
            desc = "Format";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "<leader>cr";
          lspBufAction = "rename";
          options = {
            desc = "Rename";
            silent = true;
          };
        }
      ];
    };

    userCommands = {
      NixLuaOtter = {
        command.__raw = ''
          function()
            local ok, otter = pcall(require, "otter")
            if not ok then
              vim.notify("otter.nvim is not available", vim.log.levels.ERROR)
              return
            end
            otter.activate({ "lua" }, true, true)
            vim.notify("Embedded Lua LSP activated for this buffer")
          end
        '';
        desc = "Activate Lua LSP for embedded Lua";
      };
    };

    plugins = {
      lint = {
        enable = true;
        autoCmd = {
          event = [
            "BufWritePost"
            "BufReadPost"
            "InsertLeave"
          ];
        };
        lintersByFt = {
          c = ["cppcheck"];
          cpp = ["cppcheck"];
          gdscript = ["gdlint"];
          nix = ["statix" "deadnix"];
          python = ["ruff"];
          sh = ["shellcheck"];
          bash = ["shellcheck"];
        };
      };

      conform-nvim = {
        enable = true;
        settings = {
          format_on_save.__raw = ''
            function(bufnr)
              if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
                return
              end
              return { lsp_format = "fallback", timeout_ms = 2000 }
            end
          '';
          formatters_by_ft = {
            lua = ["stylua"];
            nix = ["alejandra"];
            c = ["clang_format"];
            cpp = ["clang_format"];
            css = ["prettierd"];
            gdscript = ["gdformat"];
            go = ["gofmt" "goimports"];
            html = ["prettierd"];
            javascript = ["prettierd"];
            javascriptreact = ["prettierd"];
            json = ["prettierd"];
            jsonc = ["prettierd"];
            markdown = ["prettierd"];
            python = ["ruff_format" "ruff_organize_imports"];
            rust = ["rustfmt"];
            sh = ["shfmt"];
            bash = ["shfmt"];
            toml = ["taplo"];
            typescript = ["prettierd"];
            typescriptreact = ["prettierd"];
            yaml = ["prettierd"];
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

      crates = {
        enable = true;
        settings = {
          lsp = {
            enabled = true;
            actions = true;
            completion = true;
            hover = true;
          };
        };
      };

      lsp = {
        enable = true;
        servers = {
          nixd = {
            enable = true;
            package = pkgs.nixd;
            rootMarkers = [
              "flake.nix"
              ".git"
            ];
            settings = {
              formatting.command = ["alejandra"];
              nixpkgs.expr = "import (builtins.getFlake (builtins.toString ./.)).inputs.nixpkgs { }";
              options = {
                darwin.expr = "(builtins.getFlake (builtins.toString ./.)).darwinConfigurations.mac.options";
                home-manager.expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.leo.options.home-manager.users.type.getSubOptions []";
                leo.expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.leo.options";
                zues.expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.zues.options";
              };
            };
          };
          lua_ls.enable = true;
          # rust-analyzer is managed by rustaceanvim; do not double-enable here.
          basedpyright = {
            enable = true;
            settings.basedpyright.analysis = {
              autoImportCompletions = true;
              diagnosticMode = "workspace";
              typeCheckingMode = "standard";
            };
          };
          ruff = {
            enable = true;
            settings = {
              lineLength = 100;
              lint.enable = true;
            };
          };
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
          gopls = {
            enable = true;
            settings.gopls = {
              analyses = {
                shadow = true;
                unreachable = true;
                unusedparams = true;
              };
              gofumpt = true;
              staticcheck = true;
            };
          };
          ts_ls = {
            enable = true;
            filetypes = lib.mkForce [
              "javascript"
              "javascriptreact"
              "typescript"
              "typescriptreact"
            ];
          };
          jsonls.enable = true;
          cssls.enable = true;
          html.enable = true;
          marksman.enable = true;
          yamlls.enable = true;
          taplo.enable = true;
          gdscript = {
            enable = true;
            package = null;
          };
        };
      };

      godot.enable = true;
    };
  };
}

{
  lib,
  pkgs,
  ...
}: let
  fullDev = pkgs.stdenv.hostPlatform.isLinux;
in {
  imports = [../keymaps/code.nix];

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
          c = lib.optionals fullDev ["cppcheck"];
          cpp = lib.optionals fullDev ["cppcheck"];
          gdscript = lib.optionals fullDev ["gdlint"];
          nix = ["statix" "deadnix"];
          sh = ["shellcheck"];
          bash = ["shellcheck"];
        };
      };

      crates = {
        enable = fullDev;
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
              nixpkgs.expr = "import ${pkgs.path} { }";
            };
            extraOptions.on_init.__raw = ''
              function(client)
                require("juicy.project").configure_nixd(client)
              end
            '';
          };
          lua_ls.enable = true;
          # rust-analyzer is managed by rustaceanvim; do not double-enable here.
          basedpyright = {
            enable = fullDev;
            settings.basedpyright.analysis = {
              autoImportCompletions = true;
              diagnosticMode = "workspace";
              typeCheckingMode = "standard";
            };
          };
          ruff = {
            enable = fullDev;
            settings = {
              lineLength = 100;
              lint.enable = true;
            };
          };
          clangd = {
            enable = fullDev;
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
            enable = fullDev;
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
            enable = fullDev;
            filetypes = lib.mkForce [
              "javascript"
              "javascriptreact"
              "typescript"
              "typescriptreact"
            ];
          };
          jsonls.enable = fullDev;
          cssls.enable = fullDev;
          html.enable = fullDev;
          marksman.enable = true;
          yamlls.enable = true;
          taplo.enable = true;
          gdscript = {
            enable = fullDev;
            package = null;
          };
        };
      };

      godot.enable = fullDev;
    };
  };
}

{
  lib,
  pkgs,
  ...
}: let
  codelldbAdapter = "${pkgs.vscode-extensions.vadimcn.vscode-lldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb";
in {
  imports = [../keymaps/rust.nix];

  programs.nixvim = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    keymaps = [
      {
        mode = "n";
        key = "<F5>";
        action.__raw = "function() require('dap').continue() end";
        options.desc = "DAP continue / start";
      }
      {
        mode = "n";
        key = "<F10>";
        action.__raw = "function() require('dap').step_over() end";
        options.desc = "DAP step over";
      }
      {
        mode = "n";
        key = "<F11>";
        action.__raw = "function() require('dap').step_into() end";
        options.desc = "DAP step into";
      }
      {
        mode = "n";
        key = "<S-F11>";
        action.__raw = "function() require('dap').step_out() end";
        options.desc = "DAP step out";
      }
      {
        mode = "n";
        key = "<leader>db";
        action.__raw = "function() require('dap').toggle_breakpoint() end";
        options.desc = "Toggle breakpoint";
      }
      {
        mode = "n";
        key = "<leader>dB";
        action.__raw = "function() require('dap').set_breakpoint(vim.fn.input('Condition: ')) end";
        options.desc = "Conditional breakpoint";
      }
      {
        mode = "n";
        key = "<leader>du";
        action.__raw = "function() require('dapui').toggle() end";
        options.desc = "Toggle DAP UI";
      }
      {
        mode = "n";
        key = "<leader>dr";
        action.__raw = "function() require('dap').repl.toggle() end";
        options.desc = "Toggle DAP REPL";
      }
      {
        mode = "n";
        key = "<leader>dq";
        action.__raw = "function() require('dap').terminate() end";
        options.desc = "Terminate session";
      }
    ];

    extraConfigLua = ''
      do
        local dap = require("dap")
        local dapui = require("dapui")

        dap.listeners.before.attach.juicy_dapui = function()
          dapui.open()
        end
        dap.listeners.before.launch.juicy_dapui = function()
          dapui.open()
        end
        dap.listeners.before.event_terminated.juicy_dapui = function()
          dapui.close()
        end
        dap.listeners.before.event_exited.juicy_dapui = function()
          dapui.close()
        end
      end
    '';

    extraPackages = [
      (pkgs.writeShellScriptBin "codelldb" ''
        exec ${codelldbAdapter} "$@"
      '')
    ];

    plugins = {
      rustaceanvim = {
        enable = true;
        settings = {
          dap.adapter = {
            type = "server";
            host = "127.0.0.1";
            port = "\${port}";
            executable = {
              command = codelldbAdapter;
              args = [
                "--port"
                "\${port}"
              ];
            };
          };
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

      dap = {
        enable = true;
        adapters.servers.codelldb = {
          host = "127.0.0.1";
          port = "\${port}";
          executable = {
            command = codelldbAdapter;
            args = [
              "--port"
              "\${port}"
            ];
          };
        };
        configurations = let
          codelldbLaunch = {
            name = "Launch (codelldb)";
            type = "codelldb";
            request = "launch";
            program.__raw = ''
              function()
                return vim.fn.input("exe> ", vim.fn.getcwd() .. "/", "file")
              end
            '';
            cwd = "\${workspaceFolder}";
            stopOnEntry = false;
            args = [];
          };
        in {
          c = [codelldbLaunch];
          cpp = [codelldbLaunch];
          rust = [codelldbLaunch];
        };
      };
      dap-ui.enable = true;
      dap-virtual-text.enable = true;
    };
  };
}

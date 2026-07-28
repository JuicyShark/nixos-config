{pkgs, ...}: let
  codelldbAdapter = "${pkgs.vscode-extensions.vadimcn.vscode-lldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb";
in {
  programs.nixvim = {
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

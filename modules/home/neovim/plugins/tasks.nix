{pkgs, ...}: {
  imports = [../keymaps/run.nix ../keymaps/inspect.nix];

  programs.nixvim.keymaps = [
    {
      mode = "n";
      key = "<leader>aa";
      action.__raw = ''function() require("sidekick.cli").toggle({ name = "codex", focus = true }) end'';
      options.desc = "Toggle Codex";
    }
    {
      mode = "n";
      key = "<leader>as";
      action.__raw = ''function() require("sidekick.cli").select({ filter = { installed = true } }) end'';
      options.desc = "Select coding agent";
    }
    {
      mode = ["n" "x"];
      key = "<leader>at";
      action.__raw = ''function() require("sidekick.cli").send({ msg = "{this}" }) end'';
      options.desc = "Send context to agent";
    }
    {
      mode = ["n" "x"];
      key = "<leader>ap";
      action.__raw = ''function() require("sidekick.cli").prompt() end'';
      options.desc = "Select agent prompt";
    }
  ];

  programs.nixvim = {
    userCommands = {
      Hexdump = {
        command = "%!xxd";
        desc = "Convert buffer to xxd hexdump";
      };
      HexdumpUndo = {
        command = "%!xxd -r";
        desc = "Convert xxd hexdump back to binary";
      };
      Disasm = {
        command.__raw = ''
          function(opts)
            local f = opts.args ~= "" and opts.args or vim.fn.expand("%:p")
            Snacks.terminal("objdump -d -M intel " .. vim.fn.shellescape(f) .. " | less -R", {
              win = { position = "bottom", height = 0.4 },
              cwd = vim.fn.getcwd(),
              interactive = true,
            })
          end
        '';
        nargs = "?";
        complete = "file";
        desc = "Disassemble file with objdump";
      };
      Strings = {
        command.__raw = ''
          function(opts)
            local f = opts.args ~= "" and opts.args or vim.fn.expand("%:p")
            Snacks.terminal("strings " .. vim.fn.shellescape(f) .. " | less", {
              win = { position = "bottom", height = 0.4 },
              cwd = vim.fn.getcwd(),
              interactive = true,
            })
          end
        '';
        nargs = "?";
        complete = "file";
        desc = "Show printable strings in file";
      };
      NixDrv = {
        command.__raw = ''
          function()
            Snacks.terminal("nix derivation show .# | jq . | less -R", {
              win = { position = "bottom", height = 0.4 },
              cwd = vim.fn.getcwd(),
              interactive = true,
            })
          end
        '';
        desc = "Inspect current flake derivation";
      };
    };

    plugins = {
      # The coding-agent terminal is useful without a Copilot subscription;
      # NES stays off until a Copilot LSP is explicitly configured.
      sidekick = {
        enable = true;
        # Nixpkgs adds Copilot's unfree language server as an unconditional
        # runtime dependency. This setup only uses Sidekick's CLI integration.
        package = pkgs.vimPlugins.sidekick-nvim.overrideAttrs (_: {
          runtimeDeps = [];
        });
        settings = {
          nes.enabled = false;
          cli = {
            picker = "snacks";
            mux = {
              enabled = true;
              backend = "zellij";
            };
            tools.codex = {};
          };
        };
      };

      overseer = {
        enable = true;
        settings = {
          dap = pkgs.stdenv.hostPlatform.isLinux;
          task_list = {
            direction = "bottom";
            min_height = 12;
            max_height = 18;
            default_detail = 1;
          };
        };
      };
    };
  };
}

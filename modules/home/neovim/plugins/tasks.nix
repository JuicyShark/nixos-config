_: {
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
      overseer = {
        enable = true;
        settings = {
          dap = true;
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

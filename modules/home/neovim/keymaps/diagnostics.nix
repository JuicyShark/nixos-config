_: {
  programs.nixvim.keymaps = [
    {
      mode = "n";
      key = "gl";
      action.__raw = "function() vim.diagnostic.open_float(nil, { border = 'rounded', focus = false, scope = 'line', source = 'always' }) end";
      options.desc = "Line diagnostics";
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
      mode = "n";
      key = "<leader>xX";
      action = "<cmd>Trouble diagnostics toggle filter.buf=0<CR>";
      options = {
        desc = "Buffer diagnostics";
        nowait = true;
      };
    }
    {
      mode = "n";
      key = "<leader>xd";
      action.__raw = "function() Snacks.picker.diagnostics() end";
      options.desc = "Diagnostics picker";
    }
    {
      mode = "n";
      key = "<leader>xD";
      action.__raw = "function() Snacks.picker.diagnostics_buffer() end";
      options.desc = "Buffer diagnostics picker";
    }
    {
      mode = "n";
      key = "<leader>xq";
      action = "<cmd>Trouble qflist toggle<CR>";
      options = {
        desc = "Quickfix list";
        nowait = true;
      };
    }
    {
      mode = "n";
      key = "<leader>xl";
      action = "<cmd>Trouble loclist toggle<CR>";
      options = {
        desc = "Location list";
        nowait = true;
      };
    }
    {
      mode = ["n" "v"];
      key = "<leader>xt";
      action = "<cmd>Trouble<CR>";
      options = {
        desc = "Trouble toggle";
        nowait = true;
      };
    }
    {
      mode = "n";
      key = "]q";
      action = "<cmd>cnext<CR>";
      options.desc = "Next quickfix";
    }
    {
      mode = "n";
      key = "[q";
      action = "<cmd>cprev<CR>";
      options.desc = "Prev quickfix";
    }
    {
      mode = "n";
      key = "]Q";
      action = "<cmd>clast<CR>";
      options.desc = "Last quickfix";
    }
    {
      mode = "n";
      key = "[Q";
      action = "<cmd>cfirst<CR>";
      options.desc = "First quickfix";
    }
  ];
}

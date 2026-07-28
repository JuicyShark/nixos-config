_: {
  programs.nixvim.keymaps = [
    {
      mode = "n";
      key = "<A-left>";
      action = "<cmd>bprevious<CR>";
      options.desc = "Prev buffer";
    }
    {
      mode = "n";
      key = "<A-right>";
      action = "<cmd>bnext<CR>";
      options.desc = "Next buffer";
    }
    {
      mode = "n";
      key = "<A-w>";
      action.__raw = "function() Snacks.bufdelete() end";
      options.desc = "Delete buffer";
    }
    {
      mode = ["n" "v"];
      key = "<leader>bb";
      action.__raw = "function() Snacks.picker.buffers() end";
      options.desc = "Switch buffer";
    }
    {
      mode = "n";
      key = "<leader>bd";
      action.__raw = "function() Snacks.bufdelete() end";
      options.desc = "Delete buffer";
    }
    {
      mode = "n";
      key = "<leader>bo";
      action.__raw = "function() Snacks.bufdelete.other() end";
      options.desc = "Close other buffers";
    }
    {
      mode = "n";
      key = "<leader>bn";
      action = "<cmd>bnext<CR>";
      options.desc = "Next buffer";
    }
    {
      mode = "n";
      key = "<leader>bp";
      action = "<cmd>bprevious<CR>";
      options.desc = "Previous buffer";
    }
  ];
}

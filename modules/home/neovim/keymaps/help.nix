_: {
  programs.nixvim.keymaps = [
    {
      mode = "n";
      key = "<leader>hk";
      action = "<cmd>NeovimIdeReference<CR>";
      options.desc = "Active keyboard reference";
    }
    {
      mode = "n";
      key = "<leader>h";
      action.__raw = ''function() require("which-key").show({ keys = "<leader>h" }) end'';
      options.desc = "Help";
    }
    {
      mode = ["n" "v"];
      key = "<leader>hh";
      action.__raw = "function() Snacks.picker.help() end";
      options.desc = "Help tags";
    }
    {
      mode = ["n" "v"];
      key = "<leader>h?";
      action.__raw = "function() Snacks.picker.help() end";
      options.desc = "Help tags";
    }
    {
      mode = ["n" "v"];
      key = "<leader>?";
      action.__raw = "function() Snacks.picker.help() end";
      options = {
        desc = "Help tags";
        silent = true;
      };
    }
  ];
}

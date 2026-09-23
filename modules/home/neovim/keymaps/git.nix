_: {
  programs.nixvim.keymaps = [
    {
      mode = "n";
      key = "]h";
      action.__raw = ''function() require("gitsigns").nav_hunk("next") end'';
      options.desc = "Next Git hunk";
    }
    {
      mode = "n";
      key = "[h";
      action.__raw = ''function() require("gitsigns").nav_hunk("prev") end'';
      options.desc = "Previous Git hunk";
    }
    {
      mode = "n";
      key = "<leader>gp";
      action.__raw = ''function() require("gitsigns").preview_hunk() end'';
      options.desc = "Preview Git hunk";
    }
    {
      mode = "n";
      key = "<leader>gs";
      action.__raw = ''function() require("gitsigns").stage_hunk() end'';
      options.desc = "Stage Git hunk";
    }
    {
      mode = "n";
      key = "<leader>gr";
      action.__raw = ''function() require("gitsigns").reset_hunk() end'';
      options.desc = "Reset Git hunk";
    }
    {
      mode = "n";
      key = "<leader>gb";
      action.__raw = ''function() require("gitsigns").blame_line({ full = true }) end'';
      options.desc = "Blame current line";
    }
    {
      mode = ["n" "v"];
      key = "<leader>gc";
      action = "<cmd>LazyGit<CR>";
      options.desc = "LazyGit";
    }
    {
      mode = "n";
      key = "<leader>gd";
      action = "<cmd>DiffviewOpen<CR>";
      options.desc = "Diffview open";
    }
    {
      mode = "n";
      key = "<leader>gh";
      action = "<cmd>DiffviewFileHistory %<CR>";
      options.desc = "File history";
    }
    {
      mode = "n";
      key = "<leader>gq";
      action = "<cmd>DiffviewClose<CR>";
      options.desc = "Diffview close";
    }
  ];
}

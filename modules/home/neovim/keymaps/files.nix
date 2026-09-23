_: {
  programs.nixvim.keymaps = [
    {
      mode = "n";
      key = "<leader>e";
      action.__raw = "function() Snacks.explorer() end";
      options.desc = "Explorer";
    }
    {
      mode = "n";
      key = "<leader>.";
      action.__raw = "function() Snacks.explorer() end";
      options.desc = "Explorer";
    }
    {
      mode = ["n" "v"];
      key = "<leader>ff";
      action.__raw = "function() Snacks.picker.files({ cwd = vim.fn.getcwd(), title = 'Files: current directory' }) end";
      options.desc = "Find files";
    }
    {
      mode = ["n" "v"];
      key = "<C-f>";
      action.__raw = "function() Snacks.picker.files({ cwd = vim.fn.getcwd(), title = 'Files: current directory' }) end";
      options = {
        desc = "Find files";
        silent = true;
        nowait = true;
      };
    }
    {
      mode = ["n" "v"];
      key = "<leader>fg";
      action.__raw = "function() Snacks.picker.grep({ cwd = vim.fn.getcwd(), title = 'Search: current directory' }) end";
      options.desc = "Live grep";
    }
    {
      mode = ["n" "v"];
      key = "<leader>fb";
      action.__raw = "function() Snacks.picker.buffers() end";
      options.desc = "Find buffers";
    }
    {
      mode = ["n" "v"];
      key = "<leader>fr";
      action.__raw = "function() Snacks.picker.recent() end";
      options.desc = "Recent files";
    }
    {
      mode = "n";
      key = "<leader>fw";
      action.__raw = "function() Snacks.picker.grep_word() end";
      options.desc = "Grep word under cursor";
    }
    {
      mode = "v";
      key = "<leader>fw";
      action.__raw = "function() Snacks.picker.grep_word() end";
      options.desc = "Grep selection";
    }
    {
      mode = "n";
      key = "<leader>fR";
      action.__raw = "function() Snacks.picker.resume() end";
      options.desc = "Resume last picker";
    }
    {
      mode = ["n" "v"];
      key = "<leader>pf";
      action.__raw = "function() require('juicy.project').pick('files') end";
      options.desc = "Project files";
    }
    {
      mode = ["n" "v"];
      key = "<leader>ps";
      action.__raw = "function() require('juicy.project').pick('grep') end";
      options.desc = "Project search";
    }
    {
      mode = ["n" "v"];
      key = "<leader>pb";
      action.__raw = "function() require('juicy.project').pick('buffers', { filter = { cwd = true } }) end";
      options.desc = "Project buffers";
    }
    {
      mode = "n";
      key = "<leader>pt";
      action.__raw = "function() require('juicy.project').pick('explorer') end";
      options.desc = "Project tree";
    }
    {
      mode = ["n" "x"];
      key = "<leader>sr";
      action.__raw = ''function() require("grug-far").open({ visualSelectionUsage = "auto-detect", prefills = { paths = require("juicy.project").root() } }) end'';
      options.desc = "Search and replace project";
    }
  ];
}

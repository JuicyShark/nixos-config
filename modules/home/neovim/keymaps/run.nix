_: {
  programs.nixvim.keymaps = [
    {
      mode = ["n" "t"];
      key = "<C-`>";
      action.__raw = "function() require('juicy.project').terminal() end";
      options.desc = "Toggle terminal";
    }
    {
      mode = ["n" "t"];
      key = "<leader>ot";
      action.__raw = "function() require('juicy.project').terminal() end";
      options.desc = "Open terminal";
    }
    {
      mode = "t";
      key = "<Esc>";
      action = ''<C-\><C-N>'';
      options.desc = "Unfocus terminal";
    }

    {
      mode = "n";
      key = "<leader>rr";
      action = "<cmd>OverseerRun<CR>";
      options.desc = "Run task";
    }
    {
      mode = "n";
      key = "<F6>";
      action = "<cmd>OverseerRun<CR>";
      options.desc = "Run task";
    }
    {
      mode = "n";
      key = "<leader>rl";
      action.__raw = ''
        function()
          local tasks = require("overseer").list_tasks({ recent_first = true })
          if tasks[1] then
            tasks[1]:restart()
          else
            vim.notify("No task to restart", vim.log.levels.INFO)
          end
        end
      '';
      options.desc = "Restart last task";
    }
    {
      mode = "n";
      key = "<leader>rt";
      action = "<cmd>OverseerToggle<CR>";
      options.desc = "Toggle task list";
    }
    {
      mode = "n";
      key = "<leader>ra";
      action = "<cmd>OverseerTaskAction<CR>";
      options.desc = "Task action";
    }
    {
      mode = "n";
      key = "<leader>rs";
      action = "<cmd>OverseerShell<CR>";
      options.desc = "Run shell task";
    }
    {
      mode = "n";
      key = "<leader>rc";
      action.__raw = "function() require('juicy.project').terminal() end";
      options.desc = "Open terminal";
    }
  ];
}

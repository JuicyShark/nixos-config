_: {
  programs.nixvim.keymaps = [
    {
      mode = ["n" "t"];
      key = "<C-`>";
      action.__raw = "function() Snacks.terminal.toggle(nil, { win = { position = 'bottom', height = 0.25 }, cwd = vim.fn.getcwd() }) end";
      options.desc = "Toggle terminal";
    }
    {
      mode = ["n" "t"];
      key = "<leader>ot";
      action.__raw = "function() Snacks.terminal.toggle(nil, { win = { position = 'bottom', height = 0.25 }, cwd = vim.fn.getcwd() }) end";
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
      action.__raw = "function() Snacks.terminal.toggle(nil, { win = { position = 'bottom', height = 0.3 }, cwd = vim.fn.getcwd() }) end";
      options.desc = "Open terminal";
    }

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
}

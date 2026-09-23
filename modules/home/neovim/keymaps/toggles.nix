_: {
  programs.nixvim.keymaps = [
    {
      mode = "n";
      key = "<leader>tA";
      action.__raw = ''
        function()
          vim.g.reduced_motion = not vim.g.reduced_motion
          vim.g.snacks_animate = not vim.g.reduced_motion
          if vim.g.reduced_motion then
            vim.g.juicy_cursor_animation = MiniAnimate.config.cursor.enable
            MiniAnimate.config.cursor.enable = false
          else
            MiniAnimate.config.cursor.enable = vim.g.juicy_cursor_animation ~= false
          end
          vim.notify("Reduced motion: " .. (vim.g.reduced_motion and "on" or "off"))
        end
      '';
      options.desc = "Toggle reduced motion";
    }
    {
      mode = "n";
      key = "<leader>ta";
      action.__raw = ''
        function()
          if vim.g.reduced_motion then
            vim.notify("Disable reduced motion first with <leader>tA")
            return
          end
          MiniAnimate.config.cursor.enable = not MiniAnimate.config.cursor.enable
          vim.notify("Cursor animation: " .. (MiniAnimate.config.cursor.enable and "on" or "off"))
        end
      '';
      options.desc = "Toggle cursor animation";
    }
    {
      mode = "n";
      key = "<leader>tw";
      action.__raw = ''function() Snacks.toggle.option("wrap", { name = "Wrap" }):toggle() end'';
      options.desc = "Toggle wrap";
    }
    {
      mode = "n";
      key = "<leader>ts";
      action.__raw = ''function() Snacks.toggle.option("spell", { name = "Spell" }):toggle() end'';
      options.desc = "Toggle spell";
    }
    {
      mode = "n";
      key = "<leader>tn";
      action.__raw = "function() Snacks.toggle.line_number():toggle() end";
      options.desc = "Toggle line numbers";
    }
    {
      mode = "n";
      key = "<leader>td";
      action.__raw = "function() Snacks.toggle.diagnostics():toggle() end";
      options.desc = "Toggle diagnostics";
    }
    {
      mode = "n";
      key = "<leader>tf";
      action.__raw = ''
        function()
          vim.g.disable_autoformat = not vim.g.disable_autoformat
          vim.notify("Format on save: " .. (vim.g.disable_autoformat and "off" or "on"))
        end
      '';
      options.desc = "Toggle format on save";
    }
    {
      mode = "n";
      key = "<leader>th";
      action.__raw = ''
        function()
          local ih = vim.lsp.inlay_hint
          ih.enable(not ih.is_enabled({ bufnr = 0 }), { bufnr = 0 })
        end
      '';
      options.desc = "Toggle inlay hints";
    }
    {
      mode = "n";
      key = "<leader>tm";
      action.__raw = ''function() require("render-markdown").toggle() end'';
      options.desc = "Toggle Markdown rendering";
    }
  ];
}

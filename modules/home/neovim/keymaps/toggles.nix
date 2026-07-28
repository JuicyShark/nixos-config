_: {
  programs.nixvim.keymaps = [
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
  ];
}

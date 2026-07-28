_: {
  programs.nixvim.keymaps = [
    {
      mode = "n";
      key = "<leader>ch";
      action = "<cmd>checkhealth vim.lsp<CR>";
      options.desc = "LSP health and clients";
    }
    {
      mode = "n";
      key = "<leader>co";
      action = "<cmd>NixLuaOtter<CR>";
      options.desc = "Embedded Lua LSP";
    }
    {
      mode = "n";
      key = "<leader>cD";
      action.__raw = "function() Snacks.picker.lsp_references() end";
      options.desc = "References";
    }
    {
      mode = "n";
      key = "<leader>ci";
      action.__raw = "function() Snacks.picker.lsp_implementations() end";
      options.desc = "Implementations";
    }
    {
      mode = "n";
      key = "<leader>cd";
      action.__raw = "function() Snacks.picker.lsp_definitions() end";
      options.desc = "Definitions";
    }
    {
      mode = "n";
      key = "<leader>ct";
      action.__raw = "function() Snacks.picker.lsp_type_definitions() end";
      options.desc = "Type definitions";
    }
    {
      mode = "n";
      key = "<leader>cs";
      action.__raw = "function() Snacks.picker.lsp_symbols() end";
      options.desc = "Document symbols";
    }
    {
      mode = "n";
      key = "<leader>cS";
      action.__raw = "function() Snacks.picker.lsp_workspace_symbols() end";
      options.desc = "Workspace symbols";
    }
  ];
}

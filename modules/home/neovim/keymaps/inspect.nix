_: {
  programs.nixvim.keymaps = [
    {
      mode = "n";
      key = "<leader>ix";
      action = "<cmd>Hexdump<CR>";
      options.desc = "Hex view";
    }
    {
      mode = "n";
      key = "<leader>iX";
      action = "<cmd>HexdumpUndo<CR>";
      options.desc = "Hex view undo";
    }
    {
      mode = "n";
      key = "<leader>id";
      action = "<cmd>Disasm<CR>";
      options.desc = "Disassemble";
    }
    {
      mode = "n";
      key = "<leader>is";
      action = "<cmd>Strings<CR>";
      options.desc = "Strings in file";
    }
    {
      mode = "n";
      key = "<leader>in";
      action = "<cmd>NixDrv<CR>";
      options.desc = "Show nix derivation";
    }
  ];
}

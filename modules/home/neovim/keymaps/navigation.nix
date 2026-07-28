_: {
  programs.nixvim.keymaps = [
    {
      mode = ["n" "v"];
      key = "gx";
      action.__raw = "function() open_hyperlink_under_cursor() end";
      options.desc = "Open link";
    }
    {
      mode = "n";
      key = "<CR>";
      action.__raw = "function() open_hyperlink_under_cursor() end";
      options.desc = "Open link";
    }

    {
      mode = "n";
      key = "<C-Left>";
      action = "<C-w>h";
      options.desc = "Focus left split";
    }
    {
      mode = "n";
      key = "<C-Down>";
      action = "<C-w>j";
      options.desc = "Focus lower split";
    }
    {
      mode = "n";
      key = "<C-Up>";
      action = "<C-w>k";
      options.desc = "Focus upper split";
    }
    {
      mode = "n";
      key = "<C-Right>";
      action = "<C-w>l";
      options.desc = "Focus right split";
    }
    {
      mode = "v";
      key = "<C-Left>";
      action = "<C-w>h";
      options.desc = "Focus left split";
    }
    {
      mode = "v";
      key = "<C-Down>";
      action = "<C-w>j";
      options.desc = "Focus lower split";
    }
    {
      mode = "v";
      key = "<C-Up>";
      action = "<C-w>k";
      options.desc = "Focus upper split";
    }
    {
      mode = "v";
      key = "<C-Right>";
      action = "<C-w>l";
      options.desc = "Focus right split";
    }
    {
      mode = "i";
      key = "<C-Left>";
      action = "<C-o><C-w>h";
      options.desc = "Focus left split";
    }
    {
      mode = "i";
      key = "<C-Down>";
      action = "<C-o><C-w>j";
      options.desc = "Focus lower split";
    }
    {
      mode = "i";
      key = "<C-Up>";
      action = "<C-o><C-w>k";
      options.desc = "Focus upper split";
    }
    {
      mode = "i";
      key = "<C-Right>";
      action = "<C-o><C-w>l";
      options.desc = "Focus right split";
    }
    {
      mode = "t";
      key = "<C-Left>";
      action = ''<C-\><C-N><C-w>h'';
      options.desc = "Focus left split";
    }
    {
      mode = "t";
      key = "<C-Down>";
      action = ''<C-\><C-N><C-w>j'';
      options.desc = "Focus lower split";
    }
    {
      mode = "t";
      key = "<C-Up>";
      action = ''<C-\><C-N><C-w>k'';
      options.desc = "Focus upper split";
    }
    {
      mode = "t";
      key = "<C-Right>";
      action = ''<C-\><C-N><C-w>l'';
      options.desc = "Focus right split";
    }
    {
      mode = "n";
      key = "<A-v>";
      action = "<cmd>vsplit<CR>";
      options.desc = "Vertical split";
    }
    {
      mode = "n";
      key = "<A-h>";
      action = "<cmd>split<CR>";
      options.desc = "Horizontal split";
    }

    {
      mode = ["n" "v" "o"];
      key = "h";
      action = "<Nop>";
      options.desc = "Disabled";
    }
    {
      mode = ["n" "v" "o"];
      key = "j";
      action = "<Nop>";
      options.desc = "Disabled";
    }
    {
      mode = ["v" "o"];
      key = "k";
      action = "<Nop>";
      options.desc = "Disabled";
    }
    {
      mode = ["n" "v" "o"];
      key = "l";
      action = "<Nop>";
      options.desc = "Disabled";
    }

    {
      mode = ["n" "v"];
      key = "<Down>";
      action = "gj";
      options = {
        silent = true;
        noremap = true;
      };
    }
    {
      mode = ["n" "v"];
      key = "<Up>";
      action = "gk";
      options = {
        silent = true;
        noremap = true;
      };
    }
    {
      mode = "n";
      key = "<Esc>";
      action = "<cmd>noh<CR><Esc>";
      options = {
        desc = "Clear search highlight";
        silent = true;
      };
    }
    {
      mode = "v";
      key = "<";
      action = "<gv";
      options.desc = "Indent left";
    }
    {
      mode = "v";
      key = ">";
      action = ">gv";
      options.desc = "Indent right";
    }
    {
      mode = "n";
      key = "<C-d>";
      action = "<C-d>zz";
      options.desc = "Half-page down";
    }
    {
      mode = "n";
      key = "<C-u>";
      action = "<C-u>zz";
      options.desc = "Half-page up";
    }
    {
      mode = "n";
      key = "n";
      action = "nzzzv";
      options.desc = "Next search match";
    }
    {
      mode = "n";
      key = "N";
      action = "Nzzzv";
      options.desc = "Prev search match";
    }
    {
      mode = ["n" "v"];
      key = "<C-s>";
      action = "<cmd>write<CR>";
      options.desc = "Save file";
    }
    {
      mode = "i";
      key = "<C-s>";
      action = "<C-o><cmd>write<CR>";
      options.desc = "Save file";
    }
    {
      mode = "n";
      key = "<A-Down>";
      action = "<cmd>m .+1<CR>==";
      options.desc = "Move line down";
    }
    {
      mode = "n";
      key = "<A-Up>";
      action = "<cmd>m .-2<CR>==";
      options.desc = "Move line up";
    }
    {
      mode = "v";
      key = "<A-Down>";
      action = ":m '>+1<CR>gv=gv";
      options = {
        desc = "Move selection down";
        silent = true;
      };
    }
    {
      mode = "v";
      key = "<A-Up>";
      action = ":m '<-2<CR>gv=gv";
      options = {
        desc = "Move selection up";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<C-S-Left>";
      action = "<cmd>vertical resize -2<CR>";
      options.desc = "Shrink split horizontally";
    }
    {
      mode = "n";
      key = "<C-S-Right>";
      action = "<cmd>vertical resize +2<CR>";
      options.desc = "Grow split horizontally";
    }
    {
      mode = "n";
      key = "<C-S-Up>";
      action = "<cmd>resize -2<CR>";
      options.desc = "Shrink split vertically";
    }
    {
      mode = "n";
      key = "<C-S-Down>";
      action = "<cmd>resize +2<CR>";
      options.desc = "Grow split vertically";
    }
  ];
}

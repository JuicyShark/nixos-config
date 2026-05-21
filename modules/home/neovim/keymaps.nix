# All keymap definitions
_: {
  programs.nixvim.keymaps = [
    {
      mode = "n";
      key = "<A-left>";
      action = "<cmd>bprevious<cr>";
      options.desc = "Prev Buffer";
    }
    {
      mode = "n";
      key = "<A-right>";
      action = "<cmd>bnext<cr>";
      options.desc = "Next Buffer";
    }

    # Buffer deletion (snacks)
    {
      mode = "n";
      key = "<A-w>";
      action.__raw = "function() Snacks.bufdelete() end";
      options.desc = "Delete Buffer";
    }

    # File explorer toggle (snacks)
    {
      mode = "n";
      key = "<leader>e";
      action.__raw = "function() Snacks.explorer() end";
      options.desc = "Explorer (snacks)";
    }
    {
      mode = "n";
      key = "<leader>.";
      action.__raw = "function() Snacks.explorer() end";
      options.desc = "Explorer (snacks)";
    }

    # Split navigation: Ctrl+Arrow in all modes
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
      options.desc = "Focus left split (visual)";
    }
    {
      mode = "v";
      key = "<C-Down>";
      action = "<C-w>j";
      options.desc = "Focus lower split (visual)";
    }
    {
      mode = "v";
      key = "<C-Up>";
      action = "<C-w>k";
      options.desc = "Focus upper split (visual)";
    }
    {
      mode = "v";
      key = "<C-Right>";
      action = "<C-w>l";
      options.desc = "Focus right split (visual)";
    }
    {
      mode = "i";
      key = "<C-Left>";
      action = "<C-o><C-w>h";
      options.desc = "Focus left split (insert)";
    }
    {
      mode = "i";
      key = "<C-Down>";
      action = "<C-o><C-w>j";
      options.desc = "Focus lower split (insert)";
    }
    {
      mode = "i";
      key = "<C-Up>";
      action = "<C-o><C-w>k";
      options.desc = "Focus upper split (insert)";
    }
    {
      mode = "i";
      key = "<C-Right>";
      action = "<C-o><C-w>l";
      options.desc = "Focus right split (insert)";
    }
    {
      mode = "t";
      key = "<C-Left>";
      action = ''<C-\><C-N><C-w>h'';
      options.desc = "Focus left split (terminal)";
    }
    {
      mode = "t";
      key = "<C-Down>";
      action = ''<C-\><C-N><C-w>j'';
      options.desc = "Focus lower split (terminal)";
    }
    {
      mode = "t";
      key = "<C-Up>";
      action = ''<C-\><C-N><C-w>k'';
      options.desc = "Focus upper split (terminal)";
    }
    {
      mode = "t";
      key = "<C-Right>";
      action = ''<C-\><C-N><C-w>l'';
      options.desc = "Focus right split (terminal)";
    }

    # Split creation
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
      mode = [
        "n"
        "t"
      ];
      key = "<C-`>";
      action.__raw = "function() Snacks.terminal.toggle(nil, { win = { position = 'bottom', height = 0.25 }, cwd = vim.fn.getcwd() }) end";
      options.desc = "Toggle terminal";
    }
    {
      mode = "t";
      key = "<Esc>";
      action = ''<C-\><C-N>'';
      options.desc = "Unfocus terminal";
    }
    # [F]ind things (Snacks picker)
    {
      mode = ["n" "v"];
      key = "<leader>ff";
      action.__raw = "function() Snacks.picker.files() end";
      options.desc = "Find Files";
    }
    {
      mode = ["n" "v" "i"];
      key = "<C-f>";
      action.__raw = "function() Snacks.picker.files() end";
      options = {
        desc = "Find Files";
        silent = true;
        nowait = true;
      };
    }
    {
      mode = ["n" "v"];
      key = "<leader>fg";
      action.__raw = "function() Snacks.picker.grep() end";
      options.desc = "Find w/ Grep";
    }
    {
      mode = ["n" "v"];
      key = "<leader>fb";
      action.__raw = "function() Snacks.picker.buffers() end";
      options.desc = "Find Buffers";
    }
    {
      mode = ["n" "v"];
      key = "<leader>fr";
      action.__raw = "function() Snacks.picker.recent() end";
      options.desc = "Recent Files";
    }
    {
      mode = "n";
      key = "<leader>xx";
      action = "<cmd>Trouble diagnostics toggle<CR>";
      options = {
        desc = "Workspace diagnostics";
        nowait = true;
      };
    }
    {
      mode = ["n" "v"];
      key = "<leader>f?";
      action.__raw = "function() Snacks.picker.help() end";
      options.desc = "Help Tags";
    }
    {
      mode = ["n" "v"];
      key = "<leader>?";
      action.__raw = "function() Snacks.picker.help() end";
      options.silent = true;
    }
    {
      mode = [
        "n"
        "v"
      ];
      key = "<leader>ft";
      action = "<cmd>TodoTrouble<CR>";
      options = {
        desc = "[F]ind [T]odo's";
        nowait = true;
      };
    }
    {
      mode = [
        "n"
        "v"
      ];
      key = "<leader>xt";
      action = "<cmd>Trouble<CR>";
      options = {
        desc = "Trouble toggle";
        nowait = true;
      };
    }

    # Debug (dap + dap-ui)
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

    # Bytes / low-level file exploration
    {
      mode = "n";
      key = "<leader>bx";
      action = "<cmd>Hexdump<CR>";
      options.desc = "Hex view (xxd)";
    }
    {
      mode = "n";
      key = "<leader>bX";
      action = "<cmd>HexdumpUndo<CR>";
      options.desc = "Hex view undo";
    }
    {
      mode = "n";
      key = "<leader>bd";
      action = "<cmd>Disasm<CR>";
      options.desc = "Disassemble (objdump)";
    }
    {
      mode = "n";
      key = "<leader>bs";
      action = "<cmd>Strings<CR>";
      options.desc = "Strings in file";
    }
    {
      mode = "n";
      key = "<leader>bn";
      action = "<cmd>NixDrv<CR>";
      options.desc = "Show nix derivation";
    }

    # Inlay hints toggle
    {
      mode = "n";
      key = "<leader>ch";
      action.__raw = ''
        function()
          local ih = vim.lsp.inlay_hint
          ih.enable(not ih.is_enabled({ bufnr = 0 }), { bufnr = 0 })
        end
      '';
      options.desc = "Toggle inlay hints";
    }
    # Git
    {
      mode = [
        "n"
        "v"
      ];
      key = "<leader>gc";
      action = "<cmd>LazyGit<CR>";
      options = {
        desc = "LazyGit";
      };
    }
    # IDE actions — compiler.nvim picker (build / run / test / debug)
    {
      mode = "n";
      key = "<leader>rr";
      action = "<cmd>CompilerOpen<CR>";
      options.desc = "Compile/Run (picker)";
    }
    {
      mode = "n";
      key = "<F6>";
      action = "<cmd>CompilerOpen<CR>";
      options.desc = "Compile/Run (picker)";
    }
    {
      mode = "n";
      key = "<leader>rb";
      action = "<cmd>CompilerRedo<CR>";
      options.desc = "Re-run last compile";
    }
    {
      mode = "n";
      key = "<leader>rt";
      action = "<cmd>CompilerToggleResults<CR>";
      options.desc = "Toggle compile results";
    }
    {
      mode = "n";
      key = "<leader>rs";
      action = "<cmd>CompilerStop<CR>";
      options.desc = "Stop compile";
    }
    {
      mode = "n";
      key = "<leader>ro";
      action = "<cmd>OverseerToggle<CR>";
      options.desc = "Overseer task list";
    }
    {
      mode = "n";
      key = "<leader>rc";
      action.__raw = "function() Snacks.terminal.toggle(nil, { win = { position = 'bottom', height = 0.3 }, cwd = vim.fn.getcwd() }) end";
      options.desc = "Toggle terminal";
    }
    # Terminal toggle (also bound to <C-`>)
    {
      mode = "n";
      key = "<leader>tt";
      action.__raw = "function() Snacks.terminal.toggle(nil, { win = { position = 'bottom', height = 0.3 }, cwd = vim.fn.getcwd() }) end";
      options.desc = "Toggle terminal";
    }
    # Git - Diffview
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
    # Misc
    {
      mode = [
        "n"
        "v"
      ];
      key = "<Down>";
      options.silent = true;
      options.noremap = true;
      action = "gj";
    }
    {
      mode = [
        "n"
        "v"
      ];
      key = "<Up>";
      options.silent = true;
      options.noremap = true;
      action = "gk";
    }

    # Save (Ctrl-S)
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

    # Move lines (Alt-j / Alt-k)
    {
      mode = "n";
      key = "<A-j>";
      action = "<cmd>m .+1<CR>==";
      options.desc = "Move line down";
    }
    {
      mode = "n";
      key = "<A-k>";
      action = "<cmd>m .-2<CR>==";
      options.desc = "Move line up";
    }
    {
      mode = "i";
      key = "<A-j>";
      action = "<Esc><cmd>m .+1<CR>==gi";
      options.desc = "Move line down";
    }
    {
      mode = "i";
      key = "<A-k>";
      action = "<Esc><cmd>m .-2<CR>==gi";
      options.desc = "Move line up";
    }
    {
      mode = "v";
      key = "<A-j>";
      action = ":m '>+1<CR>gv=gv";
      options = {
        desc = "Move selection down";
        silent = true;
      };
    }
    {
      mode = "v";
      key = "<A-k>";
      action = ":m '<-2<CR>gv=gv";
      options = {
        desc = "Move selection up";
        silent = true;
      };
    }

    # LSP symbol pickers
    {
      mode = "n";
      key = "<leader>fs";
      action.__raw = "function() Snacks.picker.lsp_symbols() end";
      options.desc = "Document symbols";
    }
    {
      mode = "n";
      key = "<leader>fS";
      action.__raw = "function() Snacks.picker.lsp_workspace_symbols() end";
      options.desc = "Workspace symbols";
    }

    # Diagnostics picker + grep word
    {
      mode = "n";
      key = "<leader>fd";
      action.__raw = "function() Snacks.picker.diagnostics() end";
      options.desc = "Diagnostics picker";
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

    # Resume last picker
    {
      mode = "n";
      key = "<leader>fR";
      action.__raw = "function() Snacks.picker.resume() end";
      options.desc = "Resume last picker";
    }

    # Clear search highlight with Esc in normal mode
    {
      mode = "n";
      key = "<Esc>";
      action = "<cmd>noh<CR><Esc>";
      options = {
        desc = "Clear search highlight";
        silent = true;
      };
    }

    # Visual indent keeps selection
    {
      mode = "v";
      key = "<";
      action = "<gv";
      options.desc = "Indent left (keep selection)";
    }
    {
      mode = "v";
      key = ">";
      action = ">gv";
      options.desc = "Indent right (keep selection)";
    }

    # Center cursor on scroll / search
    {
      mode = "n";
      key = "<C-d>";
      action = "<C-d>zz";
      options.desc = "Half-page down (centered)";
    }
    {
      mode = "n";
      key = "<C-u>";
      action = "<C-u>zz";
      options.desc = "Half-page up (centered)";
    }
    {
      mode = "n";
      key = "n";
      action = "nzzzv";
      options.desc = "Next search match (centered)";
    }
    {
      mode = "n";
      key = "N";
      action = "Nzzzv";
      options.desc = "Prev search match (centered)";
    }

    # UI toggles (<leader>u*)
    {
      mode = "n";
      key = "<leader>uw";
      action.__raw = ''function() Snacks.toggle.option("wrap", { name = "Wrap" }):toggle() end'';
      options.desc = "Toggle wrap";
    }
    {
      mode = "n";
      key = "<leader>us";
      action.__raw = ''function() Snacks.toggle.option("spell", { name = "Spell" }):toggle() end'';
      options.desc = "Toggle spell";
    }
    {
      mode = "n";
      key = "<leader>un";
      action.__raw = "function() Snacks.toggle.line_number():toggle() end";
      options.desc = "Toggle line numbers";
    }
    {
      mode = "n";
      key = "<leader>ud";
      action.__raw = "function() Snacks.toggle.diagnostics():toggle() end";
      options.desc = "Toggle diagnostics";
    }
    {
      mode = "n";
      key = "<leader>uf";
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
      key = "<leader>uh";
      action.__raw = ''
        function()
          local ih = vim.lsp.inlay_hint
          ih.enable(not ih.is_enabled({ bufnr = 0 }), { bufnr = 0 })
        end
      '';
      options.desc = "Toggle inlay hints";
    }

    # Quickfix nav
    {
      mode = "n";
      key = "]q";
      action = "<cmd>cnext<CR>";
      options.desc = "Next quickfix";
    }
    {
      mode = "n";
      key = "[q";
      action = "<cmd>cprev<CR>";
      options.desc = "Prev quickfix";
    }
    {
      mode = "n";
      key = "]Q";
      action = "<cmd>clast<CR>";
      options.desc = "Last quickfix";
    }
    {
      mode = "n";
      key = "[Q";
      action = "<cmd>cfirst<CR>";
      options.desc = "First quickfix";
    }

    # Close other buffers
    {
      mode = "n";
      key = "<leader>bo";
      action.__raw = "function() Snacks.bufdelete.other() end";
      options.desc = "Close other buffers";
    }

    ## [N]eorg / [N]otes Binds
    {
      mode = "n";
      key = "<leader>nt";
      action = "<cmd>Neorg journal today<CR>";
      options = {
        desc = "Open Journal";
      };
    }
    {
      mode = "n";
      key = "<leader>nn";
      action = "<Plug>(neorg.tempus.insert-date)";
      options = {
        desc = "Insert Date";
      };
    }
    {
      mode = "i";
      key = "<C-g>d";
      action = "<Plug>(neorg.tempus.insert-date.insert-mode)";
      options = {
        desc = "Insert Date";
      };
    }
  ];
}

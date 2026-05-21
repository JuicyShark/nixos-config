# Extra Lua configuration blocks
{pkgs, ...}: let
  codelldbAdapter = "${pkgs.vscode-extensions.vadimcn.vscode-lldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb";
in {
  programs.nixvim.extraConfigLua = ''
    -- Register missing treesitter predicates (grammar/runtime version mismatch)
    local ts_query = require("vim.treesitter.query")
    local predicates = ts_query.list_predicates and ts_query.list_predicates() or {}
    local has_is_not = false
    for _, p in ipairs(predicates) do
      if p == "is-not?" then has_is_not = true; break end
    end
    if not has_is_not then
      vim.treesitter.query.add_predicate("is-not?", function(match, _pattern, bufnr, pred)
        local dominated = pred[2]
        local dominated_node = match[dominated]
        if not dominated_node then return true end
        local dominated_type = dominated_node:type()
        for i = 3, #pred do
          if dominated_type == pred[i] then return false end
        end
        return true
      end, { force = true })
    end

    -- Enhanced diagnostic configuration
    vim.diagnostic.config({
      virtual_text = {
        spacing = 4,
        prefix = '●',
        source = 'if_many',
      },
      float = {
        focusable = false,
        close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
        border = 'rounded',
        source = 'always',
        prefix = "",
        scope = 'cursor',
      },
      signs = true,
      underline = true,
      update_in_insert = false,
      severity_sort = true,
    })

    -- Auto-show diagnostic on cursor hold
    vim.api.nvim_create_autocmd({ "CursorHold" }, {
      pattern = "*",
      callback = function()
        vim.diagnostic.open_float(nil, { focus = false })
      end,
    })

    -- Inlay hints on LspAttach (Neovim 0.10+). Toggle with <leader>ch.
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        if vim.lsp.inlay_hint then
          pcall(vim.lsp.inlay_hint.enable, true, { bufnr = args.buf })
        end
      end,
    })

    -- nvim-lint: run on write/read/insert-leave
    vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
      callback = function()
        local ok, lint = pcall(require, "lint")
        if ok then pcall(lint.try_lint) end
      end,
    })

    -- DAP: codelldb adapter for c / cpp / rust. Path is baked in at build time.
    do
      local ok, dap = pcall(require, "dap")
      if ok then
        dap.adapters.codelldb = {
          type = "server",
          port = "''${port}",
          executable = {
            command = "${codelldbAdapter}",
            args = { "--port", "''${port}" },
          },
        }
        local lldb_cfg = {
          {
            name = "Launch (codelldb)",
            type = "codelldb",
            request = "launch",
            program = function()
              return vim.fn.input("exe> ", vim.fn.getcwd() .. "/", "file")
            end,
            cwd = "''${workspaceFolder}",
            stopOnEntry = false,
            args = {},
          },
        }
        dap.configurations.c = lldb_cfg
        dap.configurations.cpp = lldb_cfg
        dap.configurations.rust = lldb_cfg
      end
    end

    -- Byte / disassembly / nix-derivation user commands
    local function snacks_term(cmd)
      Snacks.terminal(cmd, {
        win = { position = "bottom", height = 0.4 },
        cwd = vim.fn.getcwd(),
        interactive = true,
      })
    end

    vim.api.nvim_create_user_command("Hexdump", function()
      vim.cmd("%!xxd")
      vim.bo.filetype = "xxd"
    end, {})
    vim.api.nvim_create_user_command("HexdumpUndo", function()
      vim.cmd("%!xxd -r")
    end, {})
    vim.api.nvim_create_user_command("Disasm", function(opts)
      local f = opts.args ~= "" and opts.args or vim.fn.expand("%:p")
      snacks_term("objdump -d -M intel " .. vim.fn.shellescape(f) .. " | less -R")
    end, { nargs = "?", complete = "file" })
    vim.api.nvim_create_user_command("Strings", function(opts)
      local f = opts.args ~= "" and opts.args or vim.fn.expand("%:p")
      snacks_term("strings " .. vim.fn.shellescape(f) .. " | less")
    end, { nargs = "?", complete = "file" })
    vim.api.nvim_create_user_command("NixDrv", function()
      snacks_term("nix derivation show .# | jq . | less -R")
    end, {})

    -- compiler.nvim + overseer.nvim drive build/run/test; see keymaps under <leader>r.

    -- Diffview: disable mercurial
    require("diffview").setup({
      hg_cmd = {},
    })

    -- Set vim.ui overrides (deferred to ensure Snacks is loaded)
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      once = true,
      callback = function()
        if Snacks and Snacks.picker then
          vim.ui.select = Snacks.picker.select
        end
        if Snacks and Snacks.input then
          vim.ui.input = Snacks.input
        end
      end,
    })
  '';
}

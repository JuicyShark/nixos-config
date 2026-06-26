# Extra Lua configuration blocks
{pkgs, ...}: let
  codelldbAdapter = "${pkgs.vscode-extensions.vadimcn.vscode-lldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb";
in {
  programs.nixvim.extraConfigLua = ''
    do
      local rt = vim.env.XDG_RUNTIME_DIR
      if rt and rt ~= "" then
        local sockets = {}
        if vim.env.KITTY_PID and vim.env.KITTY_PID ~= "" then
          table.insert(sockets, rt .. "/nvim-smart-focus-kitty-" .. vim.env.KITTY_PID .. ".sock")
        end
        table.insert(sockets, rt .. "/nvim-smart-focus-" .. tostring(vim.fn.getpid()) .. ".sock")

        local uv = vim.uv or vim.loop
        local started = {}
        for _, candidate in ipairs(sockets) do
          if uv and uv.fs_unlink then
            pcall(uv.fs_unlink, candidate)
          end
          local ok = pcall(vim.fn.serverstart, candidate)
          if ok then
            table.insert(started, candidate)
          end
        end
        if #started > 0 then
          vim.g.smart_focus_server = started[1]
          vim.api.nvim_create_autocmd("VimLeavePre", {
            callback = function()
              for _, socket in ipairs(started) do
                if uv and uv.fs_unlink then
                  pcall(uv.fs_unlink, socket)
                end
              end
            end,
          })
        end
      end
    end

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

    -- Snacks is configured before this block by nixvim, so make UI overrides
    -- deterministic for startup and headless health checks.
    if Snacks and Snacks.picker then
      Snacks.picker.setup()
    end
    if Snacks and Snacks.input then
      Snacks.input.enable()
    end
  '';
}

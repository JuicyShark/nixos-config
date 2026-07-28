local failures = {}

local function expect(name, condition)
	if not condition then
		table.insert(failures, name)
	end
end

local ok_focus, smart_focus = pcall(require, "juicy.smart_focus")
expect("juicy.smart_focus load", ok_focus)

if ok_focus then
	local sockets = smart_focus.socket_candidates("/run/user/1000", "123", 456)
	expect("kitty window socket first", sockets[1] == "/run/user/1000/nvim-smart-focus-kitty-window-123.sock")
	expect("pid socket second", sockets[2] == "/run/user/1000/nvim-smart-focus-456.sock")

	if #vim.api.nvim_tabpage_list_wins(0) > 1 then
		vim.cmd("only")
	end
	local original = vim.api.nvim_get_current_win()
	vim.cmd("rightbelow vsplit")
	local right = vim.api.nvim_get_current_win()
	expect(
		"smart focus moves to left split",
		smart_focus.move("left") == 1 and vim.api.nvim_get_current_win() == original
	)
	expect(
		"smart focus stops at left edge",
		smart_focus.move("left") == 0 and vim.api.nvim_get_current_win() == original
	)
	expect(
		"smart focus moves to right split",
		smart_focus.move("right") == 1 and vim.api.nvim_get_current_win() == right
	)
	expect("smart focus rejects unknown direction", smart_focus.move("sideways") == 0)
	vim.cmd("only")

	original = vim.api.nvim_get_current_win()
	vim.cmd("rightbelow split")
	local bottom = vim.api.nvim_get_current_win()
	expect(
		"smart focus moves to upper split",
		smart_focus.move("up") == 1 and vim.api.nvim_get_current_win() == original
	)
	expect(
		"smart focus stops at upper edge",
		smart_focus.move("up") == 0 and vim.api.nvim_get_current_win() == original
	)
	expect(
		"smart focus moves to lower split",
		smart_focus.move("down") == 1 and vim.api.nvim_get_current_win() == bottom
	)
	vim.cmd("only")
end

local diagnostics = vim.diagnostic.config()
expect("legacy diagnostic virtual text disabled", diagnostics.virtual_text == false)
expect(
	"native current-line diagnostic virtual lines",
	type(diagnostics.virtual_lines) == "table" and diagnostics.virtual_lines.current_line == true
)

expect("node provider disabled by NixVim", vim.g.loaded_node_provider == 0)
expect("python provider disabled by NixVim", vim.g.loaded_python3_provider == 0)
expect("ruby provider disabled by NixVim", vim.g.loaded_ruby_provider == 0)
expect("legacy LspInfo command removed", vim.fn.exists(":LspInfo") == 0)
expect(
	"native linked editing API",
	type(vim.lsp.linked_editing_range) == "table" and type(vim.lsp.linked_editing_range.enable) == "function"
)
expect("nvim-ufo removed", not pcall(require, "ufo"))
expect("compiler.nvim removed", vim.fn.exists(":CompilerOpen") == 0)
expect("Overseer task command", vim.fn.exists(":OverseerRun") == 2)
expect("word-level inline diff", vim.list_contains(vim.opt.diffopt:get(), "inline:word"))

local code_map = vim.fn.maparg("<leader>cd", "n", false, true)
expect("Doom-style code prefix", code_map.desc == "Definitions")
expect("old LSP prefix removed", vim.fn.maparg("<leader>ld", "n") == "")

local run_map = vim.fn.maparg("<leader>rr", "n", false, true)
expect("Overseer owns run workflow", run_map.desc == "Run task")

local dap = require("dap")
expect("DAP UI opens on launch", type(dap.listeners.before.launch.juicy_dapui) == "function")
expect("DAP UI closes on exit", type(dap.listeners.before.event_exited.juicy_dapui) == "function")

vim.cmd("enew")
vim.cmd("setfiletype rust")
expect("native treesitter foldexpr", vim.wo.foldexpr == "v:lua.vim.treesitter.foldexpr()")
expect("rust indent is four spaces", vim.bo.shiftwidth == 4 and vim.bo.tabstop == 4)

local rust_map = vim.fn.maparg("<leader>mr", "n", false, true)
expect("rust ftplugin keymap", rust_map.buffer == 1 and rust_map.desc == "Rust runnables")

if #failures > 0 then
	vim.api.nvim_err_writeln("NixVim native config contract failed:\n- " .. table.concat(failures, "\n- "))
	vim.cmd.cquit(1)
end

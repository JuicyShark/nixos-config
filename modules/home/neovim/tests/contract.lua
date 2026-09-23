local failures = {}

local function expect(name, condition)
	if not condition then
		table.insert(failures, name)
	end
end

local ok_focus, smart_focus = pcall(require, "juicy.smart_focus")
expect("juicy.smart_focus load", ok_focus)

if ok_focus then
	local ghostty_sockets = smart_focus.socket_candidates("/run/user/1000", 789)
	expect(
		"Ghostty uses pid socket",
		#ghostty_sockets == 1 and ghostty_sockets[1] == "/run/user/1000/nvim-smart-focus-789.sock"
	)
	expect(
		"smart focus parses process start time",
		smart_focus.parse_proc_start_time("789 (nvim) S 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 4242") == "4242"
	)
	expect(
		"expired smart focus requests are rejected",
		smart_focus.request({ direction = "left", deadline = 0 }).status == "stale"
	)
	expect(
		"invalid smart focus requests are rejected",
		smart_focus.request({ direction = "sideways" }).status == "blocked"
	)

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

-- Keep this contract focused on runtime integration that Nix evaluation cannot
-- prove. Plugin presence and declarative option values belong to Nix itself.
local dap = require("dap")
expect("DAP UI opens on launch", type(dap.listeners.before.launch.juicy_dapui) == "function")
expect("DAP UI closes on exit", type(dap.listeners.before.event_exited.juicy_dapui) == "function")

-- Exercise the user-facing formatting path without requiring an LSP client.
local fixture = vim.fn.tempname()
vim.fn.mkdir(fixture .. "/.git", "p")
vim.fn.mkdir(fixture .. "/src", "p")
local lua_file = fixture .. "/src/format.lua"
vim.fn.writefile({ "local x={1,2}" }, lua_file)
vim.cmd.edit(vim.fn.fnameescape(lua_file))
local format_map = vim.fn.maparg("<leader>cf", "n", false, true)
expect("manual format available without LSP", type(format_map.callback) == "function")
if type(format_map.callback) == "function" then
	format_map.callback()
	local manual = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	expect("manual format uses configured formatter", manual[1] == "local x = { 1, 2 }")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, { "local x={1,2}" })
	vim.cmd.write()
	expect("save and manual formatting agree", vim.deep_equal(vim.fn.readfile(lua_file), manual))
	vim.g.disable_autoformat = true
	vim.api.nvim_buf_set_lines(0, 0, -1, false, { "local x={1,2}" })
	vim.cmd.write()
	expect("disabled autoformat preserves save", vim.fn.readfile(lua_file)[1] == "local x={1,2}")
	vim.g.disable_autoformat = nil
end

local project = require("juicy.project")
expect("project root follows file outside cwd", project.root() == fixture)
local client = { config = { root_dir = fixture, settings = { nixd = {} } } }
client.notify = function() end
local original_flake = vim.env.FLAKE
vim.env.FLAKE = fixture .. "/unrelated"
project.configure_nixd(client)
expect("unrelated Nix project has no host options", client.config.settings.nixd.options == nil)
vim.env.FLAKE = fixture
project.configure_nixd(client)
expect("configured flake gets host options", client.config.settings.nixd.options.leo ~= nil)
vim.env.FLAKE = original_flake

local links = require("juicy.links")
expect("URL punctuation preserved", links.normalize("https://example.org/a(b);") == "https://example.org/a(b);")
expect(
	"balanced Markdown URL",
	links.markdown_link_at("[link](https://example.org/a(b))", 3) == "https://example.org/a(b)"
)
local original_open = vim.ui.open
links.setup("unused-opener")
expect("native ui.open remains intact", vim.ui.open == original_open)

local notes = require("juicy.notes")
expect("Unicode note title preserved", notes.slug("中文 笔记") == "中文-笔记")
expect("note slug cannot escape directory", not notes.slug("../../test"):find("/", 1, true))

vim.keymap.set("n", "<leader>zz", function() end, { buffer = true, desc = "Fixture buffer action" })
local reference = require("juicy.reference")
local reference_text = table.concat(reference.lines(0), "\n")
expect("reference includes buffer mappings", reference_text:find("Fixture buffer action", 1, true) ~= nil)
reference.open()
expect("reference opens without managed notes file", vim.bo.buftype == "nofile")
reference.open()

if #failures > 0 then
	vim.api.nvim_err_writeln("NixVim runtime contract failed:\n- " .. table.concat(failures, "\n- "))
	vim.cmd.cquit(1)
end

local failures = {}

local function expect(name, condition)
	if not condition then
		table.insert(failures, name)
	end
end

for _, command in ipairs({
	"Neorg",
	"NotesNew",
	"NotesInbox",
	"NotesOpenIndex",
	"NotesToday",
	"NotesTomorrow",
	"NotesYesterday",
	"NotesFind",
	"NotesGrep",
	"NotesAgenda",
	"NotesBacklinks",
	"NotesTags",
	"NotesInsertLink",
	"NotesCalendar",
}) do
	expect(command .. " command", vim.fn.exists(":" .. command) == 2)
end

expect("norg parser", pcall(vim.treesitter.language.add, "norg"))
expect("norg_meta parser", pcall(vim.treesitter.language.add, "norg_meta"))

local ok_neorg, neorg = pcall(require, "neorg")
expect("neorg module", ok_neorg)

if ok_neorg then
	for _, module in ipairs({
		"core.completion",
		"core.dirman",
		"core.export.markdown",
		"core.journal",
		"core.qol.todo_items",
		"core.tangle",
		"external.interim-ls",
	}) do
		expect(module .. " loaded", neorg.modules.is_module_loaded(module))
	end

	local dirman = neorg.modules.get_module("core.dirman")
	local workspace = dirman and dirman.get_current_workspace()
	expect("notes workspace active", workspace and workspace[1] == "notes")
	expect("notes workspace path", workspace and tostring(workspace[2]) == vim.fn.expand("~/documents/notes"))
end

local source = vim.fn.tempname() .. ".norg"
vim.fn.writefile({ "* Neorg Setup" }, source)
vim.cmd.edit(vim.fn.fnameescape(source))
expect("norg filetype", vim.bo.filetype == "norg")
expect("norg buffer parser", pcall(vim.treesitter.get_parser, 0, "norg"))

vim.wait(2000, function()
	return #vim.lsp.get_clients({ bufnr = 0, name = "neorg-interim-ls" }) == 1
end, 20)
expect("Neorg completion LSP attached", #vim.lsp.get_clients({ bufnr = 0, name = "neorg-interim-ls" }) == 1)

local task_map = vim.fn.maparg("<leader>ntd", "n", false, true)
expect("norg ftplugin loaded", task_map.buffer == 1 and task_map.desc == "Done")

if #failures > 0 then
	vim.api.nvim_err_writeln("NixVim Neorg setup contract failed:\n- " .. table.concat(failures, "\n- "))
	vim.cmd.cquit(1)
end

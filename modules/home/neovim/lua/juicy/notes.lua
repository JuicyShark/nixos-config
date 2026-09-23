local M = {}

local function root()
	return vim.fn.expand("~/documents/notes")
end

local function ensure()
	local notes_root = root()
	vim.fn.mkdir(notes_root .. "/pages", "p")
	vim.fn.mkdir(notes_root .. "/journal", "p")
	return notes_root
end

local function empty_buffer()
	return vim.api.nvim_buf_line_count(0) == 1 and vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == ""
end

local function open_with_template(path, lines)
	local exists = vim.fn.filereadable(path) == 1
	vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
	vim.cmd.edit(vim.fn.fnameescape(path))

	if not exists and empty_buffer() then
		vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
		vim.cmd.normal({ args = { "G" }, bang = true })
	end
end

local function picker(method, options)
	local snacks = rawget(_G, "Snacks")
	if snacks and snacks.picker and snacks.picker[method] then
		snacks.picker[method](options)
		return
	end

	vim.notify("Snacks picker is unavailable", vim.log.levels.WARN)
end

function M.slug(title)
	-- Preserve UTF-8 titles while excluding path separators and link syntax.
	local slug = title
		:lower()
		:gsub("[%z\1-\31/\\:%[%]{}]", "")
		:gsub("%s+", "-")
		:gsub("-+", "-")
		:gsub("^[-.]+", "")
		:gsub("[-.]+$", "")

	return slug ~= "" and slug or os.date("%Y%m%d%H%M%S")
end

function M.new(opts)
	local title = opts.args ~= "" and opts.args or vim.fn.input("note> ")
	if not title or title == "" then
		return
	end

	open_with_template(ensure() .. "/pages/" .. M.slug(title) .. ".norg", {
		"@document.meta",
		"title: " .. title,
		"created: " .. os.date("%Y-%m-%d"),
		"categories: [note]",
		"@end",
		"",
		"* " .. title,
		"",
	})
end

function M.inbox(opts)
	local text = opts.args ~= "" and opts.args or vim.fn.input("inbox> ")
	if not text or text == "" then
		return
	end

	local path = ensure() .. "/inbox.norg"
	if vim.fn.filereadable(path) == 0 then
		vim.fn.writefile({
			"@document.meta",
			"title: Inbox",
			"created: " .. os.date("%Y-%m-%d"),
			"categories: [inbox]",
			"@end",
			"",
			"* Inbox",
			"",
		}, path)
	end

	vim.fn.writefile({ "- ( ) " .. text }, path, "a")
	vim.cmd.edit(vim.fn.fnameescape(path))
	vim.cmd.normal({ args = { "G" }, bang = true })
end

function M.index()
	open_with_template(ensure() .. "/index.norg", {
		"@document.meta",
		"title: Notes",
		"created: " .. os.date("%Y-%m-%d"),
		"categories: [index]",
		"@end",
		"",
		"* Notes",
		"",
	})
end

function M.journal(period)
	vim.cmd("Neorg journal " .. period)
end

function M.find()
	picker("files", {
		cwd = ensure(),
		hidden = true,
		ignored = true,
		title = "Notes",
	})
end

function M.grep()
	picker("grep", {
		cwd = ensure(),
		hidden = true,
		ignored = true,
		title = "Search notes",
	})
end

function M.agenda()
	picker("grep", {
		cwd = ensure(),
		hidden = true,
		ignored = true,
		search = [[TODO|DONE|WAIT|HOLD|CANCEL|DEADLINE|SCHEDULED|\([ xX_\-=!+?]\)|<\d{4}-\d{2}-\d{2}>]],
		title = "Notes agenda",
	})
end

function M.backlinks()
	local path = vim.api.nvim_buf_get_name(0)
	local relative = vim.fs.relpath(root(), path)
	if not relative or relative:match("^%.%.") or not relative:match("%.norg$") then
		vim.notify("Open a note in the notes workspace first", vim.log.levels.INFO)
		return
	end
	local target = relative:gsub("%.norg$", "")
	picker("grep", {
		cwd = ensure(),
		hidden = true,
		ignored = true,
		search = "{:" .. target .. ":}",
		regex = false,
		title = "Backlinks",
	})
end

function M.tags()
	picker("grep", {
		cwd = ensure(),
		hidden = true,
		ignored = true,
		search = [[#\w+|categories:]],
		title = "Note tags",
	})
end

function M.insert_link()
	local source = vim.api.nvim_get_current_buf()
	picker("files", {
		cwd = ensure(),
		ft = "norg",
		title = "Insert note link",
		confirm = function(p, item)
			p:close()
			if not item or not vim.api.nvim_buf_is_valid(source) then
				return
			end
			local file = Snacks.picker.util.path(item)
			local relative = file and vim.fs.relpath(root(), file)
			if not relative or relative:match("^%.%.") then
				return
			end
			local target = relative:gsub("%.norg$", "")
			local label = vim.fn.fnamemodify(target, ":t"):gsub("[%[%]]", "")
			vim.api.nvim_buf_call(source, function()
				vim.api.nvim_put({ "{:" .. target .. ":}[" .. label .. "]" }, "c", true, true)
			end)
		end,
	})
end

function M.calendar()
	local ok, neorg = pcall(require, "neorg.core")
	if not ok or not neorg.modules.is_module_loaded("core.ui.calendar") then
		vim.notify("Neorg calendar is unavailable", vim.log.levels.WARN)
		return
	end

	neorg.modules.get_module("core.ui.calendar").open({})
end

function M.reference()
	require("juicy.reference").open()
end

function M.setup()
	local commands = {
		NotesOpenIndex = { M.index, "Open notes index" },
		NotesToday = {
			function()
				M.journal("today")
			end,
			"Open today's journal",
		},
		NotesTomorrow = {
			function()
				M.journal("tomorrow")
			end,
			"Open tomorrow's journal",
		},
		NotesYesterday = {
			function()
				M.journal("yesterday")
			end,
			"Open yesterday's journal",
		},
		NotesFind = { M.find, "Find notes" },
		NotesGrep = { M.grep, "Search notes" },
		NotesAgenda = { M.agenda, "Search agenda items" },
		NotesBacklinks = { M.backlinks, "Search note backlinks" },
		NotesTags = { M.tags, "Search note tags" },
		NotesInsertLink = { M.insert_link, "Insert Neorg note link" },
		NotesCalendar = { M.calendar, "Open Neorg calendar" },
		NeovimIdeReference = { M.reference, "Open Neovim IDE reference" },
	}

	vim.api.nvim_create_user_command("NotesNew", M.new, {
		nargs = "?",
		desc = "Create or open a note",
	})
	vim.api.nvim_create_user_command("NotesInbox", M.inbox, {
		nargs = "?",
		desc = "Capture a task to the notes inbox",
	})

	for name, command in pairs(commands) do
		vim.api.nvim_create_user_command(name, command[1], { desc = command[2] })
	end
end

return M

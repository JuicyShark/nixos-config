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
	local slug = title:lower():gsub("[^%w%s-]", ""):gsub("%s+", "-"):gsub("-+", "-"):gsub("^-", ""):gsub("-$", "")

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
	local stem = vim.fn.expand("%:t:r")
	picker("grep", {
		cwd = ensure(),
		hidden = true,
		ignored = true,
		search = stem ~= "" and stem or nil,
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
	local title = vim.fn.input("link> ")
	if not title or title == "" then
		return
	end

	vim.api.nvim_put({ "{:pages/" .. M.slug(title) .. ":}[" .. title .. "]" }, "c", true, true)
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
	local existing = vim.g.neovim_ide_reference_win
	if existing and vim.api.nvim_win_is_valid(existing) then
		vim.api.nvim_win_close(existing, true)
		vim.g.neovim_ide_reference_win = nil
		return
	end

	local path = root() .. "/pages/neovim-ide-cheatsheet.norg"
	local lines = vim.fn.filereadable(path) == 1 and vim.fn.readfile(path)
		or {
			"* Neovim IDE Cheatsheet",
			"",
			"The managed cheatsheet file has not been activated into ~/documents/notes yet.",
		}
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(buf, "neovim-ide-reference")
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].filetype = "norg"
	vim.bo[buf].modifiable = false

	local columns = vim.o.columns
	local rows = vim.o.lines
	local width = math.min(math.max(50, math.floor(columns * 0.38)), columns - 4)
	local height = math.min(28, rows - 4, #lines)
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		anchor = "NE",
		row = 1,
		col = columns - 2,
		width = width,
		height = height,
		border = "rounded",
		style = "minimal",
		title = " IDE Reference ",
		title_pos = "center",
	})

	vim.g.neovim_ide_reference_win = win
	vim.wo[win].conceallevel = 2
	vim.wo[win].wrap = true
	vim.wo[win].linebreak = true
	vim.wo[win].number = false
	vim.wo[win].relativenumber = false
	for _, key in ipairs({ "q", "<Esc>" }) do
		vim.keymap.set("n", key, "<cmd>close<CR>", {
			buffer = buf,
			silent = true,
			nowait = true,
		})
	end
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

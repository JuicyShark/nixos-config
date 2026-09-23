local M = {}
local window

function M.lines(bufnr)
	local lines = {
		"Neovim reference",
		"",
		"Arrows: move | Ctrl+arrows: editor splits | Super+arrows: desktop focus",
		"Zellij: Ctrl+g unlocks its controls; Esc locks them again.",
		"Files: current directory | Project: root of the current file's project",
		"Format: Space cf | Formatter status: Space cF",
		"Help tags: Space hh | This reference: Space hk",
		"",
		"Active mappings (buffer mappings override global mappings)",
		"",
	}
	local entries = {}
	for _, mode in ipairs({ "n", "x", "i", "t" }) do
		local maps = {}
		for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
			maps[map.lhs] = map
		end
		for _, map in ipairs(vim.api.nvim_buf_get_keymap(bufnr, mode)) do
			maps[map.lhs] = map
		end
		for lhs, map in pairs(maps) do
			if map.desc and map.desc ~= "Disabled" then
				entries[#entries + 1] = string.format("%-2s %-24s %s", mode, lhs, map.desc)
			end
		end
	end
	table.sort(entries)
	vim.list_extend(lines, entries)
	return lines
end

function M.open()
	if window and vim.api.nvim_win_is_valid(window) then
		vim.api.nvim_win_close(window, true)
		window = nil
		return
	end
	local lines = M.lines(vim.api.nvim_get_current_buf())
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].modifiable = false
	local width = math.max(1, math.min(100, vim.o.columns - 4))
	local height = math.max(1, math.min(#lines, vim.o.lines - 4))
	window = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		row = 1,
		col = math.max(0, math.floor((vim.o.columns - width) / 2)),
		width = width,
		height = height,
		border = "rounded",
		style = "minimal",
		title = " Editor reference ",
	})
	vim.wo[window].wrap = false
	for _, key in ipairs({ "q", "<Esc>" }) do
		vim.keymap.set("n", key, "<cmd>close<CR>", { buffer = buf, silent = true, nowait = true })
	end
end

return M

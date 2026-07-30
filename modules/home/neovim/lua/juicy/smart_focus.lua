local M = {}

local directions = {
	left = "h",
	down = "j",
	up = "k",
	right = "l",
}

function M.move(direction)
	local key = directions[direction]
	if not key then
		return 0
	end

	local current = vim.api.nvim_get_current_win()
	local target = vim.fn.win_getid(vim.fn.winnr(key))
	if target == 0 or target == current then
		return 0
	end

	vim.api.nvim_set_current_win(target)
	return 1
end

function M.socket_candidates(runtime_dir, nvim_pid)
	if not runtime_dir or runtime_dir == "" then
		return {}
	end

	return { runtime_dir .. "/nvim-smart-focus-" .. tostring(nvim_pid) .. ".sock" }
end

function M.start()
	local rt = vim.env.XDG_RUNTIME_DIR
	local sockets = M.socket_candidates(rt, vim.fn.getpid())
	if #sockets == 0 then
		return {}
	end

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

	return started
end

return M

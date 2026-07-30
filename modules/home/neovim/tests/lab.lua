local M = {}

local function smart_focus_report()
	local sockets = {}
	local ok, smart_focus = pcall(require, "juicy.smart_focus")
	if ok then
		sockets = smart_focus.socket_candidates(vim.env.XDG_RUNTIME_DIR, vim.fn.getpid())
	end

	local lines = {
		"# Smart Focus",
		"",
		"Active server: " .. tostring(vim.g.smart_focus_server or "not started"),
		"XDG_RUNTIME_DIR: " .. tostring(vim.env.XDG_RUNTIME_DIR or "unset"),
		"",
		"## Candidate Sockets",
	}
	for _, socket in ipairs(sockets) do
		table.insert(lines, "- " .. socket .. " exists=" .. tostring(vim.uv.fs_stat(socket) ~= nil))
	end

	vim.cmd("botright split")
	vim.bo.buftype = "nofile"
	vim.bo.bufhidden = "wipe"
	vim.bo.swapfile = false
	vim.api.nvim_buf_set_name(0, "juicy-smart-focus-report")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
	vim.bo.filetype = "markdown"
end

function M.setup()
	vim.api.nvim_create_user_command("JuicyLabSmartFocus", smart_focus_report, {})
end

M.setup()

return M

local M = {}
local directions = { left = "h", down = "j", up = "k", right = "l" }
local generation = 0
local suspended = false
local publish = function() end

local function process(pid)
	local ok, lines = pcall(vim.fn.readfile, "/proc/" .. tostring(pid) .. "/stat", "", 1)
	if not ok or not lines[1] then
		return nil
	end
	local fields = vim.split(lines[1]:match("^%d+ %(.+%) (.+)$") or "", "%s+")
	if not fields[20] then
		return nil
	end
	return {
		pid = pid,
		state = fields[1],
		pgrp = tonumber(fields[3]),
		tty = tonumber(fields[5]),
		foreground = tonumber(fields[6]),
		start = fields[20],
	}
end

local function terminal_ui()
	local found
	for _, ui in ipairs(vim.api.nvim_list_uis()) do
		local client = vim.api.nvim_get_chan_info(ui.chan).client or {}
		local pid = client.attributes and tonumber(client.attributes.pid)
		local p = client.name == "nvim-tui" and pid and process(pid)
		if p and p.tty ~= 0 then
			if found then
				return nil
			end -- multiple terminal UIs need explicit routing
			found = p
		end
	end
	return found
end

function M.parse_proc_start_time(stat)
	local fields = stat and stat:match("^%d+ %(.+%) (.+)$")
	return fields and vim.split(fields, "%s+")[20] or nil
end

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
	return vim.api.nvim_get_current_win() == target and 1 or -1
end

function M.socket_candidates(runtime_dir, pid)
	if not runtime_dir or runtime_dir == "" then
		return {}
	end
	return { runtime_dir .. "/nvim-smart-focus-" .. tostring(pid) .. ".sock" }
end

function M.request(request)
	local uv = vim.uv or vim.loop
	if type(request) ~= "table" or not directions[request.direction] then
		return { status = "blocked" }
	end
	if type(request.deadline) ~= "number" or uv.hrtime() / 1e9 >= request.deadline then
		return { status = "stale" }
	end
	if not request.instance:match("^[%w_.-]+$") then
		return { status = "stale" }
	end
	local path = vim.env.XDG_RUNTIME_DIR .. "/smart-focus/" .. request.instance .. "/context"
	local ok, lines = pcall(vim.fn.readfile, path, "", 1)
	if not ok or lines[1] ~= request.context or request.focus_generation ~= generation then
		return { status = "stale" }
	end
	local p = process(vim.fn.getpid())
	local ui = terminal_ui()
	if
		not p
		or p.pid ~= request.pid
		or p.start ~= request.start
		or not ui
		or ui.pid ~= request.ui_pid
		or ui.start ~= request.ui_start
		or ui.pgrp ~= ui.foreground
		or suspended
	then
		return { status = "stale" }
	end
	local mode = vim.api.nvim_get_mode()
	local win = vim.api.nvim_get_current_win()
	local config = vim.api.nvim_win_get_config(win)
	if mode.blocking or mode.mode:match("^[cr!]") or config.relative ~= "" then
		return { status = "blocked" }
	end
	if request.operation == "cwd" then
		return { status = "cwd", cwd = vim.fn.getcwd() }
	end
	local moved_ok, moved = pcall(M.move, request.direction)
	if not moved_ok or moved == -1 then
		return { status = "unknown" }
	end
	return { status = moved == 1 and "moved" or "edge" }
end

function M.start(opts)
	opts = opts or {}
	local rt, pid = vim.env.XDG_RUNTIME_DIR, vim.fn.getpid()
	local p = process(pid)
	if not rt or not p then
		return {}
	end
	local uv = vim.uv or vim.loop
	local socket = M.socket_candidates(rt, pid)[1]
	if vim.g.smart_focus_server == socket then
		return { socket }
	end
	pcall(uv.fs_unlink, socket)
	if not pcall(vim.fn.serverstart, socket) then
		return {}
	end
	vim.g.smart_focus_server = socket
	local directory = rt .. "/smart-focus/editors"
	vim.fn.mkdir(directory, "p", 448)
	local registration = directory .. "/" .. tostring(pid) .. ".json"
	local registered_ui
	publish = function()
		local current = process(pid)
		local ui = terminal_ui()
		if not current or not ui then
			pcall(uv.fs_unlink, registration)
			return
		end
		local record = {
			version = 3,
			pid = pid,
			start = current.start,
			tty = ui.tty,
			ui_pid = ui.pid,
			ui_start = ui.start,
			socket = socket,
			focus_generation = generation,
			session = vim.env.ZELLIJ_SESSION_NAME,
			pane = vim.env.ZELLIJ_PANE_ID,
		}
		local temp = registration .. ".tmp"
		if vim.fn.writefile({ vim.json.encode(record) }, temp) == 0 then
			uv.fs_rename(temp, registration)
		end
		if opts.broker and not vim.env.ZELLIJ and registered_ui ~= ui.pid then
			registered_ui = ui.pid
			vim.system({ opts.broker, "register-terminal", tostring(ui.pid) }, { detach = true })
		end
	end
	local group = vim.api.nvim_create_augroup("JuicySmartFocus", { clear = true })
	vim.api.nvim_create_autocmd(
		{ "UIEnter", "UILeave", "WinEnter", "TabEnter", "FocusGained", "FocusLost", "ModeChanged" },
		{
			group = group,
			callback = function()
				generation = generation + 1
				publish()
			end,
		}
	)
	vim.api.nvim_create_autocmd("VimSuspend", {
		group = group,
		callback = function()
			suspended = true
			generation = generation + 1
			publish()
		end,
	})
	vim.api.nvim_create_autocmd("VimResume", {
		group = group,
		callback = function()
			suspended = false
			generation = generation + 1
			publish()
		end,
	})
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = group,
		callback = function()
			pcall(uv.fs_unlink, registration)
			pcall(uv.fs_unlink, socket)
		end,
	})
	publish()
	return { socket }
end

return M

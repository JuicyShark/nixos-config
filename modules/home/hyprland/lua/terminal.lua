return function(ctx, opts)
	local hl = ctx.hl
	opts = opts or {}

	local fallback = opts.fallback
	local working_directory_flag = opts.workingDirectoryFlag

	local terminal_classes = {
		["com.mitchellh.ghostty"] = true,
	}

	local function shell_quote(value)
		return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
	end

	local function open_terminal()
		local active = hl.get_active_window and hl.get_active_window()

		if fallback then
			local cwd = active and terminal_classes[active.class or ""] and ctx.cwd and ctx.cwd.forWindow(active)
			local command = fallback
			if cwd and working_directory_flag then
				command = command .. " " .. working_directory_flag .. "=" .. shell_quote(cwd)
			end
			hl.exec_cmd(command)
		end
	end

	_G.Juicy = _G.Juicy or {}
	_G.Juicy.terminal = {
		open = open_terminal,
	}
end

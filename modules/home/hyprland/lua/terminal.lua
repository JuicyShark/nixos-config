return function(ctx, opts)
	local hl = ctx.hl
	opts = opts or {}

	local fallback = opts.fallback
	local home = assert(opts.home, "terminal home directory is required")
	local working_directory_flag = opts.workingDirectoryFlag
	local inherit_shortcut = opts.inheritShortcut or {
		mods = "CTRL ALT",
		key = "Return",
	}
	local terminal_classes = {
		["com.mitchellh.ghostty"] = true,
	}

	local function shell_quote(value)
		return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
	end

	local function is_terminal(window)
		return window and terminal_classes[window.class or ""] == true
	end

	local function check_result(result)
		if type(result) == "table" and result.ok == false then
			error(result.error or "Unable to open terminal", 0)
		end
	end

	local function open_terminal(spec)
		spec = spec or {}
		local active = hl.get_active_window and hl.get_active_window()
		local has_explicit_request = spec.command or spec.cwd or #(spec.args or {}) > 0

		-- Ghostty is a single process for all of its windows, so compositor-side
		-- process-tree inspection cannot identify the selected surface reliably.
		-- Let Ghostty's own new_window action inherit from the focused surface.
		if not has_explicit_request and is_terminal(active) then
			check_result(hl.dispatch(hl.dsp.send_shortcut({
				mods = inherit_shortcut.mods,
				key = inherit_shortcut.key,
				window = active,
			})))
			return true
		end

		local command = spec.command or fallback
		if command then
			local cwd = spec.cwd or home
			if cwd and working_directory_flag then
				command = command .. " " .. working_directory_flag .. "=" .. shell_quote(cwd)
			end
			for _, argument in ipairs(spec.args or {}) do
				command = command .. " " .. shell_quote(argument)
			end
			check_result(hl.exec_cmd(command))
			return true
		end
		return false
	end

	ctx.terminal = {
		isWindow = is_terminal,
		open = open_terminal,
	}
	_G.Juicy = _G.Juicy or {}
	_G.Juicy.terminal = ctx.terminal
end

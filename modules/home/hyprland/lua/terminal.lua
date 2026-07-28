return function(ctx, opts)
	local hl = ctx.hl
	opts = opts or {}

	local terminal = opts.terminal
	local fallback = opts.fallback
	local remote_control = opts.remoteControl == true

	local kitty_classes = {
		kitty = true,
		pinned = true,
	}

	local function open_terminal()
		local active = hl.get_active_window and hl.get_active_window()
		local pid = active and tonumber(active.pid) or nil
		local rt = os.getenv("XDG_RUNTIME_DIR")

		if remote_control and terminal and rt and pid and active and kitty_classes[active.class or ""] then
			hl.exec_cmd(
				terminal
					.. " @ --to unix:"
					.. rt
					.. "/kitty-"
					.. tostring(pid)
					.. " launch --type=os-window --cwd=current"
			)
			return
		end

		if fallback then
			hl.exec_cmd(fallback)
		end
	end

	_G.Juicy = _G.Juicy or {}
	_G.Juicy.terminal = {
		open = open_terminal,
	}
end

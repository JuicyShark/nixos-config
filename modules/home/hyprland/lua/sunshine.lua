-- ============================================================
-- SUNSHINE STREAM ROUTING
-- ============================================================
return function(ctx)
	local hl = ctx.hl
	local sunshine = ctx.cfg.sunshine or {}

	if not sunshine.enable then
		return
	end

	local streamMonitor = sunshine.virtualMonitor or "HDMI-A-1"
	local streamSteamWorkspace = sunshine.steamWorkspace or "21"
	local streamGameWorkspace = sunshine.gameWorkspace or sunshine.virtualWorkspace or "22"

	local function window_selector(window)
		if not window or not window.address then
			return nil
		end
		return "address:" .. tostring(window.address)
	end

	local function window_workspace(window)
		return window and window.workspace and window.workspace.name or nil
	end

	local function stream_monitor_active()
		for _, monitor in ipairs(hl.get_monitors() or {}) do
			if monitor.name == streamMonitor then
				return true
			end
		end
		return false
	end

	local function is_steam_window(window)
		return window and window.class == "steam"
	end

	local function is_game_window(window)
		if not window then
			return false
		end
		local class = window.class or ""
		local title = window.title or ""
		local initial_title = window.initial_title or ""
		return class:match("^steam_app_[0-9]+$")
			or class == "gamescope"
			or class == "Slay the Spire 2"
			or class == "Balatro"
			or title == "Slay the Spire 2"
			or title == "Balatro"
			or initial_title == "Slay the Spire 2"
			or initial_title == "Balatro"
			or initial_title == "World of Warcraft"
	end

	local function move_window(window, workspace)
		local selector = window_selector(window)
		if not selector or window_workspace(window) == workspace then
			return
		end
		hl.dispatch(hl.dsp.window.move({ workspace = workspace, silent = true, window = selector }))
	end

	local function reconcile_stream_windows()
		local active = stream_monitor_active()
		if active then
			hl.dispatch(hl.dsp.workspace.move({ workspace = streamSteamWorkspace, monitor = streamMonitor }))
			hl.dispatch(hl.dsp.workspace.move({ workspace = streamGameWorkspace, monitor = streamMonitor }))
		end

		for _, window in ipairs(hl.get_windows() or {}) do
			local ws = window_workspace(window)
			if active then
				if is_game_window(window) then
					move_window(window, streamGameWorkspace)
				elseif is_steam_window(window) then
					move_window(window, streamSteamWorkspace)
				end
			else
				if ws == streamGameWorkspace then
					move_window(window, "5")
				elseif ws == streamSteamWorkspace and is_steam_window(window) then
					move_window(window, "special:steam")
				elseif ws == streamSteamWorkspace then
					move_window(window, "5")
				end
			end
		end
	end

	hl.on("hyprland.start", reconcile_stream_windows)
	hl.on("monitor.added", reconcile_stream_windows)
	hl.on("monitor.removed", reconcile_stream_windows)
	hl.on("window.open_early", reconcile_stream_windows)
	hl.on("window.move_to_workspace", reconcile_stream_windows)
end

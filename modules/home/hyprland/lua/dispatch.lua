return function(ctx, opts)
	local hl = ctx.hl
	opts = opts or {}
	local presets = opts.presets or {}
	local pendingLaunches = {}
	local pip = {}

	local function dispatch_action(action)
		local result
		if type(action) == "function" then
			result = action()
		elseif action then
			result = hl.dispatch(action)
		end
		if type(result) == "table" and result.ok == false then
			error(result.error or "Desktop action failed", 0)
		end
		return result
	end

	local api = {}

	local function workspace_selector(workspace)
		if not workspace then
			return nil
		end
		if tonumber(workspace.id) and workspace.id > 0 then
			return tostring(workspace.id)
		end
		return workspace.config_name or workspace.name
	end

	local function apply_config(spec)
		for section, values in pairs(spec or {}) do
			hl.config({ [section] = values })
		end
	end

	function api.bind(action, opts)
		opts = opts or {}
		return function()
			local ok, result = pcall(dispatch_action, action)
			if opts.reset then
				hl.dispatch(hl.dsp.submap(opts.reset))
			end
			if not ok then
				if ctx.feedback then
					ctx.feedback.notify("Desktop action", tostring(result), "critical")
				else
					print("[desktop action] " .. tostring(result))
				end
				return
			end
			return result
		end
	end

	function api.layout(actions, opts)
		opts = opts or {}
		return api.bind(function()
			local layout = api.currentLayout()
			if not layout or not actions[layout] then
				error("Action unavailable in " .. tostring(layout or "this workspace") .. " layout", 0)
			end
			return dispatch_action(actions[layout])
		end, opts)
	end

	function api.focusOrSpawn(match, command)
		return function()
			local windows = hl.get_windows(match) or {}
			local target = nil
			local targetTier = math.huge
			local targetHistory = math.huge
			for _, window in ipairs(windows) do
				local tier = window.active and 0 or (window.mapped ~= false and not window.hidden and 1 or 2)
				local history = tonumber(window.focus_history_id)
				if not history or history < 0 then
					history = math.huge
				end
				if
					window.mapped ~= false
					and (not target or tier < targetTier or (tier == targetTier and history < targetHistory))
				then
					target = window
					targetTier = tier
					targetHistory = history
				end
			end

			if target then
				if command then
					pendingLaunches[command] = nil
				end
				-- Native focus reveals grouped windows and special workspaces.
				return dispatch_action(hl.dsp.focus({ window = target }))
			elseif command and command ~= "" and not pendingLaunches[command] then
				local token = {}
				pendingLaunches[command] = token
				hl.timer(function()
					if pendingLaunches[command] == token then
						pendingLaunches[command] = nil
					end
				end, { timeout = 3000, type = "oneshot" })
				local ok, err = pcall(hl.exec_cmd, command)
				if not ok or (type(err) == "table" and err.ok == false) then
					pendingLaunches[command] = nil
					error(type(err) == "table" and err.error or err, 0)
				end
			end
		end
	end

	function api.currentWorkspace()
		local special = hl.get_active_special_workspace()
		if special then
			return special
		end
		return hl.get_active_workspace()
	end

	local function monitor_geometry(monitor)
		if not monitor then
			return nil
		end
		return table.concat({
			monitor.name,
			tostring(monitor.x),
			tostring(monitor.y),
			tostring(monitor.width),
			tostring(monitor.height),
			tostring(monitor.scale),
		}, ":")
	end

	function api.togglePip()
		local window = hl.get_active_window()
		if not window then
			return
		end
		if (window.fullscreen or 0) ~= 0 then
			error("Leave fullscreen before toggling picture in picture", 0)
		end
		local key = window.stable_id or window.address
		local saved = pip[key]
		if saved then
			dispatch_action(hl.dsp.window.pin({ window = window, action = "disable" }))
			dispatch_action(hl.dsp.window.float({ window = window, action = saved.floating and "enable" or "disable" }))
			-- Don't restore old coordinates after moving outputs or changing their geometry.
			if saved.floating and saved.monitor == monitor_geometry(window.monitor) then
				if saved.width and saved.height then
					dispatch_action(hl.dsp.window.resize({ window = window, x = saved.width, y = saved.height }))
				end
				if saved.x and saved.y then
					dispatch_action(hl.dsp.window.move({ window = window, x = saved.x, y = saved.y }))
				end
			end
			if saved.pinned then
				dispatch_action(hl.dsp.window.pin({ window = window, action = "enable" }))
			end
			pip[key] = nil
		elseif window.pinned then
			-- Also gives an already-pinned window a safe exit after a config reload.
			dispatch_action(hl.dsp.window.pin({ window = window, action = "disable" }))
		else
			pip[key] = {
				floating = window.floating,
				pinned = window.pinned,
				monitor = monitor_geometry(window.monitor),
				x = type(window.at) == "table" and window.at.x or nil,
				y = type(window.at) == "table" and window.at.y or nil,
				width = type(window.size) == "table" and window.size.x or nil,
				height = type(window.size) == "table" and window.size.y or nil,
			}
			dispatch_action(hl.dsp.window.float({ window = window, action = "enable" }))
			dispatch_action(hl.dsp.window.pin({ window = window, action = "enable" }))
		end
	end

	hl.on("window.close", function(window)
		if window then
			pip[window.stable_id or window.address] = nil
		end
	end)

	function api.currentLayout()
		local workspace = api.currentWorkspace()
		return workspace and workspace.tiled_layout or nil
	end

	function api.setCurrentLayout(layout)
		local workspace = api.currentWorkspace()
		if workspace and layout then
			if workspace.monitor and workspace.monitor.name == opts.monocleMonitor then
				if layout ~= "monocle" then
					error("This output always uses monocle layout", 0)
				end
				return
			end
			hl.workspace_rule({ workspace = workspace_selector(workspace), layout = layout })
			if opts.monocleMonitor and opts.monocleMonitor ~= "" then
				-- A newly added workspace rule comes after the static output rule.
				-- Pair it with a later TV override so moving it to HDMI stays monocle.
				local selector = workspace.id
						and workspace.id > 0
						and string.format("r[%d-%d]", workspace.id, workspace.id)
					or "n[s:" .. workspace.name .. "]"
				hl.workspace_rule({
					workspace = selector .. " m[" .. opts.monocleMonitor .. "]",
					layout = "monocle",
				})
			end
		end
	end

	function api.toggleCenteredFocus()
		local centered = hl.get_config("scrolling.focus_fit_method")
		if centered == 1 then
			hl.config({ scrolling = { focus_fit_method = 0 } })
		else
			hl.config({ scrolling = { focus_fit_method = 1 } })
		end
	end

	function api.gaplessPreset()
		apply_config(presets.gapless)
	end

	function api.defaultPreset()
		apply_config(presets.default)
	end

	_G.Juicy = _G.Juicy or {}
	_G.Juicy.dispatch = api
	_G.Juicy.layout = api
end

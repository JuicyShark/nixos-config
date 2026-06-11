-- ============================================================
-- SPECIAL APPS
-- ============================================================
return function(ctx)
	local hl = ctx.hl

	local function window_selector(window)
		if not window or not window.address then
			return nil
		end
		return "address:" .. tostring(window.address)
	end

	local function window_workspace(window)
		return window and window.workspace and window.workspace.name or nil
	end

	local function window_matches(window, match)
		if type(match) == "function" then
			return match(window)
		end
		if not window or not match then
			return false
		end
		for key, pattern in pairs(match) do
			local value = window[key]
			if not value or not tostring(value):match(pattern) then
				return false
			end
		end
		return true
	end

	local function find_matching_window(match, workspace)
		local fallback = nil
		for _, window in ipairs(hl.get_windows() or {}) do
			if window_matches(window, match) then
				if window_workspace(window) == workspace then
					return window
				end
				fallback = fallback or window
			end
		end
		return fallback
	end

	ctx.apps = ctx.apps or {}
	ctx.apps.openSpecial = function(spec)
		local workspace = "special:" .. spec.name
		if hl.get_active_special_workspace then
			local active = hl.get_active_special_workspace()
			if active and active.name == workspace then
				hl.dispatch(hl.dsp.workspace.toggle_special(spec.name))
				return
			end
		end

		local window = find_matching_window(spec.match, workspace)
		if window then
			if window_workspace(window) ~= workspace then
				local selector = window_selector(window)
				if selector then
					hl.dispatch(hl.dsp.window.move({ workspace = workspace, silent = true, window = selector }))
				end
			end
		elseif spec.cmd then
			hl.exec_cmd(spec.cmd, { workspace = workspace .. " silent" })
		end
		hl.dispatch(hl.dsp.workspace.toggle_special(spec.name))
	end
end

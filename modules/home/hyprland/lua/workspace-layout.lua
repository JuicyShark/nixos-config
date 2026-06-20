-- ============================================================
-- WORKSPACE / LAYOUT HELPERS
-- ============================================================
return function(ctx)
	local hl = ctx.hl
	local cfg = ctx.cfg

	local function dispatch_action(action)
		if type(action) == "function" then
			action()
		elseif action then
			hl.dispatch(action)
		end
	end

	local function current_workspace()
		if hl.get_active_special_workspace then
			local special = hl.get_active_special_workspace()
			if special then
				return special
			end
		end
		if hl.get_active_workspace then
			return hl.get_active_workspace()
		end
		return nil
	end

	local function current_layout()
		local workspace = current_workspace()
		return workspace and workspace.tiled_layout or nil
	end

	local function is_layout(layout, expected)
		return layout == expected or (expected == "scrolling" and layout == "scroller")
	end

	local function set_workspace_layout(workspace_name, layout)
		if not workspace_name or not layout then
			return
		end
		hl.workspace_rule({ workspace = workspace_name, layout = layout })
	end

	ctx.layout = {
		currentWorkspace = current_workspace,
		current = current_layout,
		is = function(expected)
			return is_layout(current_layout(), expected)
		end,
		setWorkspaceLayout = set_workspace_layout,
	}

	ctx.layout.cycleWorkspaceLayout = function()
		local workspace = current_workspace()
		if not workspace then
			return
		end

		local layouts = { "scrolling", "hy3", "master", "monocle" }
		local next_layout = layouts[1] or "master"
		for i = 1, #layouts do
			if layouts[i] == workspace.tiled_layout then
				next_layout = layouts[(i % #layouts) + 1]
				break
			end
		end

		set_workspace_layout(workspace.name, next_layout)
	end
	ctx.layout.bind = function(bind_table)
		return function()
			local layout = current_layout()
			local action = bind_table[layout]
			if not action and layout == "scroller" then
				action = bind_table.scrolling
			end
			if not action then
				action = bind_table.default
			end
			dispatch_action(action)
		end
	end
	ctx.layout.specific = function(layout, action)
		return function()
			if is_layout(current_layout(), layout) then
				dispatch_action(action)
			end
		end
	end

	ctx.layout.hy3 = {
		dispatch = function(dispatcher, args)
			args = args or ""
			return hl.dsp.exec_cmd(cfg.hyprctl .. " dispatch hy3:" .. dispatcher .. " " .. args)
		end,
		moveFocus = function(direction, opts)
			opts = opts or {}
			return hl.plugin.hy3.move_focus(direction, { visible = opts.visible == true })
		end,
		moveWindow = function(direction, opts)
			opts = opts or {}
			return hl.plugin.hy3.move_window(direction, { once = opts.once == true, visible = opts.visible == true })
		end,
		makeGroup = function(group)
			return hl.plugin.hy3.make_group(group)
		end,
		changeGroup = function(group)
			return hl.plugin.hy3.change_group(group)
		end,
		makeTabGroup = function()
			return ctx.layout.hy3.dispatch("makegroup", "tab toggle")
		end,
		focusTab = function(direction)
			return ctx.layout.hy3.dispatch("focustab", direction)
		end,
		focusTabIndex = function(index)
			return ctx.layout.hy3.dispatch("focustab", "index " .. tostring(index))
		end,
		lockTab = function()
			return ctx.layout.hy3.dispatch("locktab")
		end,
	}
end

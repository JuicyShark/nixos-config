-- ============================================================
-- WORKSPACE / LAYOUT HELPERS
-- ============================================================
return function(ctx)
	local hl = ctx.hl

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

	local function set_workspace_layout(workspace_name, layout)
		if not workspace_name or not layout then
			return
		end
		hl.workspace_rule({ workspace = workspace_name, layout = layout })
	end

	ctx.currentWorkspace = current_workspace
	ctx.setWorkspaceLayout = set_workspace_layout
	ctx.cycleWorkspaceLayout = function()
		local workspace = current_workspace()
		if not workspace then
			return
		end

		local layouts = { "scrolling", "dwindle", "master", "monocle" }
		local next_layout = layouts[1] or "master"
		for i = 1, #layouts do
			if layouts[i] == workspace.tiled_layout then
				next_layout = layouts[(i % #layouts) + 1]
				break
			end
		end

		set_workspace_layout(workspace.name, next_layout)
	end
	ctx.layoutBind = function(bind_table)
		return function()
			local workspace = current_workspace()
			if not workspace then
				return
			end

			local layout = workspace.tiled_layout
			local action = bind_table[layout]
			if not action and layout == "scroller" then
				action = bind_table.scrolling
			end
			dispatch_action(action)
		end
	end
	ctx.layoutSpecificBind = function(layout, action)
		return function()
			local workspace = current_workspace()
			if not workspace then
				return
			end

			local active_layout = workspace.tiled_layout
			if active_layout == layout or (layout == "scrolling" and active_layout == "scroller") then
				dispatch_action(action)
			end
		end
	end
end

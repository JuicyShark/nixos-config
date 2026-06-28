-- ============================================================
-- EXTERNAL MONITOR WORKSPACES
-- ============================================================
return function(ctx)
	local hl = ctx.hl
	local desktop = ctx.desktop
	local monitorWorkspace = desktop.monitorWorkspace or {}

	if not monitorWorkspace.enable then
		return
	end

	local targetMonitor = monitorWorkspace.target
	local primaryMonitor = desktop.primary.selector
	local workspaces = monitorWorkspace.workspaces or {}
	local lastMonitor = nil

	local function set_owner(monitor)
		monitor = monitor or primaryMonitor
		if monitor == lastMonitor then
			return
		end
		lastMonitor = monitor

		for _, workspace in ipairs(workspaces) do
			hl.workspace_rule({ workspace = workspace, monitor = monitor, persistent = true })
			hl.dispatch(hl.dsp.workspace.move({ workspace = workspace, monitor = monitor }))
		end
	end

	ctx.monitorWorkspace = {
		primary = primaryMonitor,
		target = targetMonitor,
		workspaces = workspaces,
		setOwner = set_owner,
	}

	hl.on("hyprland.start", function()
		set_owner(primaryMonitor)
	end)
end

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

	local function target_connected()
		for _, monitor in ipairs(hl.get_monitors()) do
			if monitor.name == targetMonitor then
				return true
			end
		end
		return false
	end

	local function reconcile()
		local monitor = primaryMonitor
		if target_connected() then
			monitor = targetMonitor
		end

		if monitor == lastMonitor then
			return
		end
		lastMonitor = monitor

		for _, workspace in ipairs(workspaces) do
			hl.workspace_rule({ workspace = workspace, monitor = monitor, persistent = true })
			hl.dispatch(hl.dsp.workspace.move({ workspace = workspace, monitor = monitor }))
		end
	end

	hl.on("hyprland.start", reconcile)
	hl.on("monitor.added", reconcile)
	hl.on("monitor.removed", reconcile)
end

return function(ctx, opts)
	local hl = ctx.hl
	local desktop = (opts or {}).desktop or {}
	local monitorWorkspace = desktop.monitorWorkspace or {}

	if not monitorWorkspace.enable then
		return
	end

	local primary = desktop.primary.selector
	local workspaces = monitorWorkspace.workspaces or {}

	local function assign(workspace, monitor)
		hl.workspace_rule({
			workspace = workspace,
			monitor = monitor,
			persistent = true,
		})
	end

	local function apply(assignments)
		local assigned = {}

		for _, assignment in ipairs(assignments or {}) do
			for _, workspace in ipairs(assignment.workspaces or {}) do
				assign(workspace, assignment.monitor)
				assigned[workspace] = true
			end
		end

		for _, workspace in ipairs(workspaces) do
			if not assigned[workspace] then
				assign(workspace, primary)
			end
		end

		-- Workspace-rule refresh moves persistent workspaces to their declared
		-- monitors. Force it now so monitor teardown cannot race placement.
		hl.exec_scheduled_prop_refresh_immediately()
	end

	ctx.monitorWorkspace = {
		apply = apply,
	}
end

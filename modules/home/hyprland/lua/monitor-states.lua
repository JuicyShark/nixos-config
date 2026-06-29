-- ============================================================
-- MONITOR STATES
-- ============================================================
return function(ctx)
	local hl = ctx.hl
	local stream = ctx.cfg.sunshine and ctx.cfg.sunshine.stream or {}
	local primary = ctx.desktop.primary.output
	local primarySelector = ctx.desktop.primary.selector
	local doubleMonitor = ctx.desktop.double and ctx.desktop.double.output or "HDMI-A-1"
	local doublePosition = ctx.desktop.double and ctx.desktop.double.position or "auto-center-right"
	local streamMonitor = stream.monitor or (ctx.desktop.monitorWorkspace and ctx.desktop.monitorWorkspace.target) or "virtual-screen"
	local streamPosition = stream.position or "0x1440"
	local streamCreated = false
	local lastKey = nil
	local applying = false

	local function create_stream_output()
		if streamCreated then
			return
		end
		hl.exec_cmd(ctx.cfg.hyprctl .. " output create headless " .. streamMonitor)
		streamCreated = true
	end

	local function remove_stream_output()
		if not streamCreated then
			return
		end
		hl.exec_cmd(ctx.cfg.hyprctl .. " output remove " .. streamMonitor)
		streamCreated = false
	end

	local function set_monitor(output, enabled, opts)
		opts = opts or {}
		local spec = {
			output = output,
			disabled = not enabled,
		}
		if enabled then
			spec.mode = opts.mode or "preferred"
			spec.position = opts.position
			spec.scale = opts.scale
		end
		hl.monitor(spec)
	end

	local function move_workspaces(workspaces, monitor)
		for _, workspace in ipairs(workspaces) do
			hl.workspace_rule({ workspace = workspace, monitor = monitor, persistent = true })
			hl.dispatch(hl.dsp.workspace.move({ workspace = workspace, monitor = monitor }))
		end
	end

	local function set_solo()
		move_workspaces({ "6", "7", "8", "9", "10" }, primarySelector)
		set_monitor(primary, true, { position = "0x0", scale = 1 })
		set_monitor(doubleMonitor, false)
		remove_stream_output()
	end

	local function set_stream(meta)
		meta = meta or {}
		local width = tonumber(meta.width) or stream.width or 2560
		local height = tonumber(meta.height) or stream.height or 1440
		local refresh = tonumber(meta.refresh) or stream.refresh or 120
		local scale = tonumber(meta.scale) or stream.scale or 1.67

		create_stream_output()
		set_monitor(streamMonitor, true, {
			mode = string.format("%dx%d@%d", width, height, refresh),
			position = streamPosition,
			scale = scale,
		})
	end

	local function apply(meta)
		local remote = ctx.state.active("remote-streaming")
		local streaming = ctx.state.active("streaming")
		local double = ctx.state.active("double")

		if remote then
			set_stream(meta)
			move_workspaces({ "6", "7", "8", "9", "10" }, streamMonitor)
			set_monitor(doubleMonitor, false)
			set_monitor(primary, false)
			return
		end

		set_monitor(primary, true, { position = "0x0", scale = 1 })

		if double then
			set_monitor(doubleMonitor, true, { position = doublePosition, scale = 1 })
			if streaming then
				set_stream(meta)
				move_workspaces({ "6", "7", "8" }, doubleMonitor)
				move_workspaces({ "9", "10" }, streamMonitor)
			else
				move_workspaces({ "6", "7", "8", "9", "10" }, doubleMonitor)
				remove_stream_output()
			end
			return
		end

		set_monitor(doubleMonitor, false)
		if streaming then
			set_stream(meta)
			move_workspaces({ "6", "7", "8", "9", "10" }, streamMonitor)
		else
			move_workspaces({ "6", "7", "8", "9", "10" }, primarySelector)
			remove_stream_output()
		end
	end

	local function reconcile(meta, opts)
		meta = meta or {}
		opts = opts or {}
		local remote = ctx.state.active("remote-streaming")
		local streaming = ctx.state.active("streaming")
		local double = ctx.state.active("double")
		local key = tostring(remote)
			.. ":"
			.. tostring(streaming)
			.. ":"
			.. tostring(double)
			.. ":"
			.. tostring(meta.width)
			.. ":"
			.. tostring(meta.height)
			.. ":"
			.. tostring(meta.refresh)
			.. ":"
			.. tostring(meta.scale)

		if applying then
			return
		end

		if key == lastKey and not opts.force then
			return
		end
		lastKey = key

		applying = true
		local ok, err = pcall(apply, meta)
		applying = false
		if not ok then
			error(err)
		end
	end

	local function solo()
		ctx.state.set("remote-streaming", false)
		ctx.state.set("streaming", false)
		ctx.state.set("double", false)
		set_solo()
		lastKey = "false:false:false:nil:nil:nil:nil"
	end

	ctx.state.onChange(function(name, _, _, meta)
		if name == "streaming" or name == "remote-streaming" or name == "double" then
			reconcile(meta)
		end
	end)

	ctx.monitorStates = {
		reconcile = reconcile,
		solo = solo,
	}

	local function reconcile_topology()
		reconcile(nil, { force = true })
	end

	hl.on("hyprland.start", reconcile_topology)
	hl.on("monitor.added", reconcile_topology)
	hl.on("monitor.removed", reconcile_topology)
	hl.on("monitor.layout_changed", reconcile_topology)
end

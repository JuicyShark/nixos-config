-- ============================================================
-- SUNSHINE STREAM MONITOR
-- ============================================================
return function(ctx)
	local hl = ctx.hl

	if not (ctx.cfg.sunshine and ctx.cfg.sunshine.enable) then
		return
	end

	local stream = ctx.cfg.sunshine.stream or {}
	local streamMonitor = stream.monitor or "virtual-screen"
	local streamPosition = stream.position or "5120x0"
	local lastEnabled = false
	local streamCreated = false

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

	local function set_workspace_owner(monitor)
		if ctx.monitorWorkspace and ctx.monitorWorkspace.setOwner then
			ctx.monitorWorkspace.setOwner(monitor)
			return
		end

		for _, workspace in ipairs({ "6", "7", "8", "9", "10" }) do
			hl.workspace_rule({ workspace = workspace, monitor = monitor, persistent = true })
			hl.dispatch(hl.dsp.workspace.move({ workspace = workspace, monitor = monitor }))
		end
	end

	local function reset_workspace_owner()
		local primary = ctx.monitorWorkspace and ctx.monitorWorkspace.primary or ctx.desktop.primary.selector
		set_workspace_owner(primary)
	end

	local function set_primary_enabled(enabled)
		local primary = ctx.desktop.primary.output
		if primary then
			hl.monitor({
				output = primary,
				disabled = not enabled,
			})
		end
	end

	local function apply_streaming(enabled, remote, meta)
		meta = meta or {}
		if not enabled then
			reset_workspace_owner()
			set_primary_enabled(true)
			remove_stream_output()
			lastEnabled = false
			return
		end

		local width = tonumber(meta.width) or stream.width or 2560
		local height = tonumber(meta.height) or stream.height or 1440
		local refresh = tonumber(meta.refresh) or stream.refresh or 120
		local scale = tonumber(meta.scale) or stream.scale or 1.67

		create_stream_output()
		hl.monitor({
			output = streamMonitor,
			mode = string.format("%dx%d@%d", width, height, refresh),
			position = streamPosition,
			scale = scale,
		})
		set_workspace_owner(streamMonitor)
		lastEnabled = true

		if remote then
			set_primary_enabled(false)
			return
		end

		set_primary_enabled(true)
	end

	local function reconcile(_, _, _, meta)
		local remote = ctx.state.active("remote-streaming")
		local localStreaming = ctx.state.active("streaming")
		local enabled = remote or localStreaming

		if not enabled and not lastEnabled then
			return
		end

		apply_streaming(enabled, remote, meta)
	end

	local function set_streaming(enabled, remote, width, height, refresh, scale)
		local meta = {
			width = width,
			height = height,
			refresh = refresh,
			scale = scale,
		}

		if enabled == true then
			if remote == true then
				ctx.state.set("remote-streaming", true, meta)
				ctx.state.set("streaming", false, meta)
			else
				ctx.state.set("streaming", true, meta)
				ctx.state.set("remote-streaming", false, meta)
			end
			reconcile("sunshine", true, ctx.state.primary(), meta)
			return
		end

		ctx.state.set("streaming", false)
		ctx.state.set("remote-streaming", false)
	end

	ctx.state.onChange(function(name, enabled, primary, meta)
		if name == "streaming" or name == "remote-streaming" then
			reconcile(name, enabled, primary, meta)
		end
	end)

	ctx.sunshine = ctx.sunshine or {}
	ctx.sunshine.setStreaming = set_streaming
	_G.Juicy = _G.Juicy or {}
	_G.Juicy.sunshine = ctx.sunshine
end

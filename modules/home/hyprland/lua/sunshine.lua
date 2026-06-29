-- ============================================================
-- SUNSHINE STREAM MONITOR
-- ============================================================
return function(ctx)
	local hl = ctx.hl

	if not (ctx.cfg.sunshine and ctx.cfg.sunshine.enable) then
		return
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
			else
				ctx.state.set("streaming", true, meta)
				ctx.state.set("remote-streaming", false, meta)
			end
			if ctx.monitorStates and ctx.monitorStates.reconcile then
				ctx.monitorStates.reconcile(meta)
			end
			return
		end

		ctx.state.set("remote-streaming", false)
		ctx.state.set("streaming", false)
		if ctx.monitorStates and ctx.monitorStates.reconcile then
			ctx.monitorStates.reconcile()
		end
	end

	ctx.sunshine = ctx.sunshine or {}
	ctx.sunshine.setStreaming = set_streaming
	_G.Juicy = _G.Juicy or {}
	_G.Juicy.sunshine = ctx.sunshine
end

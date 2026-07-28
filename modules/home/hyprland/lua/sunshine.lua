-- ============================================================
-- SUNSHINE STREAM MONITOR
-- ============================================================
return function(ctx, opts)
	opts = opts or {}
	if not opts.enable then
		return
	end

	local function set_streaming(enabled, remote, width, height, refresh, scale)
		if enabled == true then
			ctx.monitors.setStream({
				kind = remote == true and "remote" or "local",
				width = width,
				height = height,
				refresh = refresh,
				scale = scale,
			})
			return
		end

		ctx.monitors.setStream("off")
	end

	ctx.sunshine = ctx.sunshine or {}
	ctx.sunshine.setStreaming = set_streaming
	_G.Juicy = _G.Juicy or {}
	_G.Juicy.sunshine = ctx.sunshine
end

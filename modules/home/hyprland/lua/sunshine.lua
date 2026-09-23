-- ============================================================
-- SUNSHINE PRESENCE FACTS (NO DISPLAY MANAGEMENT)
-- ============================================================
return function(ctx, opts)
	opts = opts or {}
	if not opts.enable then
		return
	end

	local function set_streaming(enabled, remote)
		if enabled == true then
			ctx.state.setSource("sunshine-session", "streaming", remote ~= true)
			ctx.state.setSource("sunshine-session", "remote-streaming", remote == true)
			return
		end

		ctx.state.setSource("sunshine-session", "streaming", false)
		ctx.state.setSource("sunshine-session", "remote-streaming", false)
	end

	ctx.sunshine = ctx.sunshine or {}
	ctx.sunshine.setStreaming = set_streaming
	_G.Juicy = _G.Juicy or {}
	_G.Juicy.sunshine = ctx.sunshine
end

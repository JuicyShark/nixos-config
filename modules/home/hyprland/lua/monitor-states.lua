-- Explicit actions only; static settings own startup and reload defaults.
return function(ctx, opts)
	local hl = ctx.hl
	local main = assert(opts.mainOutput)
	local tv = assert(opts.tvOutput)
	local api = {}

	function api.setProfile(profile)
		assert(profile == "solo" or profile == "extended" or profile == "mirror", "unknown display profile")
		hl.monitor({
			output = main,
			mode = "preferred",
			position = "0x0",
			scale = 1,
			disabled = false,
		})
		hl.monitor({
			output = tv,
			mode = "1920x1080@60",
			position = "auto-center-right",
			scale = 1,
			disabled = profile == "solo",
			mirror = profile == "mirror" and main or "",
		})
	end

	function api.solo()
		api.setProfile("solo")
	end

	ctx.monitors = api
	_G.Juicy = _G.Juicy or {}
	_G.Juicy.monitors = api
end

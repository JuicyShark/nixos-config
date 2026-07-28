return function(ctx, opts)
	local hl = ctx.hl
	opts = opts or {}

	local armed = false
	local timeoutToken = 0
	local timeoutMs = opts.timeoutMs or (5 * 60 * 1000)

	local function disarm()
		armed = false
	end

	local function isOrdinaryTiledWindow(window)
		return window
			and window.mapped
			and not window.floating
			and not window.hidden
			and not window.pinned
			and not window.group
			and (window.fullscreen or 0) == 0
	end

	local function toggleConsume()
		if armed then
			disarm()
			return
		end

		armed = true
		timeoutToken = timeoutToken + 1
		local token = timeoutToken

		hl.timer(function()
			if armed and timeoutToken == token then
				disarm()
			end
		end, {
			timeout = timeoutMs,
			type = "oneshot",
		})
	end

	hl.on("window.open", function(window)
		if not armed then
			return
		end

		disarm()

		local active = hl.get_active_window()
		if
			not isOrdinaryTiledWindow(window)
			or not active
			or active.address ~= window.address
		then
			return
		end

		hl.dispatch(hl.dsp.layout("consume"))
	end)

	local api = {
		toggleConsume = toggleConsume,
	}

	_G.Juicy = _G.Juicy or {}
	_G.Juicy.nextWindow = api
end

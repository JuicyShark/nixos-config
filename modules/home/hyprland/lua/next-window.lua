return function(ctx, opts)
	local hl = ctx.hl
	opts = opts or {}

	local armed = false
	local consumeTarget = nil
	local timeoutToken = 0
	local timeoutMs = opts.timeoutMs or (5 * 60 * 1000)

	local function disarm()
		armed = false
		consumeTarget = nil
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

		consumeTarget = hl.get_active_window()
		if not consumeTarget then
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

		local active = hl.get_active_window()
		if
			not isOrdinaryTiledWindow(window)
			or not active
			or active.address ~= window.address
		then
			return
		end

		local target = consumeTarget
		disarm()
		hl.dispatch(hl.dsp.focus({ window = target }))
		hl.dispatch(hl.dsp.layout("consume"))
		hl.dispatch(hl.dsp.layout("focus u"))
	end)

	local api = {
		toggleConsume = toggleConsume,
	}

	_G.Juicy = _G.Juicy or {}
	_G.Juicy.nextWindow = api
end

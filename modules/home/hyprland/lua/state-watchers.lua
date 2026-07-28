return function(ctx)
	local hl = ctx.hl
	local gameWindows = {}
	local screenshares = 0

	local function has_tag(window, name)
		for _, tag in ipairs((window and window.tags) or {}) do
			if tag == name then
				return true
			end
		end
		return false
	end

	local function publish_gaming()
		ctx.state.setSource("game-windows", "gaming", next(gameWindows) ~= nil)
	end

	local function update_game(window)
		if not (window and window.address) then
			return
		end
		gameWindows[window.address] = has_tag(window, "game") or nil
		publish_gaming()
	end

	local function remove_game(window)
		if window and window.address then
			gameWindows[window.address] = nil
		end
		publish_gaming()
	end

	for _, window in ipairs(hl.get_windows({ tag = "game" }) or {}) do
		gameWindows[window.address] = true
	end
	publish_gaming()

	hl.on("window.open", update_game)
	hl.on("window.update_rules", update_game)
	hl.on("window.close", remove_game)
	hl.on("screenshare.state", function(active)
		screenshares = math.max(0, screenshares + (active and 1 or -1))
		ctx.state.setSource("hyprland-screenshare", "screen-recording", screenshares > 0)
	end)
end

-- ============================================================
-- WINDOW STATE
-- ============================================================
return function(ctx)
	local hl = ctx.hl
	local mark = { addr = nil, selector = nil }

	local function window_selector(window)
		if not window or not window.address then
			return nil
		end
		return "address:" .. tostring(window.address)
	end

	local function find_window(addr)
		if not addr then
			return nil
		end
		for _, w in ipairs(hl.get_windows() or {}) do
			if w.address == addr then
				return w
			end
		end
		return nil
	end

	local function set_marked(window, on)
		hl.dispatch(hl.dsp.window.tag({
			tag = (on and "+marked" or "-marked"),
			window = window,
		}))
	end

	ctx.window = ctx.window or {}
	ctx.window.toggleFakeFullscreen = function(internal, client)
		hl.dispatch(hl.dsp.window.tag({ tag = "fake-fullscreen-borderless" }))
		hl.dispatch(hl.dsp.window.fullscreen_state({ internal = internal, client = client, action = "toggle" }))
	end

	ctx.window.togglePictureInPicture = function()
		hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
		hl.dispatch(hl.dsp.window.pin())
		ctx.window.toggleFakeFullscreen(2, 0)
	end

	ctx.window.markOrSwap = function()
		local active = hl.get_active_window and hl.get_active_window()
		if not active then
			return
		end
		local active_selector = window_selector(active)
		if not active_selector then
			return
		end

		if not mark.addr then
			mark.addr = active.address
			mark.selector = active_selector
			set_marked(active_selector, true)
			return
		end

		if mark.addr == active.address then
			set_marked(active_selector, false)
			mark.addr = nil
			mark.selector = nil
			return
		end

		local marked_win = find_window(mark.addr)
		if not marked_win then
			mark.addr = active.address
			mark.selector = active_selector
			set_marked(active_selector, true)
			return
		end

		hl.dispatch(hl.dsp.window.swap({ window = active_selector, target = mark.selector }))
		set_marked(mark.selector, false)
		mark.addr = nil
		mark.selector = nil
	end
end

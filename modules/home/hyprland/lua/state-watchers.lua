-- ============================================================
-- STATE WATCHERS
-- ============================================================
return function(ctx)
	local hl = ctx.hl
	local windowPolicy = ctx.windowPolicy

	local function reconcile_gaming()
		local active = false
		for _, window in ipairs(hl.get_windows() or {}) do
			if windowPolicy.isGame(window) then
				active = true
				break
			end
		end
		ctx.state.setSource("game-windows", "gaming", active)
	end

	hl.on("hyprland.start", reconcile_gaming)
	hl.on("window.open_early", reconcile_gaming)
	hl.on("window.close", reconcile_gaming)
	hl.on("window.move_to_workspace", reconcile_gaming)
end

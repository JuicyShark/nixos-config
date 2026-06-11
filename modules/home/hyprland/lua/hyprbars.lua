-- ============================================================
-- HYPRBARS
-- ============================================================
return function(ctx)
	local hl = ctx.hl

	-- Hyprbars are opt-in for floating windows, forbidden for pinned windows
	-- and workspace 5, and temporarily allowed on tiled windows via keybind.
	local hideTiledHyprbars = hl.window_rule({
		name = "hyprbars-hide-tiled",
		match = { float = false },
		["hyprbars:no_bar"] = true,
	})
	hl.window_rule({
		name = "hyprbars-hide-pinned",
		match = { pin = true },
		["hyprbars:no_bar"] = true,
	})
	hl.window_rule({
		name = "hyprbars-hide-workspace-5",
		match = { workspace = "5" },
		["hyprbars:no_bar"] = true,
	})

	local hyprbarsTiledEnabled = false
	ctx.window = ctx.window or {}
	ctx.window.toggleHyprbarsTiled = function()
		hyprbarsTiledEnabled = not hyprbarsTiledEnabled
		hideTiledHyprbars:set_enabled(not hyprbarsTiledEnabled)
	end
end

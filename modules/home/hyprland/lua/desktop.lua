-- ============================================================
-- DESKTOP POLICY
-- ============================================================
return function(ctx)
	ctx.desktop = {
		mod = "SUPER",
		primary = {
			output = "DP-2",
			selector = "DP-2",
			wideColor = true,
		},
		monitorWorkspace = {
			enable = true,
			target = "virtual-screen",
			workspaces = { "6", "7", "8", "9", "10" },
		},
	}
end

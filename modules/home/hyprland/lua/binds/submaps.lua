-- ============================================================
-- SUBMAP LOADER
-- ============================================================
return function(ctx)
	require("binds.submaps.core")(ctx)

	for _, module in ipairs(ctx.cfg.submapModules or {}) do
		require(module)(ctx)
	end

	ctx.writeCheatsheet()
end

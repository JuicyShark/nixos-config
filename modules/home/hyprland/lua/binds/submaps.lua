-- ============================================================
-- SUBMAP LOADER
-- ============================================================
return function(ctx)
	require("binds.groups")(ctx)
	require("binds.layouts.master")(ctx)
	require("binds.layouts.hy3")(ctx)
	require("binds.layouts.scrolling")(ctx)
	require("binds.submaps.core")(ctx)

	if ctx.features.emacs then
		require("binds.submaps.emacs")(ctx)
	end

	if ctx.features.tmux then
		require("binds.submaps.tmux")(ctx)
	end

	ctx.bindHelpers.writeCheatsheet()
end

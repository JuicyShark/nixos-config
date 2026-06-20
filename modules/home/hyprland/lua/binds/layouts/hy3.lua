-- ============================================================
-- HY3 LAYOUT BINDS
-- ============================================================
return function(ctx)
	local hy3 = ctx.layout.hy3

	ctx.layout.bindHy3Actions = function(bindLayoutAction)
		bindLayoutAction("T", hy3.changeGroup("toggletab"), "[Hy3] Toggle tabs")
		bindLayoutAction("minus", hy3.changeGroup("h"), "[Hy3] Horizontal split")
		bindLayoutAction("equal", hy3.changeGroup("v"), "[Hy3] Vertical split")
		bindLayoutAction("O", hy3.changeGroup("opposite"), "[Hy3] Toggle split axis")
		bindLayoutAction("A", hy3.makeGroup("opposite"), "[Hy3] New opposite split")
		bindLayoutAction("left", hy3.makeGroup("h"), "[Hy3] Horizontal split")
		bindLayoutAction("right", hy3.makeGroup("h"), "[Hy3] Horizontal split")
		bindLayoutAction("up", hy3.makeGroup("v"), "[Hy3] Vertical split")
		bindLayoutAction("down", hy3.makeGroup("v"), "[Hy3] Vertical split")
	end
end

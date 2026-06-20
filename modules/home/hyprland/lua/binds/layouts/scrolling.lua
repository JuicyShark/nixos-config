-- ============================================================
-- SCROLLING LAYOUT BINDS
-- ============================================================
return function(ctx)
	ctx.layout.bindScrollingActions = function(bindLayoutMessage)
		bindLayoutMessage("period", "move +col", "[Scrolling] Next column")
		bindLayoutMessage("comma", "move -col", "[Scrolling] Previous column")
		bindLayoutMessage("bracketright", "colresize +conf", "[Scrolling] Widen column")
		bindLayoutMessage("bracketleft", "colresize -conf", "[Scrolling] Narrow column")
		bindLayoutMessage("H", "focus l", "[Scrolling] Focus left")
		bindLayoutMessage("L", "focus r", "[Scrolling] Focus right")
		bindLayoutMessage("F", "fit visible", "[Scrolling] Fit visible")
		bindLayoutMessage("A", "fit active", "[Scrolling] Fit active")
		bindLayoutMessage("O", "fit all", "[Scrolling] Fit all")
		bindLayoutMessage("Home", "fit tobeg", "[Scrolling] Fit start")
		bindLayoutMessage("End", "fit toend", "[Scrolling] Fit end")
		bindLayoutMessage("CONTROL + P", "promote", "[Scrolling] Promote to column")
		bindLayoutMessage("SHIFT + P", "promote", "[Scrolling] Promote to column", { cheatsheet = false })
		bindLayoutMessage("E", "expel", "[Scrolling] Expel to column")
		bindLayoutMessage("C", "consume", "[Scrolling] Consume previous column")
		bindLayoutMessage("B", "consume_or_expel prev", "[Scrolling] Consume or expel previous")
		bindLayoutMessage("V", "consume_or_expel next", "[Scrolling] Consume or expel next")
		bindLayoutMessage("I", "inhibit_scroll", "[Scrolling] Toggle scroll lock")
		bindLayoutMessage("Y", "togglefit", "[Scrolling] Toggle fit")
	end
end

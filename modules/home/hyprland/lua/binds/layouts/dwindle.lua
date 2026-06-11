-- ============================================================
-- DWINDLE LAYOUT BINDS
-- ============================================================
return function(ctx)
	local hl = ctx.hl

	ctx.bindDwindleLayoutActions = function(bindLayoutMessage, bindLayoutAction)
		bindLayoutMessage("T", "movetoroot active", "[Dwindle] Move window to root")
		bindLayoutMessage("minus", "splitratio -0.1", "[Dwindle] Shrink split")
		bindLayoutMessage("equal", "splitratio +0.1", "[Dwindle] Grow split")
		bindLayoutMessage("O", "splitratio 1.0 exact", "[Dwindle] Split ratio even")
		bindLayoutMessage("A", "rotatesplit 90", "[Dwindle] Rotate split")
		bindLayoutMessage("left", "preselect l", "[Dwindle] Preselect left")
		bindLayoutMessage("right", "preselect r", "[Dwindle] Preselect right")
		bindLayoutMessage("up", "preselect u", "[Dwindle] Preselect up")
		bindLayoutMessage("down", "preselect d", "[Dwindle] Preselect down")
		bindLayoutAction("SHIFT + P", hl.dsp.window.pseudo(), "[Dwindle] Toggle pseudo")
	end
end

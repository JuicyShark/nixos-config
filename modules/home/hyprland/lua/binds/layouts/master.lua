-- ============================================================
-- MASTER LAYOUT BINDS
-- ============================================================
return function(ctx)
	ctx.bindMasterLayoutActions = function(bindLayoutMessage)
		bindLayoutMessage("O", "mfact exact 0.5", "[Master] Master ratio 50%")
		bindLayoutMessage("U", "mfact exact 0.65", "[Master] Master ratio 65%")
		bindLayoutMessage("left", "orientationleft", "[Master] Orient left")
		bindLayoutMessage("up", "orientationcenter", "[Master] Orient center")
		bindLayoutMessage("down", "orientationcenter", "[Master] Orient center")
		bindLayoutMessage("right", "orientationright", "[Master] Orient right")
	end
end

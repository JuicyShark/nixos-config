-- ============================================================
-- GROUP BINDS
-- ============================================================
return function(ctx)
	local hl = ctx.hl
	local binds = ctx.bindHelpers

	ctx.bindHelpers.groupSubmap = function()
		binds.defineSubmap("group", function()
			binds.bind("left", hl.dsp.group.prev(), "Group previous", { repeating = true })
			binds.bind("right", hl.dsp.group.next(), "Group next", { repeating = true })
			binds.bind("R", hl.dsp.group.prev(), "Group previous", { repeating = true, cheatsheet = false })
			binds.bind("T", hl.dsp.group.next(), "Group next", { repeating = true, cheatsheet = false })
			binds.bind("G", hl.dsp.group.toggle(), "Toggle group")
			binds.bind("L", hl.dsp.group.lock_active({ action = "toggle" }), "Lock group")
			binds.bind("U", hl.dsp.window.move({ out_of_group = true }), "Ungroup active")
			binds.bindSubmap("V", "windowMove", "Move window")
			for tab = 1, 5 do
				binds.bind(tostring(tab), hl.dsp.group.active({ index = tab }), "Focus Group Tab " .. tab)
			end
		end, { persistent = true })
	end
end

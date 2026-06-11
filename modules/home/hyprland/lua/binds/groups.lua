-- ============================================================
-- GROUP BINDS
-- ============================================================
return function(ctx)
	local hl = ctx.hl
	local bind = ctx.bind
	local bindSubmap = ctx.bindSubmap
	local submap = ctx.submap

	ctx.defineGroupSubmap = function()
		submap("group", function()
			bind("left", hl.dsp.group.prev(), "Group previous", { repeating = true })
			bind("right", hl.dsp.group.next(), "Group next", { repeating = true })
			bind("R", hl.dsp.group.prev(), "Group previous", { repeating = true, cheatsheet = false })
			bind("T", hl.dsp.group.next(), "Group next", { repeating = true, cheatsheet = false })
			bind("G", hl.dsp.group.toggle(), "Toggle group")
			bind("L", hl.dsp.group.lock_active({ action = "toggle" }), "Lock group")
			bind("U", hl.dsp.window.move({ out_of_group = true }), "Ungroup active")
			bindSubmap("V", "windowMove", "Move window")
			for tab = 1, 5 do
				bind(tostring(tab), hl.dsp.group.active({ index = tab }), "Focus Group Tab " .. tab)
			end
		end, { persistent = true })
	end
end

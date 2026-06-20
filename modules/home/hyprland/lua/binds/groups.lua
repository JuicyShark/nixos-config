-- ============================================================
-- GROUP BINDS
-- ============================================================
return function(ctx)
	local hl = ctx.hl
	local binds = ctx.bindHelpers
	local layout = ctx.layout
	local hy3 = layout.hy3

	local function group_bind(default, hy3_action)
		return layout.bind({
			hy3 = hy3_action,
			default = default,
		})
	end

	ctx.bindHelpers.groupSubmap = function()
		binds.defineSubmap("group", function()
			binds.bind("left", group_bind(hl.dsp.group.prev(), hy3.focusTab("left")), "Group/tab previous", { repeating = true })
			binds.bind("right", group_bind(hl.dsp.group.next(), hy3.focusTab("right")), "Group/tab next", { repeating = true })
			binds.bind("R", group_bind(hl.dsp.group.prev(), hy3.focusTab("left")), "Group/tab previous", { repeating = true, cheatsheet = false })
			binds.bind("T", group_bind(hl.dsp.group.next(), hy3.focusTab("right")), "Group/tab next", { repeating = true, cheatsheet = false })
			binds.bind("G", group_bind(hl.dsp.group.toggle(), hy3.makeTabGroup()), "Toggle group/tab")
			binds.bind("L", group_bind(hl.dsp.group.lock_active({ action = "toggle" }), hy3.lockTab()), "Lock group/tab")
			binds.bind("U", group_bind(hl.dsp.window.move({ out_of_group = true }), hy3.changeGroup("untab")), "Ungroup active")
			binds.bindSubmap("V", "windowMove", "Move window")
			for tab = 1, 5 do
				binds.bind(tostring(tab), group_bind(hl.dsp.group.active({ index = tab }), hy3.focusTabIndex(tab)), "Focus group/tab " .. tab)
			end
		end, { persistent = true })
	end
end

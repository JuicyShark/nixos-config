-- ============================================================
-- CHEATSHEET EVENT FOLLOWER
-- ============================================================
return function(ctx)
	local hl = ctx.hl
	local cheatsheet = ctx.cheatsheet

	local function active_submap(name)
		name = tostring(name or "")
		if name == "" or name == "default" or name == "reset" then
			return ""
		end
		return name
	end

	local function sync_submap(name)
		local submap = active_submap(name)
		if submap == "" then
			cheatsheet.hide()
		else
			cheatsheet.show(submap)
		end
	end

	hl.on("keybinds.submap", sync_submap)

	if type(hl.get_current_submap) == "function" then
		hl.on("hyprland.start", function()
			sync_submap(hl.get_current_submap())
		end)
		hl.on("config.reloaded", function()
			sync_submap(hl.get_current_submap())
		end)
	end
end

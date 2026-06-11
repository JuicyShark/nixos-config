-- ============================================================
-- SPECIAL WORKSPACE GUARDS
-- ============================================================
return function(ctx)
	local hl = ctx.hl

	local guards = {
		["special:steam"] = {
			fallback = "5",
			allowed = {
				"^steam$",
			},
		},
		["special:discord"] = {
			fallback = "2",
			allowed = {
				"^discord$",
				"^vesktop$",
				"^signal$",
				"^org%.telegram%.desktop$",
			},
		},
	}

	local function class_allowed(class, patterns)
		class = class or ""
		for _, pattern in ipairs(patterns or {}) do
			if class:match(pattern) then
				return true
			end
		end
		return false
	end

	local function regular_last_workspace()
		local prev = hl.get_last_workspace and hl.get_last_workspace()
		local name = prev and prev.name
		if name and not name:match("^special:") then
			return name
		end
		return nil
	end

	local function guard_special_workspace(window)
		if not window then
			return
		end

		local workspace = window.workspace and window.workspace.name
		local guard = guards[workspace]
		if not guard or class_allowed(window.class, guard.allowed) then
			return
		end

		hl.dispatch(hl.dsp.window.move({
			workspace = regular_last_workspace() or guard.fallback,
			window = window,
		}))
	end

	hl.on("window.open_early", guard_special_workspace)
	hl.on("window.move_to_workspace", guard_special_workspace)
end

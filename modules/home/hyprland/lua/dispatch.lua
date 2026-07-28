return function(ctx, opts)
	local hl = ctx.hl
	opts = opts or {}
	local presets = opts.presets or {}

	local function dispatch_action(action)
		if type(action) == "function" then
			action()
		elseif action then
			hl.dispatch(action)
		end
	end

	local api = {}

	local function apply_config(spec)
		for section, values in pairs(spec or {}) do
			hl.config({ [section] = values })
		end
	end

	function api.bind(action, opts)
		opts = opts or {}
		return function()
			dispatch_action(action)
			if opts.reset then
				hl.dispatch(hl.dsp.submap(opts.reset))
			end
		end
	end

	function api.layout(actions, opts)
		opts = opts or {}
		return api.bind(function()
			local layout = api.currentLayout()
			dispatch_action(actions[layout])
		end, opts)
	end

	function api.currentWorkspace()
		local special = hl.get_active_special_workspace()
		if special then
			return special
		end
		return hl.get_active_workspace()
	end

	function api.currentLayout()
		local workspace = api.currentWorkspace()
		return workspace and workspace.tiled_layout or nil
	end

	function api.setCurrentLayout(layout)
		local workspace = api.currentWorkspace()
		if workspace and layout then
			hl.workspace_rule({ workspace = workspace.name, layout = layout })
		end
	end

	function api.toggleCenteredFocus()
		local centered = hl.get_config("scrolling.focus_fit_method")
		if centered == 1 then
			hl.config({ scrolling = { focus_fit_method = 0 } })
		else
			hl.config({ scrolling = { focus_fit_method = 1 } })
		end
	end

	function api.gaplessPreset()
		apply_config(presets.gapless)
	end

	function api.defaultPreset()
		apply_config(presets.default)
	end

	_G.Juicy = _G.Juicy or {}
	_G.Juicy.dispatch = api
	_G.Juicy.layout = api
end

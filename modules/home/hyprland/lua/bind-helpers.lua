-- ============================================================
-- BIND HELPERS
-- ============================================================
return function(ctx)
	local hl = ctx.hl
	local cheatsheet = ctx.cheatsheet
	local mod = ctx.desktop.mod

	local function dispatch_action(action)
		if type(action) == "function" then
			action()
		elseif action then
			hl.dispatch(action)
		end
	end

	local function bind_opts(desc, opts)
		opts = opts or {}
		local out = {}
		for key, value in pairs(opts) do
			if key ~= "cheatsheet" and key ~= "closeCheatsheet" and key ~= "when" then
				out[key] = value
			end
		end
		out.description = desc
		return out
	end

	local function submap_action(action, opts)
		opts = opts or {}
		local reset = cheatsheet.reset()
		if not reset then
			return action
		end
		return function()
			dispatch_action(action)
			hl.dispatch(hl.dsp.submap(reset))
		end
	end

	local function bind(keys, action, desc, opts)
		cheatsheet.recordBind(keys, desc, opts)
		hl.bind(keys, submap_action(action, opts), bind_opts(desc, opts))
	end

	local function bind_submap(keys, target, desc, opts)
		opts = opts or {}
		cheatsheet.recordSubmap(keys, target, desc, opts)
		hl.bind(keys, function()
			if opts.when and not opts.when() then
				return
			end
			hl.dispatch(hl.dsp.submap(target))
		end, bind_opts(desc, opts))
	end

	local function bind_back(target, desc)
		desc = desc or "Back"
		cheatsheet.recordSubmap("BackSpace", target, desc)
		hl.bind("BackSpace", function()
			hl.dispatch(hl.dsp.submap(target))
		end, { description = desc })
	end

	local function define_submap(name, body, opts)
		opts = opts or {}
		local reset = opts.reset
		if reset == nil and opts.persistent ~= true then
			reset = "reset"
		end

		local function define_body()
			cheatsheet.withSubmap(name, reset, function()
				body()
				cheatsheet.recordExit()
				hl.bind("escape", function()
					hl.dispatch(hl.dsp.submap("reset"))
				end)
			end)
		end

		hl.define_submap(name, define_body)
	end

	ctx.bindHelpers = {
		mod = mod,
		bind = bind,
		mbind = function(key, action, desc, opts)
			bind(mod .. " + " .. key, action, desc, opts)
		end,
		bindSubmap = bind_submap,
		mbindSubmap = function(key, target, desc, opts)
			bind_submap(mod .. " + " .. key, target, desc, opts)
		end,
		bindBack = bind_back,
		defineSubmap = define_submap,
		toggleOptions = cheatsheet.toggleOptions,
		writeCheatsheet = cheatsheet.write,
	}
end

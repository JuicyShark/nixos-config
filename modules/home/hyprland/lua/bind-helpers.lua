-- ============================================================
-- BIND HELPERS
-- ============================================================
return function(ctx)
	local hl = ctx.hl
	local cheatsheet = ctx.cheatsheet
	local commands = ctx.commands
	local features = ctx.features
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
			if key ~= "cheatsheet" and key ~= "when" and key ~= "allowPassthrough" then
				out[key] = value
			end
		end
		out.description = desc
		return out
	end

	local function passthrough_allowed(opts)
		return opts and opts.allowPassthrough == true
	end

	local function should_skip(opts)
		return ctx.state and ctx.state.active("passthrough") and not passthrough_allowed(opts)
	end

	local function submap_action(action, opts)
		opts = opts or {}
		local reset = cheatsheet.reset()
		return function()
			if should_skip(opts) then
				return
			end
			dispatch_action(action)
			if reset then
				hl.dispatch(hl.dsp.submap(reset))
			end
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
			if should_skip(opts) then
				return
			end
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
			if should_skip() then
				return
			end
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
				if opts.escape ~= false then
					cheatsheet.recordExit()
					hl.bind("escape", function()
						if should_skip(opts) then
							return
						end
						hl.dispatch(hl.dsp.submap("reset"))
					end)
				end
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

	function ctx.bindHelpers.entrySubmaps(bind_fn)
		bind_fn("W", "window", "Windows")
		bind_fn("A", "apps", "Apps")
		bind_fn("L", "layout", "Layout")
		bind_fn("G", "group", "Groups")
		bind_fn("SHIFT + O", "walker", "Walker")
		bind_fn("bracketleft", "system", "System")
		bind_fn("V", "media", "Media")
		bind_fn("S", "state", "State")
		if features.emacs then
			bind_fn("E", "emacs", "Emacs")
		end
		if features.tmux then
			bind_fn("T", "tmux", "Tmux")
		end
	end

	function ctx.bindHelpers.walkerSubmap()
		bind("Space", hl.dsp.exec_cmd(commands.noctaliaLauncher), "Launcher")
		bind("O", hl.dsp.exec_cmd(commands.noctaliaLauncher), "Launcher")
		bind("F", hl.dsp.exec_cmd(commands.files.emacs), "Files (Emacs)")
		bind("SHIFT + F", hl.dsp.exec_cmd(commands.files.thunar), "Files (Thunar)")
		bind("Y", hl.dsp.exec_cmd(commands.files.yazi), "Files (Yazi)")
		bind("D", hl.dsp.exec_cmd(commands.walker.commands), "Commands")
		bind("C", hl.dsp.exec_cmd(commands.walker.clipboard), "Clipboard")
		bind("B", hl.dsp.exec_cmd(commands.walker.bitwarden), "Bitwarden")
		bind("W", hl.dsp.exec_cmd(commands.walker.windows), "Windows")
		if features.gaming then
			bind("G", hl.dsp.exec_cmd(commands.app("steam-games")), "Steam games")
		end
	end
end

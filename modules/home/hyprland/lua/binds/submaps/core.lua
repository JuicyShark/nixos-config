-- ============================================================
-- SUBMAPS
-- ============================================================
return function(ctx)
	local hl = ctx.hl
	local commands = ctx.commands
	local features = ctx.features
	local binds = ctx.bindHelpers
	local layout = ctx.layout
	local bind = binds.bind
	local bindSubmap = binds.bindSubmap
	local bindBack = binds.bindBack
	local defineSubmap = binds.defineSubmap
	local specialApps = {
		discord = {
			name = "discord",
			cmd = commands.app("discord"),
			match = { class = "^(discord|vesktop)$" },
		},
		steam = {
			name = "steam",
			cmd = commands.app("steam"),
			match = { class = "^steam$" },
		},
	}

	local function set_layout(layout)
		local workspace = ctx.layout.currentWorkspace()
		if workspace then
			ctx.layout.setWorkspaceLayout(workspace.name, layout)
		end
	end

	local function layout_message(layout, key, msg, desc, opts)
		bind(key, ctx.layout.specific(layout, hl.dsp.layout(msg)), desc, opts)
	end

	local function layout_action(layout, key, action, desc, opts)
		bind(key, ctx.layout.specific(layout, action), desc, opts)
	end

	local function toggle_state(name)
		return function()
			ctx.state.toggle(name)
		end
	end

	local function clear_state()
		ctx.state.clearUser()
	end

	local function solo_monitor()
		if ctx.monitorStates and ctx.monitorStates.solo then
			ctx.monitorStates.solo()
			return
		end

		ctx.state.set("remote-streaming", false)
		ctx.state.set("streaming", false)
		ctx.state.set("double", false)
	end

	defineSubmap("passthrough", function()
		bind(ctx.desktop.mod .. " + ALT + BackSpace", function()
			ctx.state.set("passthrough", false)
			hl.dispatch(hl.dsp.submap("reset"))
		end, "Exit passthrough", { allowPassthrough = true })
	end, { persistent = true, escape = false })

	defineSubmap("state", function()
		bind("S", solo_monitor, "Solo monitor")
		bind("T", toggle_state("streaming"), "Toggle streaming")
		bind("R", toggle_state("remote-streaming"), "Toggle remote streaming")
		bind("M", toggle_state("double"), "Toggle double monitor")
		bind("C", toggle_state("screen-recording"), "Toggle screen recording")
		bind("D", toggle_state("do-not-disturb"), "Toggle do not disturb")
		bind("P", function()
			ctx.state.set("passthrough", true)
			hl.dispatch(hl.dsp.submap("passthrough"))
		end, "Enable passthrough")
		bind("N", clear_state, "Clear state")
	end)

	ctx.state.onChange(function(name, enabled)
		if name ~= "passthrough" then
			return
		end
		if enabled then
			hl.dispatch(hl.dsp.submap("passthrough"))
		elseif type(hl.get_current_submap) ~= "function" or hl.get_current_submap() == "passthrough" then
			hl.dispatch(hl.dsp.submap("reset"))
		end
	end)

	defineSubmap("walker", function()
		binds.walkerSubmap()
	end)

	defineSubmap("apps", function()
		bind("Return", hl.dsp.exec_cmd(commands.terminal.main), "Open terminal")
		bind("W", hl.dsp.exec_cmd(commands.browser), "Open browser")
		bind("CONTROL + W", hl.dsp.exec_cmd(commands.privateBrowser), "Open private browser")
		bind("SHIFT + W", hl.dsp.exec_cmd(commands.privateBrowser), "Open private browser", { cheatsheet = false })
		bind("F", hl.dsp.exec_cmd(commands.files.emacs), "Files (Emacs)")
		bind("CONTROL + F", hl.dsp.exec_cmd(commands.files.thunar), "Files (Thunar)")
		bind("SHIFT + F", hl.dsp.exec_cmd(commands.files.thunar), "Files (Thunar)", { cheatsheet = false })
		bind("Y", hl.dsp.exec_cmd(commands.files.yazi), "Files (Yazi)")
		bind("R", hl.dsp.exec_cmd(commands.walker.commands), "Run command")
		bind("S", hl.dsp.exec_cmd(commands.screenshot.region), "Take screenshot")
		if features.bloat then
			bind("D", function()
				ctx.apps.openSpecial(specialApps.discord)
			end, "Discord")
		end
		if features.gaming then
			bind("CONTROL + G", function()
				ctx.apps.openSpecial(specialApps.steam)
			end, "Steam")
			bind("SHIFT + G", function()
				ctx.apps.openSpecial(specialApps.steam)
			end, "Steam", { cheatsheet = false })
			bind("G", hl.dsp.exec_cmd(commands.app("steam-games")), "Steam Games Search")
		end
		if features.bloat then
			bind("M", hl.dsp.exec_cmd(commands.app("tidal-hifi")), "Open Music")
		end
		bind("C", hl.dsp.exec_cmd(commands.walker.clipboard), "Open clipboard")
		bind("Space", hl.dsp.exec_cmd(commands.noctaliaLauncher), "Open launcher")
		bind("V", hl.dsp.exec_cmd(commands.volumeMixer), "Open volume mixer")

		bindSubmap("O", "walker", "Walker")
		if features.emacs then
			bindSubmap("E", "emacs", "Emacs")
		end
		if features.tmux then
			bindSubmap("T", "tmux", "Tmux")
		end
	end)

	defineSubmap("window", function()
		bind("M", function()
			ctx.window.toggleFakeFullscreen(2, 0)
		end, "Maximize")
		bindSubmap("R", "windowResize", "Resize window")
		bind("CONTROL + M", hl.dsp.window.fullscreen({ mode = "fullscreen" }), "Toggle fullscreen")
		bind("F", hl.dsp.window.float({ action = "toggle" }), "Toggle floating")
		bind("P", function()
			ctx.window.togglePictureInPicture()
		end, "Picture in picture")
		bind("SHIFT + Q", hl.dsp.window.close(), "Close window")
		bind(
			"S",
			layout.bind({
				hy3 = layout.hy3.changeGroup("opposite"),
				default = hl.dsp.layout("swapsplit"),
			}),
			"Swap split"
		)
		bind("X", function()
			ctx.window.markOrSwap()
		end, "Mark / swap")
		bindSubmap("G", "group", "Groups")
	end)

	defineSubmap("windowResize", function()
		bindBack("window", "Back to windows")
		for _, d in ipairs({
			{ key = "left", x = 75, y = 0, bigX = 160, bigY = 0 },
			{ key = "right", x = -75, y = 0, bigX = -160, bigY = 0 },
			{ key = "up", x = 0, y = -75, bigX = 0, bigY = -160 },
			{ key = "down", x = 0, y = 75, bigX = 0, bigY = 160 },
		}) do
			bind(d.key, function()
				ctx.smartFocus(d.key)
			end, "Focus " .. d.key, { repeating = true })
			bind(
				"SHIFT + " .. d.key,
				hl.dsp.window.resize({ x = d.x, y = d.y, relative = true }),
				"Resize " .. d.key,
				{ repeating = true, cheatsheet = false }
			)
			bind(
				"CONTROL + " .. d.key,
				hl.dsp.window.resize({ x = d.bigX, y = d.bigY, relative = true }),
				"Resize " .. d.key .. " big",
				{ repeating = true }
			)
		end
	end, { persistent = true })

	defineSubmap("layout", function()
		bind("M", function()
			set_layout("master")
		end, "Master Layout")
		bind("D", function()
			set_layout("hy3")
		end, "Hy3 Layout")
		bind("C", function()
			set_layout("scrolling")
		end, "Scrolling Layout")

		bindSubmap("W", "window", "Window Actions")
		bindSubmap("G", "group", "Group Actions")
		bindSubmap("R", "windowResize", "Resize Window")

		layout.bindMasterActions(function(key, msg, desc)
			layout_message("master", key, msg, desc)
		end)
		layout.bindHy3Actions(function(key, action, desc)
			layout_action("hy3", key, action, desc)
		end)

		bind(
			"Left",
			layout.bind({
				hy3 = layout.hy3.changeGroup("h"),
				master = hl.dsp.layout("cycleprev"),
			}),
			"Layout previous / swap left"
		)
		bind(
			"Right",
			layout.bind({
				hy3 = layout.hy3.changeGroup("v"),
				master = hl.dsp.layout("cyclenext"),
			}),
			"Layout next / swap right"
		)
		bind("N", function()
			hl.config({ general = { gaps_out = 0 } })
			hl.config({ general = { gaps_in = 0 } })
			hl.config({ decoration = { rounding = 0 } })
		end, "Gapless preset")
		bind("P", function()
			hl.config({ general = { gaps_out = 24 } })
			hl.config({ general = { gaps_in = 12 } })
			hl.config({ decoration = { rounding = 25 } })
		end, "Default preset")
	end)

	binds.groupSubmap()

	defineSubmap("system", function()
		bind("N", hl.dsp.exec_cmd(commands.notifications.clearActive), "Clear notifs")
		bind("S", hl.dsp.exec_cmd(commands.screenshot.region), "Screenshot (region)")
		bind("CONTROL + S", hl.dsp.exec_cmd(commands.screenshot.fullscreen), "Screenshot (full)")
		bind("SHIFT + S", hl.dsp.exec_cmd(commands.screenshot.fullscreen), "Screenshot (full)", { cheatsheet = false })
		if features.annotation then
			bind("A", hl.dsp.exec_cmd(commands.annotation.toggle), "Annotate")
		end
		bind("C", hl.dsp.exec_cmd(commands.hyprpicker .. " -a"), "Color picker")
		bind("L", hl.dsp.exec_cmd(commands.session.lock), "Lock")
		bind("CONTROL + O", hl.dsp.exec_cmd(commands.session.logout), "Logout")
		bind("SHIFT + O", hl.dsp.exec_cmd(commands.session.logout), "Logout", { cheatsheet = false })
		bindSubmap("R", "confirmSystem", "Reboot")
		bindSubmap("X", "confirmSystem", "Shutdown")
	end)

	defineSubmap("confirmSystem", function()
		bindBack("system", "Back to system")
		bind("R", hl.dsp.exec_cmd(commands.session.reboot), "Reboot, NOW!!")
		bind("X", hl.dsp.exec_cmd(commands.session.shutdown), "Shutdown, NOW!!")
	end)

	defineSubmap("media", function()
		bind("Space", hl.dsp.exec_cmd(commands.media.toggle), "Play pause")
		bind("P", hl.dsp.exec_cmd(commands.media.previous), "Previous track")
		bind("N", hl.dsp.exec_cmd(commands.media.next), "Next track")
		bind("left", hl.dsp.exec_cmd(commands.media.seekBackward), "Seek -10s")
		bind("right", hl.dsp.exec_cmd(commands.media.seekForward), "Seek +10s")
		bind("minus", hl.dsp.exec_cmd(commands.volume.down), "Volume down")
		bind("plus", hl.dsp.exec_cmd(commands.volume.up), "Volume up")
		bind("M", hl.dsp.exec_cmd(commands.volume.mute), "Toggle mute")
		bind("V", hl.dsp.exec_cmd(commands.volumeMixer), "Volume Mixer")
	end)
end

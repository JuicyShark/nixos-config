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

	local function layout_message(layout, key, msg, desc)
		bind(key, ctx.layout.specific(layout, hl.dsp.layout(msg)), desc)
	end

	local function layout_action(layout, key, action, desc)
		bind(key, ctx.layout.specific(layout, action), desc)
	end

	defineSubmap("passthrough", function() end)

	defineSubmap("walker", function()
		binds.walkerSubmap()
	end)

	defineSubmap("apps", function()
		bind("Return", hl.dsp.exec_cmd(commands.terminal.main), "Open terminal")
		bind("W", hl.dsp.exec_cmd(commands.browser), "Open browser")
		bind("SHIFT + W", hl.dsp.exec_cmd(commands.privateBrowser), "[hidden] Open private browser")
		bind("R", hl.dsp.exec_cmd(commands.walker.commands), "Run command")
		bind("S", hl.dsp.exec_cmd(commands.screenshot.region), "Take screenshot")
		if features.bloat then
			bind("D", function()
				ctx.apps.openSpecial(specialApps.discord)
			end, "Discord")
		end
		if features.gaming then
			bind("SHIFT + G", function()
				ctx.apps.openSpecial(specialApps.steam)
			end, "Steam")
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
		bind("CONTROL + F", function()
			ctx.window.togglePictureInPicture()
		end, "Picture in picture")
		bind("SHIFT + Q", hl.dsp.window.close(), "Close window")
		bind("S", hl.dsp.layout("swapsplit"), "Swap split")
		bind("X", function()
			ctx.window.markOrSwap()
		end, "Mark / swap")
		bindSubmap("G", "group", "Groups")
	end)

	defineSubmap("windowMove", function()
		bindBack("window", "Back to windows")
		bind("left", hl.dsp.window.move({ direction = "l" }), "Move left", { repeating = true })
		bind("right", hl.dsp.window.move({ direction = "r" }), "Move right", { repeating = true })
		bind("up", hl.dsp.window.move({ direction = "u" }), "Move up", { repeating = true })
		bind("down", hl.dsp.window.move({ direction = "d" }), "Move down", { repeating = true })
	end, { persistent = true })

	defineSubmap("windowResize", function()
		bindBack("window", "Back to windows")
		bind(
			"SHIFT + left",
			hl.dsp.window.resize({ x = 75, y = 0, relative = true }),
			"Resize left",
			{ repeating = true }
		)
		bind(
			"SHIFT + right",
			hl.dsp.window.resize({ x = -75, y = 0, relative = true }),
			"Resize right",
			{ repeating = true }
		)
		bind("SHIFT + up", hl.dsp.window.resize({ x = 0, y = -75, relative = true }), "Resize up", { repeating = true })
		bind(
			"SHIFT + down",
			hl.dsp.window.resize({ x = 0, y = 75, relative = true }),
			"Resize down",
			{ repeating = true }
		)
		bind(
			"CONTROL + left",
			hl.dsp.window.resize({ x = 160, y = 0, relative = true }),
			"Resize left big",
			{ repeating = true }
		)
		bind(
			"CONTROL + right",
			hl.dsp.window.resize({ x = -160, y = 0, relative = true }),
			"Resize right big",
			{ repeating = true }
		)
		bind(
			"CONTROL + up",
			hl.dsp.window.resize({ x = 0, y = -160, relative = true }),
			"Resize up big",
			{ repeating = true }
		)
		bind(
			"CONTROL + down",
			hl.dsp.window.resize({ x = 0, y = 160, relative = true }),
			"Resize down big",
			{ repeating = true }
		)
	end, { persistent = true })

	defineSubmap("layout", function()
		bind("M", function()
			set_layout("master")
		end, "Master Layout")
		bind("D", function()
			set_layout("dwindle")
		end, "Dwindle Layout")
		bind("C", function()
			set_layout("scrolling")
		end, "Scrolling Layout")

		bindSubmap("W", "window", "Window Actions")
		bindSubmap("G", "group", "Group Actions")
		bindSubmap("V", "windowMove", "Move Window")
		bindSubmap("R", "windowResize", "Resize Window")

		layout.bindMasterActions(function(key, msg, desc)
			layout_message("master", key, msg, desc)
		end)
		layout.bindDwindleActions(function(key, msg, desc)
			layout_message("dwindle", key, msg, desc)
		end, function(key, action, desc)
			layout_action("dwindle", key, action, desc)
		end)
		layout.bindScrollingActions(function(key, msg, desc)
			layout_message("scrolling", key, msg, desc)
		end)

		bind(
			"J",
			layout.bind({
				scrolling = hl.dsp.layout("swapcol l"),
				dwindle = hl.dsp.layout("swapsplit"),
				monocle = hl.dsp.layout("cycleprev"),
				master = hl.dsp.layout("cycleprev"),
			}),
			"Layout previous / swap left"
		)
		bind(
			"K",
			layout.bind({
				scrolling = hl.dsp.layout("swapcol r"),
				dwindle = hl.dsp.layout("togglesplit"),
				monocle = hl.dsp.layout("cyclenext"),
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
		bind("N", hl.dsp.exec_cmd(commands.noctalia .. " ipc call notifications dismissAll"), "Clear notifs")
		bind("S", hl.dsp.exec_cmd(commands.screenshot.region), "Screenshot (region)")
		bind("SHIFT + S", hl.dsp.exec_cmd(commands.screenshot.fullscreen), "Screenshot (full)")
		bind("A", hl.dsp.exec_cmd("pkill -SIGUSR1 wayscriber"), "Annotate")
		bind("C", hl.dsp.exec_cmd(commands.hyprpicker .. " -a"), "Color picker")
		bind("L", hl.dsp.exec_cmd(commands.locker), "Lock")
		bind("SHIFT + O", hl.dsp.exec_cmd('loginctl terminate-user "$(whoami)"'), "Logout")
		bindSubmap("R", "confirmSystem", "Reboot")
		bindSubmap("X", "confirmSystem", "Shutdown")
	end)

	defineSubmap("confirmSystem", function()
		bindBack("system", "Back to system")
		bind("R", hl.dsp.exec_cmd("systemctl reboot"), "Reboot, NOW!!")
		bind("X", hl.dsp.exec_cmd("systemctl poweroff"), "Shutdown, NOW!!")
	end)

	defineSubmap("media", function()
		bind("Space", hl.dsp.exec_cmd("playerctl -p playerctld play-pause"), "Play pause")
		bind("P", hl.dsp.exec_cmd("playerctl -p playerctld previous"), "Previous track")
		bind("N", hl.dsp.exec_cmd("playerctl -p playerctld next"), "Next track")
		bind("left", hl.dsp.exec_cmd("playerctl -p playerctld position 10-"), "Seek -10s")
		bind("right", hl.dsp.exec_cmd("playerctl -p playerctld position 10+"), "Seek +10s")
		bind("minus", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_SINK@ 5%-"), "Volume down")
		bind("plus", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_SINK@ 5%+"), "Volume up")
		bind("M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SINK@ toggle"), "Toggle mute")
		bind("V", hl.dsp.exec_cmd(commands.volumeMixer), "Volume Mixer")
	end)
end

-- ============================================================
-- SUBMAPS
-- ============================================================
return function(ctx)
	local hl = ctx.hl
	local cfg = ctx.cfg
	local theme = ctx.theme
	local bind = ctx.bind
	local bindSubmap = ctx.bindSubmap
	local bindBack = ctx.bindBack
	local submap = ctx.submap
	local appCmd = ctx.appCmd
	local mark_or_swap = ctx.mark_or_swap
	local openSpecialApp = ctx.openSpecialApp
	local current_workspace = ctx.currentWorkspace
	local set_workspace_layout = ctx.setWorkspaceLayout
	local layout_bind = ctx.layoutBind
	local layout_specific_bind = ctx.layoutSpecificBind
	local toggle_submap_options = ctx.toggleSubmapOptions
	local bind_entry_submaps = ctx.bindEntrySubmaps
	local bind_walker_commands = ctx.bindWalkerCommands
	local toggle_fake_fullscreen = ctx.toggleFakeFullscreen
	local toggle_picture_in_picture = ctx.togglePictureInPicture
	local hasGaming = cfg.flags.gaming
	local hasBloat = cfg.flags.bloat
	local specialApps = {
		discord = {
			name = "discord",
			cmd = appCmd("discord"),
			match = { class = "^(discord|vesktop)$" },
		},
		steam = {
			name = "steam",
			cmd = appCmd("steam"),
			match = { class = "^steam$" },
		},
	}

	local function set_layout(layout)
		local workspace = current_workspace()
		if workspace then
			set_workspace_layout(workspace.name, layout)
		end
	end

	local function layout_message(layout, key, msg, desc)
		bind(key, layout_specific_bind(layout, hl.dsp.layout(msg)), desc)
	end

	local function layout_action(layout, key, action, desc)
		bind(key, layout_specific_bind(layout, action), desc)
	end

	submap("passthrough", function() end)

	submap("leader", function()
		bind("Space", hl.dsp.exec_cmd(cfg.walkerCommands.launcher), "Launcher")
		bind("O", hl.dsp.exec_cmd(cfg.walkerCommands.launcher), "Launcher")
		bind("Return", hl.dsp.exec_cmd(cfg.terminalCommands.main), "Terminal")
		bind("grave", hl.dsp.workspace.toggle_special("dropdown"), "Dropdown terminal")
		bind("C", hl.dsp.exec_cmd(cfg.walkerCommands.clipboard), "Clipboard")
		bind("D", hl.dsp.exec_cmd(cfg.walkerCommands.commands), "Commands")
		bind("B", hl.dsp.exec_cmd(cfg.walkerCommands.bitwarden), "Bitwarden")
		bind("Y", hl.dsp.exec_cmd(cfg.walkerCommands.files), "Files")
		bind("Z", hl.dsp.exec_cmd(cfg.walkerCommands.windows), "Windows")
		bind("slash", function()
			toggle_submap_options()
		end, "Submap options", { closeCheatsheet = false })

		bind_entry_submaps(bindSubmap)

		bind("M", function()
			toggle_fake_fullscreen(0, 2)
		end, "Maximize")
		bind("F", hl.dsp.window.fullscreen({ mode = "fullscreen" }), "Toggle fullscreen")
		bind("T", hl.dsp.window.float({ action = "toggle" }), "Toggle floating")
		bind("P", function()
			toggle_picture_in_picture()
		end, "Picture in picture")
		bind("Q", hl.dsp.window.close(), "Close")
		bind("SHIFT + B", hl.dsp.window.move({ workspace = "special:minimized", follow = false }), "Minimize")
		bind("S", hl.dsp.layout("swapsplit"), "Swap split")
		bind("X", function()
			mark_or_swap()
		end, "Mark / swap")
		bind("N", hl.dsp.exec_cmd(cfg.noctalia .. " ipc call notifications dismissAll"), "Clear notifs")
	end)

	submap("walker", function()
		bind_walker_commands()
	end)

	submap("apps", function()
		bind("Return", hl.dsp.exec_cmd(cfg.terminalCommands.main), "Open terminal")
		bind("W", hl.dsp.exec_cmd(cfg.browser), "Open browser")
		bind("SHIFT + W", hl.dsp.exec_cmd(appCmd("qutebrowser")), "Open qutebrowser")
		bind("P", hl.dsp.exec_cmd(cfg.privateBrowser), "Open private browser")
		bind("B", hl.dsp.exec_cmd(cfg.walkerCommands.bitwarden), "Open Bitwarden")
		bind("SHIFT + B", hl.dsp.exec_cmd(cfg.passManager), "Open password manager")
		bind("F", hl.dsp.exec_cmd(cfg.walkerCommands.files), "Open files")
		bind("R", hl.dsp.exec_cmd(cfg.walkerCommands.commands), "Run command")
		bind("S", hl.dsp.exec_cmd(cfg.screenshot.region), "Take screenshot")
		if hasBloat then
			bind("D", function()
				openSpecialApp(specialApps.discord)
			end, "Discord")
		end
		if hasGaming then
			bind("G", function()
				openSpecialApp(specialApps.steam)
			end, "Steam")
			bind("SHIFT + G", hl.dsp.exec_cmd(appCmd("steam-games")), "Steam games")
		end
		if hasBloat then
			bind("M", hl.dsp.exec_cmd(appCmd("tidal-hifi")), "Open Tidal")
		end
		bind("C", hl.dsp.exec_cmd(cfg.walkerCommands.clipboard), "Open clipboard")
		bind("Space", hl.dsp.exec_cmd(cfg.walkerCommands.launcher), "Open launcher")
		bind("Z", hl.dsp.exec_cmd(cfg.walkerCommands.windows), "Open windows")
		bind("V", hl.dsp.exec_cmd(cfg.volumeMixer), "Open volume mixer")
		bind("I", hl.dsp.exec_cmd(appCmd("valent")), "Open phone")
		bind("K", hl.dsp.workspace.toggle_special("calc"), "Open calculator")
		bindSubmap("O", "walker", "Walker")
		for _, entry in ipairs(cfg.submapEntries or {}) do
			bindSubmap(entry.key, entry.submap, entry.label)
		end
	end)

	submap("window", function()
		bind("M", function()
			toggle_fake_fullscreen(2, 0)
		end, "Maximize")
		bindSubmap("V", "windowMove", "Move window")
		bindSubmap("R", "windowResize", "Resize window")
		bind("F", hl.dsp.window.fullscreen({ mode = "fullscreen" }), "Toggle fullscreen")
		bind("T", hl.dsp.window.float({ action = "toggle" }), "Toggle floating")
		bind("P", function()
			toggle_picture_in_picture()
		end, "Picture in picture")
		bind("Q", hl.dsp.window.close(), "Close window")
		bind("B", hl.dsp.window.move({ workspace = "special:minimized", follow = false }), "Minimize")
		bind("S", hl.dsp.layout("swapsplit"), "Swap split")
		bind("X", function()
			mark_or_swap()
		end, "Mark / swap")
		bindSubmap("G", "group", "Groups")
	end)

	submap("windowMove", function()
		bindBack("window", "Back to windows")
		bind("left", hl.dsp.window.move({ direction = "l" }), "Move left", { repeating = true })
		bind("right", hl.dsp.window.move({ direction = "r" }), "Move right", { repeating = true })
		bind("up", hl.dsp.window.move({ direction = "u" }), "Move up", { repeating = true })
		bind("down", hl.dsp.window.move({ direction = "d" }), "Move down", { repeating = true })
	end, { persistent = true })

	submap("windowResize", function()
		bindBack("window", "Back to windows")
		bind("SHIFT + left", hl.dsp.window.resize({ x = 75, y = 0, relative = true }), "Resize left", { repeating = true })
		bind("SHIFT + right", hl.dsp.window.resize({ x = -75, y = 0, relative = true }), "Resize right", { repeating = true })
		bind("SHIFT + up", hl.dsp.window.resize({ x = 0, y = -75, relative = true }), "Resize up", { repeating = true })
		bind("SHIFT + down", hl.dsp.window.resize({ x = 0, y = 75, relative = true }), "Resize down", { repeating = true })
		bind("CONTROL + left", hl.dsp.window.resize({ x = 160, y = 0, relative = true }), "Resize left big", { repeating = true })
		bind("CONTROL + right", hl.dsp.window.resize({ x = -160, y = 0, relative = true }), "Resize right big", { repeating = true })
		bind("CONTROL + up", hl.dsp.window.resize({ x = 0, y = -160, relative = true }), "Resize up big", { repeating = true })
		bind("CONTROL + down", hl.dsp.window.resize({ x = 0, y = 160, relative = true }), "Resize down big", { repeating = true })
	end, { persistent = true })

	submap("layout", function()
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

		layout_message("master", "O", "mfact exact 0.5", "[Master] Master ratio 50%")
		layout_message("master", "U", "mfact exact 0.65", "[Master] Master ratio 65%")
		layout_message("master", "left", "orientationleft", "[Master] Orient left")
		layout_message("master", "up", "orientationcenter", "[Master] Orient center")
		layout_message("master", "down", "orientationcenter", "[Master] Orient center")
		layout_message("master", "right", "orientationright", "[Master] Orient right")

		layout_message("dwindle", "T", "movetoroot active", "[Dwindle] Move window to root")
		layout_message("dwindle", "minus", "splitratio -0.1", "[Dwindle] Shrink split")
		layout_message("dwindle", "equal", "splitratio +0.1", "[Dwindle] Grow split")
		layout_message("dwindle", "O", "splitratio 1.0 exact", "[Dwindle] Split ratio even")
		layout_message("dwindle", "A", "rotatesplit 90", "[Dwindle] Rotate split")
		layout_message("dwindle", "left", "preselect l", "[Dwindle] Preselect left")
		layout_message("dwindle", "right", "preselect r", "[Dwindle] Preselect right")
		layout_message("dwindle", "up", "preselect u", "[Dwindle] Preselect up")
		layout_message("dwindle", "down", "preselect d", "[Dwindle] Preselect down")
		layout_action("dwindle", "SHIFT + P", hl.dsp.window.pseudo(), "[Dwindle] Toggle pseudo")

		layout_message("scrolling", "period", "move +col", "[Scrolling] Next column")
		layout_message("scrolling", "comma", "move -col", "[Scrolling] Previous column")
		layout_message("scrolling", "bracketright", "colresize +conf", "[Scrolling] Widen column")
		layout_message("scrolling", "bracketleft", "colresize -conf", "[Scrolling] Narrow column")
		layout_message("scrolling", "H", "focus l", "[Scrolling] Focus left")
		layout_message("scrolling", "L", "focus r", "[Scrolling] Focus right")
		layout_message("scrolling", "F", "fit visible", "[Scrolling] Fit visible")
		layout_message("scrolling", "A", "fit active", "[Scrolling] Fit active")
		layout_message("scrolling", "O", "fit all", "[Scrolling] Fit all")
		layout_message("scrolling", "Home", "fit tobeg", "[Scrolling] Fit start")
		layout_message("scrolling", "End", "fit toend", "[Scrolling] Fit end")
		layout_message("scrolling", "SHIFT + P", "promote", "[Scrolling] Promote to column")
		layout_message("scrolling", "E", "expel", "[Scrolling] Expel to column")
		layout_message("scrolling", "C", "consume", "[Scrolling] Consume previous column")
		layout_message("scrolling", "B", "consume_or_expel prev", "[Scrolling] Consume or expel previous")
		layout_message("scrolling", "V", "consume_or_expel next", "[Scrolling] Consume or expel next")
		layout_message("scrolling", "I", "inhibit_scroll", "[Scrolling] Toggle scroll lock")
		layout_message("scrolling", "Y", "togglefit", "[Scrolling] Toggle fit")

		bind("J", layout_bind({
			scrolling = hl.dsp.layout("swapcol l"),
			dwindle = hl.dsp.layout("swapsplit"),
			monocle = hl.dsp.layout("cycleprev"),
			master = hl.dsp.layout("cycleprev"),
		}), "Layout previous / swap left")
		bind("K", layout_bind({
			scrolling = hl.dsp.layout("swapcol r"),
			dwindle = hl.dsp.layout("togglesplit"),
			monocle = hl.dsp.layout("cyclenext"),
			master = hl.dsp.layout("cyclenext"),
		}), "Layout next / swap right")
		bind("N", function()
			hl.config({ general = { gaps_out = 0 } })
			hl.config({ general = { gaps_in = 0 } })
			hl.config({ decoration = { rounding = 0 } })
		end, "Gapless preset")
		bind("P", function()
			hl.config({ general = { gaps_out = theme.gaps_out } })
			hl.config({ general = { gaps_in = theme.gaps_in } })
			hl.config({ decoration = { rounding = theme.rounding } })
		end, "Default preset")
	end)

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

	submap("system", function()
		bind("N", hl.dsp.exec_cmd(cfg.noctalia .. " ipc call notifications dismissAll"), "Clear notifs")
		bind("S", hl.dsp.exec_cmd(cfg.screenshot.region), "Screenshot (region)")
		bind("SHIFT + S", hl.dsp.exec_cmd(cfg.screenshot.fullscreen), "Screenshot (full)")
		bind("A", hl.dsp.exec_cmd("pkill -SIGUSR1 wayscriber"), "Annotate")
		bind("C", hl.dsp.exec_cmd(cfg.hyprpicker .. " -a"), "Color picker")
		bind("L", hl.dsp.exec_cmd(cfg.locker), "Lock")
		bind("SHIFT + O", hl.dsp.exec_cmd('loginctl terminate-user "$(whoami)"'), "Logout")
		bindSubmap("R", "confirmReboot", "Confirm reboot")
		bindSubmap("X", "confirmShutdown", "Confirm shutdown")
	end)

	submap("confirmReboot", function()
		bindBack("system", "Back to system")
		bind("R", hl.dsp.exec_cmd("systemctl reboot"), "Reboot")
	end)

	submap("confirmShutdown", function()
		bindBack("system", "Back to system")
		bind("X", hl.dsp.exec_cmd("systemctl poweroff"), "Shutdown")
	end)

	submap("media", function()
		bind("Space", hl.dsp.exec_cmd("playerctl -p playerctld play-pause"), "Play pause")
		bind("P", hl.dsp.exec_cmd("playerctl -p playerctld previous"), "Previous track")
		bind("N", hl.dsp.exec_cmd("playerctl -p playerctld next"), "Next track")
		bind("left", hl.dsp.exec_cmd("playerctl -p playerctld position 10-"), "Seek -10s")
		bind("right", hl.dsp.exec_cmd("playerctl -p playerctld position 10+"), "Seek +10s")
		bind("minus", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_SINK@ 5%-"), "Volume down")
		bind("plus", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_SINK@ 5%+"), "Volume up")
		bind("M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SINK@ toggle"), "Toggle mute")
		bind("V", hl.dsp.exec_cmd(cfg.volumeMixer), "Volume Mixer")
	end)

end

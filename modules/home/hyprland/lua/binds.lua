-- ============================================================
-- TOP-LEVEL BINDS
-- ============================================================
return function(ctx)
	local hl = ctx.hl
	local commands = ctx.commands
	local features = ctx.features
	local binds = ctx.bindHelpers
	local mod = binds.mod
	local bind = binds.bind
	local mbind = binds.mbind
	local bindSubmap = binds.bindSubmap
	local mbindSubmap = binds.mbindSubmap
	local mark_or_swap = ctx.window.markOrSwap
	local smart_focus = ctx.smartFocus
	local cycle_workspace_layout = ctx.layout.cycleWorkspaceLayout
	local layout_specific_bind = ctx.layout.specific
	local toggle_submap_options = binds.toggleOptions
	local toggle_hyprbars_tiled = ctx.window.toggleHyprbarsTiled

	local function toggle_fake_fullscreen(internal, client)
		hl.dispatch(hl.dsp.window.tag({ tag = "fake-fullscreen-borderless" }))
		hl.dispatch(hl.dsp.window.fullscreen_state({ internal = internal, client = client, action = "toggle" }))
	end

	local function toggle_picture_in_picture()
		hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
		hl.dispatch(hl.dsp.window.pin())
		toggle_fake_fullscreen(2, 0)
	end

	local directions = {
		{ key = "left", hypr = "l" },
		{ key = "right", hypr = "r" },
		{ key = "up", hypr = "u" },
		{ key = "down", hypr = "d" },
	}

	local function bind_entry_submaps(bind_fn)
		bind_fn("W", "window", "Windows")
		bind_fn("A", "apps", "Apps")
		bind_fn("L", "layout", "Layout")
		bind_fn("G", "group", "Groups")
		bind_fn("SHIFT + O", "walker", "Walker")
		bind_fn("bracketleft", "system", "System")
		bind_fn("V", "media", "Media")
		if features.emacs then
			bind_fn("E", "emacs", "Emacs")
		end
		if features.tmux then
			bind_fn("T", "tmux", "Tmux")
		end
	end

	local function bind_walker_commands()
		bind("Space", hl.dsp.exec_cmd(commands.noctaliaLauncher), "Launcher")
		bind("O", hl.dsp.exec_cmd(commands.noctaliaLauncher), "Launcher")
		bind("F", hl.dsp.exec_cmd(commands.files), "Files")
		bind("D", hl.dsp.exec_cmd(commands.walker.commands), "Commands")
		bind("C", hl.dsp.exec_cmd(commands.walker.clipboard), "Clipboard")
		bind("B", hl.dsp.exec_cmd(commands.walker.bitwarden), "Bitwarden")
		bind("W", hl.dsp.exec_cmd(commands.walker.windows), "Windows")
		if features.gaming then
			bind("G", hl.dsp.exec_cmd(commands.app("steam-games")), "Steam games")
		end
	end

	ctx.bindHelpers.entrySubmaps = bind_entry_submaps
	ctx.bindHelpers.walkerSubmap = bind_walker_commands
	ctx.window.toggleFakeFullscreen = toggle_fake_fullscreen
	ctx.window.togglePictureInPicture = toggle_picture_in_picture

	-- Mouse drag/resize
	bind(mod .. " + mouse:272", hl.dsp.window.drag(), "Move window", { mouse = true })
	bind(mod .. " + mouse:273", hl.dsp.window.resize(), "Resize window", { mouse = true })

	-- Submap entry points
	bind_entry_submaps(mbindSubmap)
	-- Core actions
	mbind("Space", hl.dsp.exec_cmd(commands.noctaliaLauncher), "Launcher")
	mbind("O", hl.dsp.exec_cmd(commands.noctaliaLauncher), "Launcher")
	mbind("Y", hl.dsp.exec_cmd(commands.files), "Files")
	mbind("D", hl.dsp.exec_cmd(commands.walker.commands), "Commands")
	mbind("C", hl.dsp.exec_cmd(commands.walker.clipboard), "Clipboard")
	mbind("B", hl.dsp.exec_cmd(commands.walker.bitwarden), "Bitwarden")
	mbind("Z", hl.dsp.exec_cmd(commands.walker.windows), "Windows")
	mbind("M", function()
		toggle_fake_fullscreen(0, 2)
	end, "Maximize")
	mbind("CONTROL + M", hl.dsp.window.fullscreen({ mode = "fullscreen" }), "Toggle fullscreen")
	mbind("F", hl.dsp.window.float({ action = "toggle" }), "Toggle floating")
	mbind("P", function()
		toggle_picture_in_picture()
	end, "Picture in picture")
	mbind("CONTROL + Return", hl.dsp.workspace.toggle_special("dropdown"), "Dropdown terminal")
	mbind("CONTROL + P", hl.dsp.window.pin(), "Toggle pin")
	mbind("CONTROL + B", function()
		toggle_hyprbars_tiled()
	end, "Toggle tiled hyprbars")
	mbind("SHIFT + slash", function()
		toggle_submap_options()
	end, "Submap options")
	mbind("CONTROL + Space", hl.dsp.layout("swapsplit"), "Swap split")
	mbind("SHIFT + Q", hl.dsp.window.close(), "Close")
	mbind("X", function()
		mark_or_swap()
	end, "Mark / swap window")
	mbind("tab", function()
		cycle_workspace_layout()
	end, "Cycle workspace layout")
	mbind("N", hl.dsp.exec_cmd(commands.noctalia .. " ipc call notifications dismissAll"), "Clear notifs")
	mbindSubmap("ALT + BackSpace", "passthrough", "Passthrough")

	for _, d in ipairs(directions) do
		local key, dir = d.key, d.hypr
		mbind(key, function()
			smart_focus(key)
		end, "Focus " .. key, { cheatsheet = false })
		mbind("SHIFT + " .. key, hl.dsp.window.move({ direction = dir }), "Move " .. key)
		mbind(
			"CONTROL + " .. key,
			layout_specific_bind("dwindle", hl.dsp.layout("preselect " .. dir)),
			"Preselect " .. key,
			{ cheatsheet = false }
		)
	end

	-- Terminal
	mbind("Return", hl.dsp.exec_cmd(commands.terminal.main), "Terminal")
	mbind("SHIFT + Return", hl.dsp.exec_cmd(commands.terminal.pinned), "Kitty pinned")

	-- Workspace switch + move-to (1..10, with key 0 mapped to workspace ID 10)
	for i = 1, 9 do
		local key = tostring(i % 10)
		local workspace = tostring(i)
		local label = key
		mbind(key, hl.dsp.focus({ workspace = workspace }), "Workspace " .. label)
		mbind("SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace, follow = false }), "Move to ws " .. label)
	end
	mbind("0", hl.dsp.focus({ workspace = "10" }), "Workspace 10")
	mbind("SHIFT +" .. "0", hl.dsp.window.move({ workspace = "10", follow = false }), "Move to ws 10")

	-- Master ratio
	mbind(
		"minus",
		layout_specific_bind("master", hl.dsp.layout("mfact -0.05")),
		"Master ratio -",
		{ repeating = true }
	)
	mbind(
		"SHIFT + minus",
		layout_specific_bind("master", hl.dsp.layout("mfact -0.125")),
		"Master ratio --",
		{ repeating = true }
	)
	mbind("plus", layout_specific_bind("master", hl.dsp.layout("mfact +0.05")), "Master ratio +", { repeating = true })
	mbind(
		"SHIFT + plus",
		layout_specific_bind("master", hl.dsp.layout("mfact +0.125")),
		"Master ratio ++",
		{ repeating = true }
	)

	-- Volume / seek
	bind(
		"XF86AudioRaiseVolume",
		hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_SINK@ 5%+"),
		"Volume up",
		{ repeating = true }
	)
	bind(
		"XF86AudioLowerVolume",
		hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_SINK@ 5%-"),
		"Volume down",
		{ repeating = true }
	)
	bind("XF86AudioForward", hl.dsp.exec_cmd("playerctl -p playerctld position 10+"), "Seek +10s", { repeating = true })
	bind("XF86AudioRewind", hl.dsp.exec_cmd("playerctl -p playerctld position 10-"), "Seek -10s", { repeating = true })

	-- Media keys
	bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl -p playerctld previous"), "Previous track", { locked = true })
	bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl -p playerctld next"), "Next track", { locked = true })
	bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl -p playerctld play"), "Play", { locked = true })
	bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl -p playerctld pause"), "Pause", { locked = true })
	bindSubmap("XF86AudioMedia", "media", "Media", { locked = true })
	bind("XF86Messenger", hl.dsp.workspace.toggle_special(), "Special workspace", { locked = true })
end

-- ============================================================
-- TOP-LEVEL BINDS
-- ============================================================
return function(ctx)
	local hl = ctx.hl
	local commands = ctx.commands
	local binds = ctx.bindHelpers
	local mod = binds.mod
	local bind = binds.bind
	local mbind = binds.mbind
	local bindSubmap = binds.bindSubmap
	local mbindSubmap = binds.mbindSubmap
	local bind_entry_submaps = binds.entrySubmaps
	local mark_or_swap = ctx.window.markOrSwap
	local smart_focus = ctx.smartFocus
	local layout_bind = ctx.layout.bind
	local toggle_submap_options = binds.toggleOptions
	local toggle_hyprbars_tiled = ctx.window.toggleHyprbarsTiled

	local directions = {
		{ key = "left", hypr = "l" },
		{ key = "right", hypr = "r" },
		{ key = "up", hypr = "u" },
		{ key = "down", hypr = "d" },
	}

	local function split_group_for_direction(direction)
		if direction == "l" or direction == "r" then
			return "h"
		end
		return "v"
	end

	local kitty_classes = {
		kitty = true,
		dropdown = true,
		pinned = true,
		["floating-editor"] = true,
	}

	local function open_terminal()
		local active = hl.get_active_window and hl.get_active_window()
		local pid = active and tonumber(active.pid) or nil
		local rt = os.getenv("XDG_RUNTIME_DIR")
		local terminal = ctx.cfg.apps and ctx.cfg.apps.terminal or nil

		if terminal and rt and pid and active and kitty_classes[active.class or ""] then
			hl.exec_cmd(
				terminal
					.. " @ --to unix:"
					.. rt
					.. "/kitty-"
					.. tostring(pid)
					.. " launch --type=os-window --cwd=current"
			)
			return
		end

		hl.exec_cmd(commands.terminal.main)
	end

	-- Mouse drag/resize
	bind(mod .. " + mouse:272", hl.dsp.window.drag(), "Move window", { mouse = true })
	bind(mod .. " + mouse:273", hl.dsp.window.resize(), "Resize window", { mouse = true })

	-- Submap entry points
	bind_entry_submaps(mbindSubmap)
	-- Core actions
	mbind("Space", hl.dsp.exec_cmd(commands.noctaliaLauncher), "Launcher")
	mbind("O", hl.dsp.exec_cmd(commands.noctaliaLauncher), "Launcher")
	mbind("Y", hl.dsp.exec_cmd(commands.files.emacs), "Files")
	mbind("D", hl.dsp.exec_cmd(commands.walker.commands), "Commands")
	mbind("C", hl.dsp.exec_cmd(commands.walker.clipboard), "Clipboard")
	mbind("B", hl.dsp.exec_cmd(commands.walker.bitwarden), "Bitwarden")
	mbind("Z", hl.dsp.exec_cmd(commands.walker.windows), "Windows")
	mbind("M", function()
		ctx.window.toggleFakeFullscreen(0, 2)
	end, "Maximize")
	mbind("CONTROL + M", hl.dsp.window.fullscreen({ mode = "fullscreen" }), "Toggle fullscreen")
	mbind("F", hl.dsp.window.float({ action = "toggle" }), "Toggle floating")
	mbind("P", function()
		ctx.window.togglePictureInPicture()
	end, "Picture in picture")
	mbind("CONTROL + Return", hl.dsp.workspace.toggle_special("dropdown"), "Dropdown terminal")
	mbind("CONTROL + P", hl.dsp.window.pin(), "Toggle pin")
	mbind("CONTROL + B", function()
		toggle_hyprbars_tiled()
	end, "Toggle tiled hyprbars")
	mbind("SHIFT + slash", function()
		toggle_submap_options()
	end, "Submap options")
	mbind(
		"CONTROL + Space",
		layout_bind({
			hy3 = ctx.layout.hy3.changeGroup("opposite"),
			default = hl.dsp.layout("swapsplit"),
		}),
		"Swap split"
	)
	mbind("SHIFT + Q", hl.dsp.window.close(), "Close")
	mbind("X", function()
		mark_or_swap()
	end, "Mark / swap window")

	mbind("N", hl.dsp.exec_cmd(commands.notifications.clearActive), "Clear notifs")
	mbindSubmap("ALT + BackSpace", "state", "State")

	for _, d in ipairs(directions) do
		local key, dir = d.key, d.hypr
		mbind(key, function()
			smart_focus(key)
		end, "Focus " .. key, { cheatsheet = false })
		mbind(
			"SHIFT + " .. key,
			layout_bind({
				hy3 = ctx.layout.hy3.moveWindow(dir),
				default = hl.dsp.window.move({ direction = dir }),
			}),
			"Move " .. key
		)
		mbind(
			"CONTROL + " .. key,
			layout_bind({
				hy3 = ctx.layout.hy3.makeGroup(split_group_for_direction(dir)),
				dwindle = hl.dsp.layout("preselect " .. dir),
			}),
			"Split " .. key,
			{ cheatsheet = false }
		)
	end

	-- Terminal
	mbind("Return", function()
		open_terminal()
	end, "Terminal")

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
	mbind("minus", ctx.layout.specific("master", hl.dsp.layout("mfact -0.05")), "Master ratio -", { repeating = true })
	mbind(
		"SHIFT + minus",
		ctx.layout.specific("master", hl.dsp.layout("mfact -0.125")),
		"Master ratio --",
		{ repeating = true }
	)
	mbind("plus", ctx.layout.specific("master", hl.dsp.layout("mfact +0.05")), "Master ratio +", { repeating = true })
	mbind(
		"SHIFT + plus",
		ctx.layout.specific("master", hl.dsp.layout("mfact +0.125")),
		"Master ratio ++",
		{ repeating = true }
	)

	-- Volume / seek
	bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(commands.volume.up), "Volume up", { repeating = true })
	bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(commands.volume.down), "Volume down", { repeating = true })
	bind("XF86AudioForward", hl.dsp.exec_cmd(commands.media.seekForward), "Seek +10s", { repeating = true })
	bind("XF86AudioRewind", hl.dsp.exec_cmd(commands.media.seekBackward), "Seek -10s", { repeating = true })

	-- Media keys
	bind("XF86AudioPrev", hl.dsp.exec_cmd(commands.media.previous), "Previous track", { locked = true })
	bind("XF86AudioNext", hl.dsp.exec_cmd(commands.media.next), "Next track", { locked = true })
	bind("XF86AudioPlay", hl.dsp.exec_cmd(commands.media.toggle), "Play", { locked = true })
	bind("XF86AudioPause", hl.dsp.exec_cmd(commands.media.toggle), "Pause", { locked = true })
	bindSubmap("XF86AudioMedia", "media", "Media", { locked = true })
	bind("XF86Messenger", hl.dsp.workspace.toggle_special(), "Special workspace", { locked = true })
end

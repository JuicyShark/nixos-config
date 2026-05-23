-- ============================================================
-- TOP-LEVEL BINDS
-- ============================================================
return function(ctx)
	local hl = ctx.hl
	local cfg = ctx.cfg
	local mod = ctx.mod
	local bind = ctx.bind
	local mbind = ctx.mbind
	local bindSubmap = ctx.bindSubmap
	local mbindSubmap = ctx.mbindSubmap
	local bindBack = ctx.bindBack
	local submap = ctx.submap
	local mark_or_swap = ctx.mark_or_swap
	local openSpecialApp = ctx.openSpecialApp
	local smart_focus = ctx.smartFocus
	local cheatsheet = ctx.cheatsheet
	local hasGaming = cfg.flags.gaming
	local hasBloat = cfg.flags.bloat
	local hasEmacs = cfg.flags.emacs

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

	local resize_steps = {
		{ key = "left", x = 75, y = 0 },
		{ key = "right", x = -75, y = 0 },
		{ key = "up", x = 0, y = -75 },
		{ key = "down", x = 0, y = 75 },
	}

	local resize_large_steps = {
		{ key = "left", x = 160, y = 0 },
		{ key = "right", x = -160, y = 0 },
		{ key = "up", x = 0, y = -160 },
		{ key = "down", x = 0, y = 160 },
	}

	-- Mouse drag/resize
	bind(mod .. " + mouse:272", hl.dsp.window.drag(), "Move window", { mouse = true })
	bind(mod .. " + mouse:273", hl.dsp.window.resize(), "Resize window", { mouse = true })

	-- Submap entry points
	for _, e in ipairs({
		{ "W", "window", "Windows" },
		{ "A", "apps", "Apps" },
		{ "L", "layout", "Layout" },
		{ "G", "group", "Groups" },
		{ "bracketleft", "system", "System" },
		{ "V", "media", "Media" },
	}) do
		mbindSubmap(e[1], e[2], e[3])
	end
	if hasEmacs then
		mbindSubmap("E", "emacs", "Emacs")
	end

	-- Core actions
	mbindSubmap("Space", "leader", "Leader")
	mbind("O", hl.dsp.exec_cmd(cfg.noctalia .. " ipc call launcher toggle"), "Launcher")
	mbind("M", function()
		toggle_fake_fullscreen(0, 2)
	end, "Maximize")
	mbind("F", hl.dsp.window.fullscreen({ mode = "fullscreen" }), "Toggle fullscreen")
	mbind("T", hl.dsp.window.float({ action = "toggle" }), "Toggle floating")
	mbind("CONTROL + Return", hl.dsp.workspace.toggle_special("dropdown"), "Dropdown terminal")
	mbind("CONTROL + P", hl.dsp.window.pin(), "Toggle pin")
	mbind("SHIFT + slash", hl.dsp.exec_cmd(cfg.submapCheatsheetToggle), "Submap options")
	mbind("CONTROL + Space", hl.dsp.layout("swapsplit"), "Swap split")
	mbind("SHIFT + Q", hl.dsp.window.close(), "Close")
	mbind("X", function()
		mark_or_swap()
	end, "Mark / swap window")
	mbindSubmap("ALT + BackSpace", "passthrough", "Passthrough")

	for _, d in ipairs(directions) do
		local key, dir = d.key, d.hypr
		mbind(key, function()
			smart_focus(key)
		end, "Focus " .. key, { cheatsheet = false })
		mbind("SHIFT + " .. key, hl.dsp.window.move({ direction = dir }), "Move " .. key)
		mbind("CONTROL + " .. key, hl.dsp.layout("focus " .. dir), "Move focus " .. key, { cheatsheet = false })
	end

	-- Terminal
	mbind("Return", hl.dsp.exec_cmd(cfg.terminalCommands.main), "Terminal")
	mbind("SHIFT + Return", hl.dsp.exec_cmd(cfg.terminalCommands.pinned), "Kitty pinned")

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

	-- Screenshots
	for _, s in ipairs({
		{ "Print", "fullscreen", "Screenshot (full)" },
		{ "ALT + Print", "window", "Screenshot (window)" },
	}) do
		bind(s[1], hl.dsp.exec_cmd(cfg.screenshot[s[2]]), s[3], { locked = true })
	end

	-- Master ratio (repeating)
	for _, m in ipairs({
		{ "minus", "mfact -0.05", "Master ratio -" },
		{ "SHIFT + minus", "mfact -0.125", "Master ratio --" },
		{ "plus", "mfact +0.05", "Master ratio +" },
		{ "SHIFT + plus", "mfact +0.125", "Master ratio ++" },
	}) do
		mbind(m[1], hl.dsp.layout(m[2]), m[3], { repeating = true })
	end
	for _, r in ipairs(resize_steps) do
		mbind(
			"ALT + " .. r.key,
			hl.dsp.window.resize({ x = r.x, y = r.y, relative = true }),
			"Resize " .. r.key,
			{ repeating = true }
		)
	end

	-- Volume / seek (repeating)
	for _, v in ipairs({
		{ "XF86AudioRaiseVolume", "wpctl set-volume @DEFAULT_SINK@ 5%+", "Volume up" },
		{ "XF86AudioLowerVolume", "wpctl set-volume @DEFAULT_SINK@ 5%-", "Volume down" },
		{ "XF86AudioForward", "playerctl -p playerctld position 10+", "Seek +10s" },
		{ "XF86AudioRewind", "playerctl -p playerctld position 10-", "Seek -10s" },
	}) do
		bind(v[1], hl.dsp.exec_cmd(v[2]), v[3], { repeating = true })
	end

	-- Media (locked)
	for _, p in ipairs({
		{ "XF86AudioPrev", "previous", "Previous track" },
		{ "XF86AudioNext", "next", "Next track" },
		{ "XF86AudioPlay", "play", "Play" },
		{ "XF86AudioPause", "pause", "Pause" },
	}) do
		bind(p[1], hl.dsp.exec_cmd("playerctl -p playerctld " .. p[2]), p[3], { locked = true })
	end
	bind("XF86AudioMedia", hl.dsp.submap("media"), "Media", { locked = true })
	bind("XF86Messenger", hl.dsp.workspace.toggle_special(), "Special workspace", { locked = true })

	-- ============================================================
	-- SUBMAPS
	-- ============================================================

	submap("passthrough", function() end)

	submap("leader", function()
		bind("Space", hl.dsp.exec_cmd(cfg.noctalia .. " ipc call launcher toggle"), "Launcher")
		bind("O", hl.dsp.exec_cmd(cfg.noctalia .. " ipc call launcher toggle"), "Launcher")
		bind("Return", hl.dsp.exec_cmd(cfg.terminalCommands.main), "Terminal")
		bind("grave", hl.dsp.workspace.toggle_special("dropdown"), "Dropdown terminal")
		bind("C", hl.dsp.exec_cmd(cfg.noctalia .. " ipc call launcher clipboard"), "Clipboard")
		bind("slash", hl.dsp.exec_cmd(cfg.submapCheatsheetToggle), "Submap options")

		for _, e in ipairs({
			{ "W", "window", "Windows" },
			{ "A", "apps", "Apps" },
			{ "L", "layout", "Layout" },
			{ "G", "group", "Groups" },
			{ "bracketleft", "system", "System" },
			{ "V", "media", "Media" },
		}) do
			bindSubmap(e[1], e[2], e[3])
		end
		if hasEmacs then
			bindSubmap("E", "emacs", "Emacs")
		end

		bind("M", function()
			toggle_fake_fullscreen(0, 2)
		end, "Maximize")
		bind("F", hl.dsp.window.fullscreen({ mode = "fullscreen" }), "Toggle fullscreen")
		bind("T", hl.dsp.window.float({ action = "toggle" }), "Toggle floating")
		bind("P", function()
			toggle_picture_in_picture()
		end, "Picture in picture")
		bind("Q", hl.dsp.window.close(), "Close")
		bind("B", hl.dsp.window.move({ workspace = "special:minimized", follow = false }), "Minimize")
		bind("S", hl.dsp.layout("swapsplit"), "Swap split")
		bind("X", function()
			mark_or_swap()
		end, "Mark / swap")
		bind("N", hl.dsp.exec_cmd(cfg.noctalia .. " ipc call notifications dismissAll"), "Clear notifs")
	end)

	submap("apps", function()
		bind("Return", hl.dsp.exec_cmd(cfg.terminalCommands.main), "Open terminal")
		bind("W", hl.dsp.exec_cmd(cfg.browser), "Open browser")
		bind("SHIFT + W", hl.dsp.exec_cmd("qutebrowser"), "Open qutebrowser")
		bind("P", hl.dsp.exec_cmd(cfg.privateBrowser), "Open private browser")
		bind("B", hl.dsp.exec_cmd(cfg.passManager), "Open password manager")
		bind("S", hl.dsp.exec_cmd(cfg.screenshot.region), "Take screenshot")
		if hasBloat then
			bind("D", function()
				openSpecialApp({
					name = "discord",
					cmd = "discord",
					match = function(window)
						return window.class == "discord" or window.class == "vesktop"
					end,
				})
			end, "Discord")
		end
		if hasGaming then
			bind("G", function()
				openSpecialApp({
					name = "steam",
					cmd = "steam",
					match = { class = "^steam$" },
				})
			end, "Steam")
		end
		if hasBloat then
			bind("M", hl.dsp.exec_cmd("tidal-hifi"), "Open Tidal")
		end
		bind("C", hl.dsp.exec_cmd(cfg.noctalia .. " ipc call launcher clipboard"), "Open clipboard")
		bind("Space", hl.dsp.exec_cmd(cfg.noctalia .. " ipc call launcher toggle"), "Open launcher")
		bind("V", hl.dsp.exec_cmd(cfg.volumeMixer), "Open volume mixer")
		bind("I", hl.dsp.exec_cmd("valent"), "Open phone")
		bind("K", hl.dsp.workspace.toggle_special("calc"), "Open calculator")
		if hasEmacs then
			bindSubmap("E", "emacs", "Emacs")
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
		bind("S", hl.dsp.layout("swapsplit"), "Swap split")
		bind("X", function()
			mark_or_swap()
		end, "Mark / swap")
		bindSubmap("G", "group", "Groups")
	end)

	submap("windowMove", function()
		bindBack("window", "Back to windows")
		for _, d in ipairs(directions) do
			bind(d.key, hl.dsp.window.move({ direction = d.hypr }), "Move " .. d.key, { repeating = true })
		end
	end, { persistent = true })

	submap("windowResize", function()
		bindBack("window", "Back to windows")
		for _, r in ipairs(resize_steps) do
			bind(
				"SHIFT + " .. r.key,
				hl.dsp.window.resize({ x = r.x, y = r.y, relative = true }),
				"Resize " .. r.key,
				{ repeating = true }
			)
		end
		for _, r in ipairs(resize_large_steps) do
			bind(
				"CONTROL + " .. r.key,
				hl.dsp.window.resize({ x = r.x, y = r.y, relative = true }),
				"Resize " .. r.key .. " big",
				{ repeating = true }
			)
		end
	end, { persistent = true })

	submap("layout", function()
		-- Switch layout engine
		for _, l in ipairs({
			{ "M", "master", "Master" },
			{ "D", "dwindle", "Dwindle" },
			{ "C", "scrolling", "Scrolling" },
		}) do
			local lay = l[2]
			bind(l[1], function()
				hl.config({ general = { layout = lay } })
			end, l[3] .. " Layout")
		end
		-- Related action groups
		for _, s in ipairs({
			{ "W", "window", "Window Actions" },
			{ "G", "group", "Group Actions" },
			{ "V", "windowMove", "Move Window" },
			{ "R", "windowResize", "Resize Window" },
		}) do
			bindSubmap(s[1], s[2], s[3])
		end
		bind("T", hl.dsp.layout("movetoroot active"), "Move window to root")
		for _, l in ipairs({
			{ "O", "mfact exact 0.5", "[Master] Master ratio 50%" },
			{ "U", "mfact exact 0.65", "[Master] Master ratio 65%" },
			{ "left", "orientationleft", "[Master] Orient left" },
			{ "up", "orientationcenter", "[Master] Orient center" },
			{ "down", "orientationcenter", "[Master] Orient center" },
			{ "right", "orientationright", "[Master] Orient right" },
			{ "S", "togglesplit", "[Dwindle] Toggle split" },
			{ "period", "move +col", "[Scrolling] Next column" },
			{ "comma", "move -col", "[Scrolling] Previous column" },
			{ "bracketright", "colresize +0.05", "[Scrolling] Widen column" },
			{ "bracketleft", "colresize -0.05", "[Scrolling] Narrow column" },
			{ "J", "swapcol l", "[Scrolling] Swap column left" },
			{ "K", "swapcol r", "[Scrolling] Swap column right" },
			{ "H", "focus l", "[Scrolling] Focus left" },
			{ "L", "focus r", "[Scrolling] Focus right" },
			{ "F", "fit visible", "[Scrolling] Fit visible" },
			{ "Y", "togglefit", "[Scrolling] Toggle fit" },
		}) do
			bind(l[1], hl.dsp.layout(l[2]), l[3])
		end
		bind("N", function()
			hl.config({ general = { gaps_out = 0 } })
			hl.config({ general = { gaps_in = 0 } })
			hl.config({ decoration = { rounding = 0 } })
		end, "Gapless preset")
		bind("P", function()
			hl.config({ general = { gaps_out = cfg.theme.gaps_out } })
			hl.config({ general = { gaps_in = cfg.theme.gaps_in } })
			hl.config({ decoration = { rounding = cfg.theme.rounding } })
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
		bind("H", hl.dsp.exec_cmd("htb-vpn-toggle"), "HTB VPN toggle")
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

	if hasEmacs then
		submap("emacs", function()
			bind("E", hl.dsp.exec_cmd("emacsclient -r"), "Emacs raise")
			bind("F", function()
				local w = hl.get_windows({ class = "emacs" })[1]
				if w then
					hl.dispatch(hl.dsp.focus({ window = w }))
				end
			end, "Emacs focus")
			bind("N", hl.dsp.exec_cmd("emacsclient -c"), "Emacs new frame")
			bind("C", hl.dsp.exec_cmd("emacsclient -r ."), "Emacs cwd")
			bind(
				"D",
				hl.dsp.exec_cmd('emacsclient -c --eval "(call-interactively org-dailies-goto-today)"'),
				"Emacs org today"
			)
		end)
	end

	-- ============================================================
	-- CHEATSHEET DUMP
	-- ============================================================
	-- Serialize cheatsheet binds to JSON at $XDG_RUNTIME_DIR/hypr/$HIS/cheatsheet-binds.json
	-- so the submap-cheatsheet UI can read structured bind data instead of
	-- shelling out to `hyprctl -j binds` and re-parsing descriptions.
	local function json_escape(s)
		return (s:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t"))
	end

	local function add_string_field(parts, key, value)
		if type(value) == "string" then
			parts[#parts + 1] = '"' .. key .. '":"' .. json_escape(value) .. '"'
		end
	end

	local function add_true_field(parts, key, value)
		if value == true then
			parts[#parts + 1] = '"' .. key .. '":true'
		end
	end

	local function encode_cheatsheet_entry(entry)
		local parts = {}

		add_string_field(parts, "submap", entry.submap)
		add_string_field(parts, "combo", entry.combo)
		add_string_field(parts, "action", entry.action)
		add_string_field(parts, "targetSubmap", entry.targetSubmap)
		add_true_field(parts, "entersSubmap", entry.entersSubmap)
		add_true_field(parts, "isEscapeExit", entry.isEscapeExit)

		return "{" .. table.concat(parts, ",") .. "}"
	end

	local function encode_cheatsheet_json(entries)
		local items = {}
		for i, entry in ipairs(entries) do
			items[i] = "  " .. encode_cheatsheet_entry(entry)
		end
		return "[\n" .. table.concat(items, ",\n") .. "\n]\n"
	end

	do
		local rt = os.getenv("XDG_RUNTIME_DIR")
		local sig = os.getenv("HYPRLAND_INSTANCE_SIGNATURE")
		if rt and sig then
			local f = io.open(rt .. "/hypr/" .. sig .. "/cheatsheet-binds.json", "w")
			if f then
				f:write(encode_cheatsheet_json(cheatsheet))
				f:close()
			end
		end
	end
end

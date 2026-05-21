-- ============================================================
-- WORKSPACE / LAYER RULES
-- ============================================================
return function(ctx)
	local hl = ctx.hl
	local cfg = ctx.cfg
	local C = cfg.colors
	local hasGaming = cfg.flags.gaming
	local hasBloat = cfg.flags.bloat
	local hasZsa = cfg.flags.zsa
	local hasHaPresence = cfg.flags.haPresence
	local sunshine = cfg.sunshine or {}

	local function rgb(color)
		return "rgb(" .. color .. ")"
	end

	local terminalClass =
		"(kitty|dropdown|pinned|floating-editor|com.mitchellh.ghostty|org.wezfurlong.wezterm|org.alacritty|foot)"
	local chatClass = "(discord|vesktop|signal|org.telegram.desktop)"
	local utilityClass =
		"(thunar|com.saivert.pwvucontrol|RimPy|org.keepassxc.KeePassXC|bitwarden|Tk|nm-connection-editor|blueman-manager)"
	local devTagClass =
		"(kitty|dropdown|pinned|floating-editor|com.mitchellh.ghostty|org.wezfurlong.wezterm|org.alacritty|foot|code|codium|emacs|org.gnu.Emacs)"
	local browserClass =
		"(org.qutebrowser.qutebrowser|chromium-browser|Chromium|google-chrome|Google-chrome|chrome|vivaldi-stable|Vivaldi-stable|firefox|firefox-esr|librewolf|brave-browser|Brave-browser|microsoft-edge|Microsoft-edge)"
	local streamMonitor = sunshine.virtualMonitor or "HDMI-A-1"
	local streamSteamWorkspace = sunshine.steamWorkspace or "21"
	local streamGameWorkspace = sunshine.gameWorkspace or sunshine.virtualWorkspace or "22"

	for _, ws in ipairs({
		"1",
		"2",
		"3",
		"4",
		"5",
		"6",
		"7",
		"8",
		"9",
		"0",
		"special:minimized",
		"special:dropdown",
		"special:steam",
		"special:discord",
	}) do
		hl.workspace_rule({ workspace = ws, monitor = cfg.primary.selector })
	end
	hl.workspace_rule({ workspace = "2", default = true })
	hl.workspace_rule({ workspace = "4", gaps_in = 0, gaps_out = 0, no_rounding = true, decorate = true })
	hl.workspace_rule({
		workspace = "5",
		gaps_in = 0,
		gaps_out = 0,
		no_rounding = true,
		no_shadow = true,
		decorate = false,
	})

	hl.layer_rule({ name = "submap-cheatsheet-blur", match = { namespace = "submap-cheatsheet" }, blur = true })

	-- ============================================================
	-- WINDOW RULES
	-- ============================================================
	local function tag(match, tags)
		for _, name in ipairs(tags) do
			hl.window_rule({ match = match, tag = "+" .. name })
		end
	end

	-- Marked-window border (set/cleared by mark_or_swap in helpers.lua).
	hl.window_rule({
		match = { tag = "marked" },
		border_size = 12,
		rounding = 0,
		border_color = rgb(C.base09) .. " " .. rgb(C.base09),
	})

	-- ============================================================
	-- IDENTITY TAGS
	-- ============================================================
	tag({ class = terminalClass }, { "terminal" })
	tag({ class = devTagClass }, { "dev" })
	tag({ class = browserClass }, { "browser", "no-client-fullscreen" })
	tag({ class = chatClass }, { "chat", "privacy" })
	tag({ class = utilityClass }, { "utility" })
	tag({ class = "mpv" }, { "media", "low-latency" })
	tag({ class = "(org.keepassxc.KeePassXC|bitwarden)" }, { "privacy" })
	tag({ class = "(chromium-browser|vivaldi-stable)", title = ".*Private Browsing" }, { "privacy" })
	tag({ class = "org.qutebrowser.qutebrowser", title = ".*Private.*" }, { "privacy" })
	tag({ class = "com.obsproject.Studio" }, { "privacy" })
	tag({ title = "(Picture-in-Picture|Picture in picture)" }, { "media", "pip", "no-focus-steal" })
	tag({ title = "(Open|Save|Save As|Open File|Choose File|Preferences|Settings)" }, { "dialog", "file-picker" })
	tag({
		class = "xdg-desktop-portal-gtk",
		title = "(Open|Save|Save As|Open File|Choose File)",
	}, { "dialog", "file-picker" })
	tag({
		class = "(polkit-gnome-authentication-agent-1|xdg-desktop-portal-gtk|polkit-kde-authentication-agent-1)",
		title = "(Authenticate|Authentication Required|Authorization Required)",
	}, { "dialog", "auth-dialog" })
	tag({ initial_title = "(Splash|Loading|Updating|Splash Screen)" }, { "dialog", "transient", "no-focus-steal" })
	tag({ class = "steam", title = "Steam" }, { "steam-shell" })
	tag({ class = "steam", title = ".*Controller Layout$" }, { "dialog" })
	tag({ xdg_tag = "proton-game" }, { "game" })
	tag({ class = "^steam_app_[0-9]+$" }, { "game" })
	tag({ class = "^(Slay the Spire 2|Balatro)$" }, { "game", "no-client-fullscreen", "force-tile" })
	tag({ title = "^(Slay the Spire 2|Balatro)$" }, { "game", "no-client-fullscreen", "force-tile" })
	tag({ initial_title = "^(Slay the Spire 2|Balatro)$" }, { "no-client-fullscreen", "force-tile" })
	tag({ class = "^gamescope$" }, { "game", "gamescope" })
	tag({ class = "dropdown" }, { "scratchpad", "dropdown" })
	tag({ class = "floating-editor" }, { "scratchpad", "floating-editor" })
	tag({ class = "com.gabm.satty" }, { "dialog" })
	tag({ title = "Sign in - Google Accounts.*" }, { "dialog", "large-dialog" })
	tag({ class = "(valent|Valent)" }, { "dialog", "phone" })

	-- ============================================================
	-- POLICY RULES
	-- ============================================================
	hl.window_rule({ match = { float = true }, max_size = "1900 1240" })
	hl.window_rule({ suppress_event = "maximize" })
	hl.window_rule({
		match = { tag = "privacy" },
		no_screen_share = true,
	})
	hl.window_rule({
		match = { tag = "no-client-fullscreen" },
		-- Client fullscreen requests should not become compositor fullscreen.
		-- Manual Hyprland fullscreen via binds still works.
		suppress_event = "fullscreen fullscreenoutput maximize",
	})
	hl.window_rule({
		match = { tag = "dialog" },
		float = true,
		center = true,
	})
	hl.window_rule({
		match = { tag = "file-picker" },
		float = true,
		center = true,
		stay_focused = true,
		size = "monitor_h*1.1 monitor_h*0.62",
		animation = "none",
	})
	hl.window_rule({
		match = { tag = "auth-dialog" },
		stay_focused = true,
		pin = true,
	})
	hl.window_rule({
		match = { tag = "no-focus-steal" },
		no_initial_focus = true,
		suppress_event = "activatefocus",
	})
	hl.window_rule({
		match = { tag = "transient" },
		suppress_event = "activate activatefocus",
	})
	hl.window_rule({ match = { tag = "chat" }, tile = true })
	hl.window_rule({ match = { tag = "chat" }, workspace = "special:discord silent" })
	hl.window_rule({
		match = { tag = "utility" },
		float = true,
		size = "monitor_h*0.5 monitor_h*0.75",
		move = "monitor_w-window_w-(monitor_h*0.04) (monitor_h-window_h)/2",
	})
	hl.window_rule({
		match = { tag = "pip" },
		float = true,
		pin = true,
		size = "monitor_h*0.889 monitor_h*0.5",
		move = "monitor_w-monitor_h*0.889-(monitor_w*0.03) monitor_h*0.05",
	})
	hl.window_rule({
		match = { tag = "media" },
		content = "video",
		idle_inhibit = "always",
		border_size = 0,
		no_dim = true,
	})
	hl.window_rule({
		match = { tag = "low-latency" },
		immediate = true,
	})
	hl.window_rule({
		match = { tag = "browser" },
		opacity = "1.0 1.0",
	})
	hl.window_rule({
		match = { tag = "game" },
		content = "game",
		decorate = false,
		no_shadow = true,
		rounding = 0,
		border_size = 0,
		idle_inhibit = "always",
		no_dim = true,
		immediate = true,
		workspace = "5",
	})
	hl.window_rule({
		match = { tag = "force-tile" },
		tile = true,
	})
	hl.window_rule({
		match = { tag = "steam-shell" },
		workspace = "special:steam silent",
	})
	hl.window_rule({
		match = { tag = "gamescope" },
		fullscreen = true,
		workspace = "5 silent",
	})
	hl.window_rule({ match = { class = "steam", initial_title = "Steam Big Picture Mode" }, fullscreen_state = "2 2" })
	hl.window_rule({ match = { initial_title = "World of Warcraft" }, suppress_event = "fullscreen", fullscreen = true })
	hl.window_rule({ match = { class = "tidal-hifi" }, workspace = "8 silent" })
	hl.window_rule({ match = { class = "explorer.exe" }, workspace = "special:minimized silent" })
	hl.window_rule({ match = { class = "battle.net.exe" }, max_size = "2000 1200", float = true, center = true })
	hl.window_rule({
		match = { tag = "dropdown" },
		float = true,
		size = "monitor_h*1.4 monitor_h*0.5",
		move = "(monitor_w-window_w)/2 0",
		animation = "slide",
		rounding = 0,
		no_shadow = true,
	})
	hl.window_rule({
		match = { tag = "floating-editor" },
		float = true,
		center = true,
		size = "monitor_w*0.55 monitor_h*0.7",
	})
	hl.window_rule({ match = { class = "com.gabm.satty" }, max_size = "1400 900" })
	hl.window_rule({ match = { tag = "large-dialog" }, size = "1050 950" })
	hl.window_rule({ match = { tag = "phone" }, size = "monitor_w*0.4 monitor_h*0.6" })
	hl.window_rule({
		match = { initial_title = "pinned" },
		float = true,
		pin = true,
		size = "monitor_w*0.22 monitor_h*0.28",
		move = "monitor_w-window_w-(monitor_w*0.03) monitor_h-window_h-(monitor_h*0.06)",
	})

	-- Keep special:steam dedicated to the launcher. Steam-app windows and
	-- manual strays fall back to the last regular workspace, usually games.
	local function evict_if_intruder(win)
		if not win then
			return
		end
		local ws = win.workspace and win.workspace.name
		if ws ~= "special:steam" then
			return
		end
		if win.class == "steam" then
			return
		end
		-- Avoid bouncing the window back into special:steam if the user just
		-- toggled in (last workspace would itself be special:steam).
		local prev = hl.get_last_workspace()
		local target = prev and prev.name or "1"
		if target == "special:steam" or (target and target:match("^special:")) then
			target = "5"
		end
		hl.dispatch(hl.dsp.window.move({ workspace = target, window = win }))
	end
	hl.on("window.open_early", function(w)
		evict_if_intruder(w)
	end)
	hl.on("window.move_to_workspace", function(w)
		evict_if_intruder(w)
	end)

	-- Pinned border highlight
	hl.window_rule({
		match = { pin = true },
		border_color = { colors = { rgb(C.base09), rgb(C.base0A) }, angle = 45 },
	})

	-- Borders
	hl.window_rule({ match = { float = true }, border_size = 6 })
	hl.window_rule({ match = { tag = "fake-fullscreen-borderless" }, border_size = 0 })
	for _, w in ipairs({ "w[tv1]", "f[1]" }) do
		hl.window_rule({ match = { float = false, workspace = w }, border_size = 0, rounding = 0 })
	end

	-- ============================================================
	-- SUNSHINE STREAM ROUTING
	-- ============================================================
	local function window_selector(window)
		if not window or not window.address then
			return nil
		end
		return "address:" .. tostring(window.address)
	end

	local function window_workspace(window)
		return window and window.workspace and window.workspace.name or nil
	end

	local function stream_monitor_active()
		if not sunshine.enable then
			return false
		end
		for _, monitor in ipairs(hl.get_monitors() or {}) do
			if monitor.name == streamMonitor then
				return true
			end
		end
		return false
	end

	local function is_steam_window(window)
		return window and window.class == "steam"
	end

	local function is_game_window(window)
		if not window then
			return false
		end
		local class = window.class or ""
		local title = window.title or ""
		local initial_title = window.initial_title or ""
		return class:match("^steam_app_[0-9]+$")
			or class == "gamescope"
			or class == "Slay the Spire 2"
			or class == "Balatro"
			or title == "Slay the Spire 2"
			or title == "Balatro"
			or initial_title == "Slay the Spire 2"
			or initial_title == "Balatro"
			or initial_title == "World of Warcraft"
	end

	local function move_window(window, workspace)
		local selector = window_selector(window)
		if not selector or window_workspace(window) == workspace then
			return
		end
		hl.dispatch(hl.dsp.window.move({ workspace = workspace, silent = true, window = selector }))
	end

	local function reconcile_stream_windows()
		if not sunshine.enable then
			return
		end

		local active = stream_monitor_active()
		if active then
			hl.dispatch(hl.dsp.workspace.move({ workspace = streamSteamWorkspace, monitor = streamMonitor }))
			hl.dispatch(hl.dsp.workspace.move({ workspace = streamGameWorkspace, monitor = streamMonitor }))
		end

		for _, window in ipairs(hl.get_windows() or {}) do
			local ws = window_workspace(window)
			if active then
				if is_game_window(window) then
					move_window(window, streamGameWorkspace)
				elseif is_steam_window(window) then
					move_window(window, streamSteamWorkspace)
				end
			else
				if ws == streamGameWorkspace then
					move_window(window, "5")
				elseif ws == streamSteamWorkspace and is_steam_window(window) then
					move_window(window, "special:steam")
				elseif ws == streamSteamWorkspace then
					move_window(window, "5")
				end
			end
		end
	end

	if sunshine.enable then
		hl.on("hyprland.start", reconcile_stream_windows)
		hl.on("monitor.added", reconcile_stream_windows)
		hl.on("monitor.removed", reconcile_stream_windows)
		hl.on("window.open_early", function()
			reconcile_stream_windows()
		end)
		hl.on("window.move_to_workspace", function()
			reconcile_stream_windows()
		end)
	end

	-- ============================================================
	-- AUTOSTART
	-- ============================================================
	if hasHaPresence then
		hl.on("hyprland.start", function()
			hl.exec_cmd("ha-presence-discover")
			hl.exec_cmd("ha-presence-update active")
		end)
	end

	hl.on("hyprland.start", function()
		local autostart = {
			{ cmd = cfg.noctalia },
			{ cmd = cfg.submapCheatsheet },
			{ cmd = "wayscriber -d --no-tray" },

			{ cmd = cfg.browser, ws = "2 silent" },
			{ cmd = cfg.passManager, ws = "6 silent" },
			{ cmd = "qutebrowser", ws = "1 silent", when = hasBloat },
			{ cmd = cfg.terminalCommands.main, ws = "1 silent" },
			{ cmd = cfg.terminalCommands.dropdown, ws = "special:dropdown silent" },

			{ cmd = "steam", ws = "special:steam silent", when = hasGaming },
			{ cmd = "discord", ws = "special:discord silent", when = hasBloat },
			{ cmd = "tidal-hifi", ws = "8 silent", when = hasBloat },
			{ cmd = "keymapp", ws = "9 silent", when = hasZsa },
		}
		for _, e in ipairs(autostart) do
			if e.when ~= false then
				if e.ws then
					hl.exec_cmd(e.cmd, { workspace = e.ws })
				else
					hl.exec_cmd(e.cmd)
				end
			end
		end
	end)
end

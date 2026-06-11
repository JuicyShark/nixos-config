-- ============================================================
-- WORKSPACE / LAYER RULES
-- ============================================================
return function(ctx)
	local hl = ctx.hl
	local primary = ctx.desktop.primary
	local monitorWorkspace = ctx.desktop.monitorWorkspace or {}

	local externalWorkspaceSet = {}

	local workspaceRules = {
		{ workspace = "1", layout = "master", layout_opts = { orientation = "left" } },
		{ workspace = "2", default = true, layout = "master", layout_opts = { orientation = "center" } },
		{ workspace = "3", layout = "scrolling" },
		{ workspace = "4", layout = "dwindle", gaps_in = 0, gaps_out = 0, no_rounding = true, decorate = true },
		{
			workspace = "5",
			layout = "dwindle",
			gaps_in = 0,
			gaps_out = 0,
			no_rounding = true,
			no_shadow = true,
			decorate = false,
		},
	}

	local gameClass = "^(steam_app_[0-9]+|gamescope|FTL\\.amd64|Slay the Spire 2|Balatro)$"
	local gameTitle = "^(World of Warcraft|Slay the Spire 2|Balatro)$"
	local attentionTitle =
		"(Authenticate|Authentication Required|Authorization Required|Confirm|Confirmation|Are you sure.*|Password Required|Unlock.*|Enter Password.*)"
	local mediaInspectorTitle = "(Media viewer|Image Viewer|Screenshot|Drag and Drop)"

	local identityTags = {
		{
			--browser classes
			match = {
				class = "(org.qutebrowser.qutebrowser|chromium-browser|Chromium|google-chrome|Google-chrome|chrome|vivaldi-stable|Vivaldi-stable|firefox|firefox-esr|librewolf|brave-browser|Brave-browser|microsoft-edge|Microsoft-edge)",
			},
			tags = { "no-client-fullscreen" },
		},
		--chat classes
		{
			match = { class = "(discord|vesktop|signal|org.telegram.desktop)" },
			tags = { "chat" },
		},
		{
			--utility apps
			match = {
				class = "(thunar|com.saivert.pwvucontrol|RimPy|org.keepassxc.KeePassXC|bitwarden|Tk|nm-connection-editor|blueman-manager)",
			},
			tags = { "utility" },
		},
		{ match = { class = "mpv" }, tags = { "media", "low-latency" } },
		{ match = { class = "(org.keepassxc.KeePassXC|bitwarden)" }, tags = { "privacy" } },
		{ match = { class = "(chromium-browser|vivaldi-stable)", title = ".*Private Browsing" }, tags = { "privacy" } },
		{ match = { class = "org.qutebrowser.qutebrowser", title = ".*Private.*" }, tags = { "privacy" } },
		{ match = { class = "com.obsproject.Studio" }, tags = { "privacy" } },
		{ match = { title = "(Picture-in-Picture|Picture in picture)" }, tags = { "media", "pip", "no-focus-steal" } },
		{
			match = { title = "(Open|Save|Save As|Open File|Choose File|Preferences|Settings|Open Files" },
			tags = { "dialog", "file-picker" },
		},
		{
			match = { class = "xdg-desktop-portal-gtk", title = "(Open|Save|Save As|Open File|Choose File)" },
			tags = { "dialog", "file-picker" },
		},
		{ match = { class = "file_chooser" }, tags = { "dialog", "file-picker" } },
		{
			match = {
				class = "(polkit-gnome-authentication-agent-1|xdg-desktop-portal-gtk|polkit-kde-authentication-agent-1)",
				title = "(Authenticate|Authentication Required|Authorization Required)",
			},
			tags = { "dialog", "attention" },
		},
		{ match = { modal = true }, tags = { "dialog", "attention" } },
		{
			match = { class = "(pinentry.*|gcr-prompter|org.gnome.keyring.SystemPrompter)" },
			tags = { "dialog", "attention" },
		},
		{ match = { title = attentionTitle }, tags = { "dialog", "attention" } },
		{
			match = { initial_title = "(Splash|Loading|Updating|Splash Screen)" },
			tags = { "dialog", "transient", "no-focus-steal" },
		},
		{ match = { class = "steam", title = "Steam" }, tags = { "steam-shell" } },
		{ match = { class = "steam", title = ".*Controller Layout$" }, tags = { "dialog" } },
		{ match = { xdg_tag = "proton-game" }, tags = { "game" } },
		{ match = { class = gameClass }, tags = { "game" } },
		{ match = { title = gameTitle }, tags = { "game", "no-client-fullscreen", "force-tile" } },
		{ match = { initial_title = gameTitle }, tags = { "game", "no-client-fullscreen", "force-tile" } },
		{ match = { class = "^gamescope$" }, tags = { "gamescope" } },
		{ match = { class = "dropdown" }, tags = { "dropdown" } },
		{ match = { class = "floating-editor" }, tags = { "floating-editor" } },
		{ match = { class = "com.gabm.satty" }, tags = { "dialog", "media-inspector" } },
		{ match = { class = "org.telegram.desktop", title = mediaInspectorTitle }, tags = { "media-inspector" } },
		{ match = { title = mediaInspectorTitle }, tags = { "media-inspector" } },
		{ match = { title = "Sign in - Google Accounts.*" }, tags = { "dialog", "attention" } },
		{ match = { class = "(valent|Valent)" }, tags = { "dialog", "phone" } },
	}

	local appWindowRules = {
		{ match = { class = "steam", initial_title = "Steam Big Picture Mode" }, fullscreen_state = "2 2" },
		{ match = { initial_title = "World of Warcraft" }, suppress_event = "fullscreen", fullscreen = true },
		{ match = { class = "tidal-hifi" }, workspace = "8 silent" },
		{ match = { class = "explorer.exe" }, workspace = "special:minimized silent" },
		{ match = { class = "battle.net.exe" }, max_size = "2000 1200", float = true, center = true },
		{ match = { class = "com.gabm.satty" }, max_size = "1400 900" },
		{ match = { tag = "phone" }, size = "monitor_w*0.4 monitor_h*0.6" },
	}

	for _, ws in ipairs(monitorWorkspace.workspaces or {}) do
		externalWorkspaceSet[ws] = true
	end

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
		"10",
		"special:minimized",
		"special:dropdown",
		"special:steam",
		"special:discord",
	}) do
		if not externalWorkspaceSet[ws] then
			hl.workspace_rule({ workspace = ws, monitor = primary.selector })
		end
	end
	for _, rule in ipairs(workspaceRules) do
		hl.workspace_rule(rule)
	end

	hl.layer_rule({ name = "submap-cheatsheet-blur", match = { namespace = "submap-cheatsheet" }, blur = true })

	-- ============================================================
	-- WINDOW RULES
	-- ============================================================
	local function tag(match, tags)
		for _, name in ipairs(tags) do
			hl.window_rule({ match = match, tag = "+" .. name })
		end
	end

	-- ============================================================
	-- IDENTITY TAGS
	-- ============================================================
	for _, entry in ipairs(identityTags) do
		tag(entry.match, entry.tags)
	end

	-- ============================================================
	-- POLICY RULES
	-- ============================================================
	hl.window_rule({ match = { float = true }, max_size = "1900 1240" })
	hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })
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
		match = { tag = "attention" },
		float = true,
		center = true,
		stay_focused = true,
		dim_around = true,
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
		no_initial_focus = true,
		focus_on_activate = false,
		suppress_event = "activatefocus fullscreen",
		opacity = "1.0 1.0",
		size = "monitor_h*0.889 monitor_h*0.5",
		move = "monitor_w-monitor_h*0.889-(monitor_w*0.03) monitor_h*0.05",
	})
	hl.window_rule({
		match = { tag = "media-inspector" },
		float = true,
		center = true,
		content = "photo",
		idle_inhibit = "focus",
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
	for _, rule in ipairs(appWindowRules) do
		hl.window_rule(rule)
	end
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
	hl.window_rule({
		match = { initial_title = "pinned" },
		float = true,
		pin = true,
		size = "monitor_w*0.22 monitor_h*0.28",
		move = "monitor_w-window_w-(monitor_w*0.03) monitor_h-window_h-(monitor_h*0.06)",
	})

	-- Borders
	hl.window_rule({ match = { float = true }, border_size = 6 })
	hl.window_rule({ match = { tag = "fake-fullscreen-borderless" }, border_size = 0 })
	for _, w in ipairs({ "w[tv1]", "f[1]" }) do
		hl.window_rule({ match = { float = false, workspace = w }, border_size = 0, rounding = 0 })
	end
end

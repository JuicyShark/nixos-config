-- ============================================================
-- MONITOR
-- ============================================================
return function(ctx)
	local hl = ctx.hl
	local cfg = ctx.cfg
	local C = cfg.colors
	local mod = "SUPER"

	local function rgb(color)
		return "rgb(" .. color .. ")"
	end

	-- Match by EDID description when provided so cable port swaps don't break the bind;
	-- otherwise fall back to the named output.
	hl.monitor({
		output = cfg.primary.selector,
		mode = "preferred",
		position = "0x0",
		scale = 1,
		--	supports_wide_color = cfg.primary.wideColor,
	})
	hl.monitor({
		output = "HDMI-A-2",
		mode = "preferred",
		position = "auto-center-right",
		scale = 1,
		--	supports_wide_color = cfg.primary.wideColor,
	})
	if cfg.sunshine and cfg.sunshine.enable then
		hl.monitor({
			output = cfg.sunshine.virtualMonitor,
			disabled = true,
		})
	end

	-- ============================================================
	-- LOOK & FEEL
	-- ============================================================
	hl.config({
		cursor = {
			default_monitor = cfg.primary.selector,
			inactive_timeout = 10,
			enable_hyprcursor = true,
			no_hardware_cursors = false,
			no_break_fs_vrr = 2,
		},

		general = {
			gaps_in = cfg.theme.gaps_in,
			gaps_out = cfg.theme.gaps_out,
			border_size = 4,
			col = {
				active_border = { colors = { rgb(C.base0D), rgb(C.base0E) }, angle = 45 },
				inactive_border = rgb(C.base02),
			},
			resize_on_border = true,
			extend_border_grab_area = 3,
			layout = "master",
			allow_tearing = true,
			snap = { enabled = true, window_gap = 15, monitor_gap = 10, border_overlap = false, respect_gaps = true },
		},

		decoration = {
			rounding = cfg.theme.rounding,
			rounding_power = 1.0,
			dim_inactive = false,
			dim_strength = 0.18,
			dim_special = 0.25,
			shadow = { enabled = true, range = 30, render_power = 3, color = "rgba(0A1F0E88)" },
			blur = { enabled = true, size = 5, passes = 2 },
		},

		group = {
			merge_groups_on_drag = false,
			merge_groups_on_groupbar = true,
			drag_into_group = 2,
			col = {
				border_active = { colors = { rgb(C.base0C), rgb(C.base0E) }, angle = 45 },
				border_inactive = rgb(C.base01),
			},
			groupbar = {
				enabled = true,
				indicator_height = 0,
				font_size = 17,
				font_weight_active = "heavy",
				height = 32,
				text_offset = -3,
				text_padding = 3,
				text_color = "0xFF" .. C.base07,
				text_color_inactive = "0xFF" .. C.base04,
				col = {
					active = { colors = { rgb(C.base0C), rgb(C.base02) }, angle = 45 },
					inactive = rgb(C.base01),
				},
				rounding_power = 1.0,
				gradients = true,
				gradient_rounding = 16,
				gaps_out = 0,
				gaps_in = 4,
				keep_upper_gap = false,
				blur = false,
			},
		},

		xwayland = { enabled = true, create_abstract_socket = true, force_zero_scaling = true },
		render = { direct_scanout = 2, cm_enabled = true },

		dwindle = {
			preserve_split = true,
			default_split_ratio = 1.0,
			split_width_multiplier = 1.25,
			special_scale_factor = 0.7,
		},

		master = {
			mfact = 0.45,
			special_scale_factor = 0.8,
			allow_small_split = false,
			new_status = "slave",
			new_on_top = false,
			orientation = "center",
			center_ignores_reserved = true,
			slave_count_for_center_master = 0,
			center_master_fallback = "right",
			always_keep_position = true,
		},

		scrolling = {
			fullscreen_on_one_column = false,
			column_width = 0.25,
			focus_fit_method = 1,
			follow_focus = false,
			follow_min_visible = 0,
			explicit_column_widths = "0.28,0.36,0.42,0.50,0.66,1.0",
			direction = "right",
		},

		binds = { allow_workspace_cycles = false, workspace_back_and_forth = false },

		misc = {
			disable_hyprland_logo = true,
			focus_on_activate = true,
			animate_manual_resizes = true,
			animate_mouse_windowdragging = true,
			disable_autoreload = true,
			initial_workspace_tracking = 0,
			font_family = "IosevkaTerm Nerd Font",
			enable_swallow = true,
			swallow_regex = "^(com.mitchellh.ghostty|kitty)$",
			session_lock_xray = true,
			vrr = 2,
			size_limits_tiled = true,
			mouse_move_enables_dpms = false,
		},

		ecosystem = { no_update_news = true, no_donation_nag = true },
		animations = { enabled = true, workspace_wraparound = true },

		input = {
			kb_layout = "us",
			repeat_rate = 50,
			repeat_delay = 300,
			accel_profile = "flat",
			follow_mouse = 1,
			sensitivity = -0.3,
			mouse_refocus = false,
		},

		gestures = { workspace_swipe_distance = 650, workspace_swipe_cancel_ratio = 0.4 },
	})

	-- ---- animation curves & leaves ----
	hl.curve("ease_snap", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.0 } } })
	hl.curve("ease_quick", { type = "bezier", points = { { 0.16, 1.0 }, { 0.3, 1.0 } } })
	hl.curve("spring_snappy", { type = "spring", mass = 1, stiffness = 125, dampening = 18 })
	hl.curve("spring_window", { type = "spring", mass = 1, stiffness = 95, dampening = 15 })
	hl.curve("spring_workspace", { type = "spring", mass = 1, stiffness = 80, dampening = 18 })
	hl.curve("spring_drawer", { type = "spring", mass = 1, stiffness = 90, dampening = 13 })

	for _, a in ipairs({
		{ leaf = "windows", speed = 5, spring = "spring_window", style = "slide" },
		{ leaf = "windowsIn", speed = 5, spring = "spring_window", style = "popin 88%" },
		{ leaf = "windowsMove", speed = 4, spring = "spring_snappy" },
		{ leaf = "windowsOut", speed = 4, bezier = "ease_quick", style = "popin 82%" },
		{ leaf = "layersIn", speed = 5, spring = "spring_drawer", style = "slide" },
		{ leaf = "layersOut", speed = 4, bezier = "ease_quick", style = "slide" },
		{ leaf = "border", speed = 8, bezier = "ease_snap" },
		{ leaf = "borderangle", speed = 25, bezier = "ease_snap", style = "once" },
		{ leaf = "fade", speed = 4, bezier = "ease_quick" },
		{ leaf = "fadePopups", speed = 3, bezier = "ease_quick" },
		{ leaf = "fadeLayers", speed = 3, bezier = "ease_quick" },
		{ leaf = "workspaces", speed = 6, spring = "spring_workspace", style = "slidefade 18%" },
		{ leaf = "specialWorkspace", speed = 5, spring = "spring_drawer", style = "slidefadevert 22%" },
	}) do
		local animation = { leaf = a.leaf, enabled = true, speed = a.speed, style = a.style }
		if a.spring then
			animation.spring = a.spring
		else
			animation.bezier = a.bezier
		end
		hl.animation(animation)
	end

	-- ============================================================
	-- GESTURES
	-- ============================================================
	hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
	hl.gesture({ fingers = 2, direction = "pinchin", action = "float", mods = mod, arg = "tile" })
	hl.gesture({ fingers = 2, direction = "pinchout", action = "float", mods = mod })
	hl.gesture({ fingers = 3, direction = "up", action = "fullscreen" })
end

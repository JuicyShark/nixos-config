local state_path =
	assert(arg[1], "usage: runtime-helpers.lua <state-module> <dispatch-module> <terminal-module> <feedback-module>")
local dispatch_path = assert(arg[2], "dispatch module is required")
local terminal_path = assert(arg[3], "terminal module is required")
local feedback_path = assert(arg[4], "feedback module is required")
local load_state = assert(loadfile(state_path))
local load_dispatch = assert(loadfile(dispatch_path))
local load_terminal = assert(loadfile(terminal_path))

local state_commands = {}
load_state()({
	hl = {
		exec_cmd = function(command)
			state_commands[#state_commands + 1] = command
		end,
	},
}, {
	states = { "gaming", "remote-streaming" },
	sourceCommand = "/bin/ha-presence source",
})

assert(#state_commands == 0, "initial local state must not invent external facts")
assert(not pcall(Juicy.state.set, "idle", true), "idle must not be a published Hyprland state")
assert(not pcall(Juicy.state.set, "double", true), "monitor count must not be a published Hyprland state")
assert(Juicy.state.setSource("games", "gaming", true) == "gaming")
assert(state_commands[1] == "/bin/ha-presence source 'games' 'gaming' true")

Juicy.state.setSource("games", "gaming", false)
assert(state_commands[#state_commands] == "/bin/ha-presence source 'games' 'gaming' false")

assert(Juicy.state.setSource("stream", "remote-streaming", true) == "remote-streaming")
assert(state_commands[#state_commands] == "/bin/ha-presence source 'stream' 'remote-streaming' true")
local command_count = #state_commands
assert(Juicy.state.setSource("stream", "remote-streaming", true) == "remote-streaming")
assert(#state_commands == command_count, "idempotent state updates must not emit duplicate facts")
Juicy.state.set("remote-streaming", true)
assert(state_commands[#state_commands] == "/bin/ha-presence source 'hyprland-manual' 'remote-streaming' true")

local failed_attempts = 0
load_state()({
	hl = {
		exec_cmd = function()
			failed_attempts = failed_attempts + 1
			if failed_attempts == 1 then
				return { ok = false, error = "exec failed" }
			end
		end,
	},
}, { states = { "gaming" }, sourceCommand = "/bin/ha-presence source" })
assert(not pcall(Juicy.state.setSource, "games", "gaming", true))
Juicy.state.setSource("games", "gaming", true)
assert(failed_attempts == 2, "failed source-command launches must not suppress the next attempt")

local reload_commands = {}
load_state()({
	hl = {
		exec_cmd = function(command)
			reload_commands[#reload_commands + 1] = command
		end,
	},
}, {
	states = { "remote-streaming" },
	sourceCommand = "/bin/ha-presence source",
})
Juicy.state.set("remote-streaming", false)
assert(
	reload_commands[1] == "/bin/ha-presence source 'hyprland-manual' 'remote-streaming' false",
	"a post-reload false event must clear a persisted external fact"
)

local matched_windows = {
	{ address = "hidden-recent", mapped = true, hidden = true, focus_history_id = 0 },
	{ address = "visible-old", mapped = true, hidden = false, focus_history_id = 8 },
	{ address = "visible-recent", mapped = true, hidden = false, focus_history_id = 2 },
}
local focused_window = nil
local spawned = {}
local timers, events, notices, actions = {}, {}, {}, {}
local active_window
local dispatch_hl = {
	on = function(name, callback)
		events[name] = callback
	end,
	timer = function(callback)
		timers[#timers + 1] = callback
	end,
	get_active_window = function()
		return active_window
	end,
	dsp = {
		submap = function(name)
			return { kind = "submap", name = name }
		end,
		window = {},
		focus = function(spec)
			return { kind = "focus", window = spec.window }
		end,
	},
	get_windows = function()
		return matched_windows
	end,
	dispatch = function(action)
		actions[#actions + 1] = action
		focused_window = action.window
	end,
	exec_cmd = function(command)
		spawned[#spawned + 1] = command
	end,
}
load_dispatch()(
	{ hl = dispatch_hl, feedback = {
		notify = function(_, body)
			notices[#notices + 1] = body
		end,
	} },
	{ monocleMonitor = "HDMI-A-2" }
)

local focus_or_spawn = Juicy.dispatch.focusOrSpawn({ class = "^steam$" }, "steam")
focus_or_spawn()
assert(focused_window.address == "visible-recent", "focus-or-spawn must prefer the recent usable window")
matched_windows[1].active = true
focus_or_spawn()
assert(focused_window.address == "hidden-recent", "the already-active match must win")
matched_windows = {}
focus_or_spawn()
assert(spawned[#spawned] == "steam", "focus-or-spawn must launch only when no match exists")
focus_or_spawn()
Juicy.dispatch.focusOrSpawn({}, "steam")()
assert(#spawned == 1, "repeated launch actions and aliases must share launch suppression")
timers[#timers]()
focus_or_spawn()
assert(#spawned == 2, "failed or slow launches must be retryable after the grace period")
matched_windows = { { address = "unmapped", mapped = false, active = true } }
timers[#timers]()
focus_or_spawn()
assert(#spawned == 3, "an unmapped match must not consume the launcher action")
matched_windows = { { address = "grouped", mapped = true, hidden = true } }
focus_or_spawn()
assert(focused_window.address == "grouped", "mapped hidden windows must reach native focus for reveal")
matched_windows = {}
local original_exec = dispatch_hl.exec_cmd
dispatch_hl.exec_cmd = function()
	return { ok = false, error = "launch failed" }
end
assert(not pcall(focus_or_spawn))
dispatch_hl.exec_cmd = original_exec
focus_or_spawn()
assert(#spawned == 4, "a rejected launch must be immediately retryable")

Juicy.dispatch.bind(function()
	error("deliberate failure")
end, { reset = "reset" })()
assert(actions[#actions].kind == "submap" and #notices == 1, "failure must report and reset the submap")
Juicy.dispatch.bind(function()
	return { ok = false, error = "dispatcher failure" }
end, { reset = "reset" })()
assert(notices[#notices] == "dispatcher failure", "structured dispatcher errors must also be reported")
assert(Juicy.dispatch.bind(function()
	return { ok = true, pass_event = true }
end)().pass_event)
dispatch_hl.get_active_special_workspace = function()
	return nil
end
dispatch_hl.get_active_workspace = function()
	return { tiled_layout = "dwindle" }
end
Juicy.dispatch.layout({
	master = function()
		error("wrong layout called")
	end,
}, { reset = "reset" })()
assert(notices[#notices]:find("dwindle"), "unsupported layout actions must explain the no-op")

local layout_workspace = { id = 42, name = "42", monitor = { name = "DP-2" } }
local layout_rules = {}
dispatch_hl.get_active_workspace = function()
	return layout_workspace
end
dispatch_hl.workspace_rule = function(rule)
	layout_rules[#layout_rules + 1] = rule
end
Juicy.layout.setCurrentLayout("master")
assert(layout_rules[1].workspace == "42" and layout_rules[1].layout == "master")
assert(
	layout_rules[2].workspace == "r[42-42] m[HDMI-A-2]" and layout_rules[2].layout == "monocle",
	"new workspace selections need a later HDMI override for monitor moves"
)
layout_workspace.monitor.name = "HDMI-A-2"
local layout_rule_count = #layout_rules
Juicy.dispatch.bind(function()
	Juicy.layout.setCurrentLayout("scrolling")
end, { reset = "reset" })()
assert(notices[#notices]:find("always uses monocle"))
assert(actions[#actions].kind == "submap", "HDMI layout rejection must exit the submap")
Juicy.layout.setCurrentLayout("monocle")
assert(#layout_rules == layout_rule_count, "HDMI selection must not overwrite the desktop layout")
layout_workspace.monitor.name = "DP-2"
Juicy.layout.setCurrentLayout("monocle")
assert(layout_rules[#layout_rules - 1].layout == "monocle", "other outputs can select monocle")
layout_workspace.id, layout_workspace.name = -1337, "project"
Juicy.layout.setCurrentLayout("dwindle")
assert(
	layout_rules[#layout_rules].workspace == "n[s:project] m[HDMI-A-2]",
	"named workspaces also need HDMI protection"
)
layout_workspace.tiled_layout = "monocle"
local cycled = false
Juicy.dispatch.layout({
	monocle = function()
		cycled = true
	end,
})()
assert(cycled, "monocle actions must route through the layout dispatcher")

for _, kind in ipairs({ "float", "pin", "resize", "move" }) do
	dispatch_hl.dsp.window[kind] = function(spec)
		spec.kind = kind
		return spec
	end
end
active_window = {
	stable_id = "pip-one",
	floating = true,
	pinned = false,
	at = { x = 40, y = 60 },
	size = { x = 800, y = 600 },
	monitor = { name = "DP-2" },
}
Juicy.dispatch.togglePip()
active_window.at.x = 400
active_window.size.x = 300
Juicy.dispatch.togglePip()
assert(actions[#actions].kind == "move" and actions[#actions].x == 40)
assert(actions[#actions - 1].kind == "resize" and actions[#actions - 1].x == 800)
assert(
	actions[#actions - 2].kind == "float" and actions[#actions - 2].action == "enable",
	"leaving PiP must preserve a previously floating window"
)
active_window.floating = false
Juicy.dispatch.togglePip()
Juicy.dispatch.togglePip()
assert(actions[#actions].kind == "float" and actions[#actions].action == "disable")
active_window.floating = true
Juicy.dispatch.togglePip()
active_window.monitor.name = "HDMI-A-2"
Juicy.dispatch.togglePip()
assert(actions[#actions].kind == "float", "moving to another monitor must not restore old coordinates")
Juicy.dispatch.togglePip()
events["window.close"](active_window)
active_window.pinned = true
Juicy.dispatch.togglePip()
assert(
	actions[#actions].kind == "pin" and actions[#actions].action == "disable",
	"already-pinned windows without a snapshot must unpin without being tiled"
)
active_window.fullscreen = 2
local previous_actions = #actions
assert(not pcall(Juicy.dispatch.togglePip))
assert(#actions == previous_actions, "fullscreen PiP requests must not partially mutate the window")
active_window = nil
Juicy.dispatch.togglePip()
assert(#actions == previous_actions)

local notification_count, alive = 0, true
local feedback_ctx = {
	hl = {
		notification = {
			create = function()
				notification_count = notification_count + 1
				return {
					is_alive = function()
						return alive
					end,
				}
			end,
		},
	},
}
assert(loadfile(feedback_path))()(feedback_ctx)
feedback_ctx.feedback.notify("Layout", "Unavailable")
feedback_ctx.feedback.notify("Layout", "Unavailable")
assert(notification_count == 1, "repeated failures must not stack identical live notifications")
alive = false
feedback_ctx.feedback.notify("Layout", "Unavailable")
assert(notification_count == 2, "an expired notification must not suppress later feedback")

local terminal_actions = {}
local terminal_commands = {}
local terminal_window = {
	class = "com.mitchellh.ghostty",
	stable_id = "terminal-focused",
}
local terminal_hl = {
	dsp = {
		send_shortcut = function(spec)
			return { kind = "send-shortcut", spec = spec }
		end,
	},
	get_active_window = function()
		return terminal_window
	end,
	dispatch = function(action)
		terminal_actions[#terminal_actions + 1] = action
	end,
	exec_cmd = function(command)
		terminal_commands[#terminal_commands + 1] = command
	end,
}

load_terminal()({ hl = terminal_hl }, {
	fallback = "/bin/ghostty-launch",
	home = "/home/test user",
	workingDirectoryFlag = "--working-directory",
	inheritShortcut = { mods = "CTRL ALT", key = "Return" },
})

assert(Juicy.terminal.open())
assert(#terminal_actions == 1 and #terminal_commands == 0)
assert(terminal_actions[1].kind == "send-shortcut")
assert(terminal_actions[1].spec.mods == "CTRL ALT" and terminal_actions[1].spec.key == "Return")
assert(terminal_actions[1].spec.window == terminal_window, "inheritance must target the focused Ghostty surface")

terminal_window = { class = "firefox" }
assert(Juicy.terminal.open())
assert(#terminal_actions == 1 and #terminal_commands == 1)
assert(
	terminal_commands[1] == "/bin/ghostty-launch --working-directory='/home/test user'",
	"non-terminal launches must use the quoted home directory"
)

terminal_window = nil
assert(Juicy.terminal.open({ cwd = "/tmp/project with spaces", args = { "-e", "/bin/nvim" } }))
assert(#terminal_commands == 2)
assert(
	terminal_commands[2] == "/bin/ghostty-launch --working-directory='/tmp/project with spaces' '-e' '/bin/nvim'",
	"explicit terminal requests must preserve quoted cwd and arguments"
)

terminal_hl.exec_cmd = function()
	return { ok = false, error = "terminal launch rejected" }
end
assert(not pcall(Juicy.terminal.open), "terminal launch failures must reach the action error handler")
terminal_window = { class = "com.mitchellh.ghostty" }
terminal_hl.dispatch = function()
	return { ok = false, error = "shortcut rejected" }
end
assert(not pcall(Juicy.terminal.open), "a rejected inheritance shortcut must not report success")

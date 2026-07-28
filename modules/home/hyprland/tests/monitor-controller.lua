local policy_path = assert(arg[1], "usage: monitor-controller.lua <policy-module> <controller-module>")
local controller_path = assert(arg[2], "usage: monitor-controller.lua <policy-module> <controller-module>")
local load_policy = assert(loadfile(policy_path))
local load_controller = assert(loadfile(controller_path))

local outputs = {
	["DP-2"] = {
		name = "DP-2",
		width = 5120,
		height = 1440,
		refresh_rate = 120,
		scale = 1,
		x = 0,
		y = 0,
	},
	["HDMI-A-2"] = {
		name = "HDMI-A-2",
		width = 1920,
		height = 1080,
		refresh_rate = 60,
		scale = 1,
		x = 5120,
		y = 180,
	},
}
local events = {}
local timer = nil
local assignments = nil
local projected = {}

local function monitor_from_spec(spec)
	return {
		name = spec.output,
		width = 2560,
		height = 1440,
		refresh_rate = 120,
		scale = spec.scale or 1,
		x = 0,
		y = 0,
	}
end

local hl = {
	dsp = {
		focus = function(spec)
			return spec
		end,
	},
	get_active_workspace = function()
		return { name = "2" }
	end,
	get_monitor = function(selector)
		return outputs[selector]
	end,
	monitor = function(spec)
		if spec.disabled then
			outputs[spec.output] = nil
		else
			outputs[spec.output] = outputs[spec.output] or monitor_from_spec(spec)
		end
	end,
	exec_cmd = function(command)
		local created = command:match("output create headless ([^ ]+)$")
		if created then
			outputs[created] = monitor_from_spec({ output = created, scale = 1.67 })
			return
		end
		local removed = command:match("output remove ([^ ]+)$")
		if removed then
			outputs[removed] = nil
		end
	end,
	dispatch = function() end,
	on = function(name, callback)
		events[name] = callback
	end,
	timer = function(callback)
		timer = {
			callback = callback,
			enabled = true,
			set_timeout = function() end,
			set_enabled = function(self, enabled)
				self.enabled = enabled
			end,
		}
		return timer
	end,
}

local ctx = {
	hl = hl,
	monitorWorkspace = {
		apply = function(next_assignments)
			assignments = next_assignments
		end,
	},
	state = {
		setSource = function(_, name, enabled)
			projected[name] = enabled
		end,
	},
}
local desktop = {
	defaultProfile = "solo",
	primary = {
		output = "DP-2",
		selector = "DP-2",
		mode = "preferred",
		position = "0x0",
		scale = 1,
	},
	auxiliary = {
		output = "HDMI-A-2",
		selector = "HDMI-A-2",
		mode = "preferred",
		position = "auto-center-right",
		scale = 1,
	},
	monitorWorkspace = {
		target = "virtual-screen",
		workspaces = { "6", "7", "8", "9", "10" },
	},
	workspaceGroups = {
		external = { "6", "7", "8", "9", "10" },
		auxiliary = { "6", "7", "8" },
		stream = { "9", "10" },
	},
}
local stream = {
	monitor = "virtual-screen",
	position = "0x1440",
	width = 2560,
	height = 1440,
	refresh = 120,
	scale = 1.67,
}

load_policy()(ctx, {
	desktop = desktop,
	stream = stream,
})
load_controller()(ctx, {
	desktop = desktop,
	stream = stream,
	hyprctl = "hyprctl",
	debounceMs = 1,
	retryMs = 1,
	retryTicks = 1,
	maxAttempts = 1,
})

local function drain_timer()
	for _ = 1, 20 do
		if not (timer and timer.enabled) then
			return
		end
		timer.enabled = false
		timer.callback()
	end
	error("monitor controller did not settle")
end

events["hyprland.start"]()
drain_timer()
assert(outputs["DP-2"])
assert(not outputs["HDMI-A-2"])
assert(ctx.monitors.status().phase == "stable")

ctx.monitors.setProfile("extended")
drain_timer()
assert(outputs["HDMI-A-2"])
assert(assignments[1].monitor == "HDMI-A-2")
assert(projected.double)

ctx.monitors.setStream({
	kind = "local",
	width = 1920,
	height = 1080,
	refresh = 60,
	scale = 1,
})
drain_timer()
assert(outputs["virtual-screen"])
assert(#assignments == 2)
assert(assignments[2].monitor == "virtual-screen")
assert(projected.streaming)

ctx.monitors.setStream("remote")
drain_timer()
assert(not outputs["DP-2"])
assert(not outputs["HDMI-A-2"])
assert(outputs["virtual-screen"])
assert(assignments[1].monitor == "virtual-screen")
assert(projected["remote-streaming"])

ctx.monitors.setStream("off")
drain_timer()
assert(outputs["DP-2"])
assert(outputs["HDMI-A-2"])
assert(not outputs["virtual-screen"])
assert(not projected.streaming)
assert(not projected["remote-streaming"])

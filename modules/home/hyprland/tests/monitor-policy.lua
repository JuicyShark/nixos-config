local policy_path = assert(arg[1], "usage: monitor-policy.lua <policy-module>")
local load_policy = assert(loadfile(policy_path))
local ctx = {}

load_policy()(ctx, {
	desktop = {
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
	},
	stream = {
		monitor = "virtual-screen",
		position = "0x1440",
		width = 2560,
		height = 1440,
		refresh = 120,
		scale = 1.67,
	},
})

local function output(plan, name)
	for _, spec in ipairs(plan.outputs) do
		if spec.output == name then
			return spec
		end
	end
	error("missing output " .. name)
end

local solo = ctx.monitorPolicy.resolve({ profile = "solo", stream = "off" })
assert(output(solo, "DP-2").enabled)
assert(not output(solo, "HDMI-A-2").enabled)
assert(not output(solo, "virtual-screen").enabled)
assert(solo.workspaces[1].monitor == "DP-2")

local combined = ctx.monitorPolicy.resolve({ profile = "extended", stream = "local" })
assert(output(combined, "HDMI-A-2").enabled)
assert(output(combined, "virtual-screen").enabled)
assert(combined.workspaces[1].monitor == "HDMI-A-2")
assert(#combined.workspaces[1].workspaces == 3)
assert(combined.workspaces[2].monitor == "virtual-screen")
assert(#combined.workspaces[2].workspaces == 2)

local remote = ctx.monitorPolicy.resolve({ profile = "extended", stream = "remote" })
assert(not output(remote, "DP-2").enabled)
assert(not output(remote, "HDMI-A-2").enabled)
assert(output(remote, "virtual-screen").enabled)
assert(output(remote, "virtual-screen").position == "0x0")
assert(remote.workspaces[1].monitor == "virtual-screen")

local mirror = ctx.monitorPolicy.resolve({ profile = "mirror", stream = "off" })
assert(output(mirror, "HDMI-A-2").mirror == "DP-2")
assert(mirror.workspaces[1].monitor == "DP-2")

local degraded = ctx.monitorPolicy.resolve({ profile = "extended", stream = "off" }, {
	unavailable = { ["HDMI-A-2"] = true },
})
assert(degraded.status.effectiveProfile == "solo")
assert(degraded.status.degraded)
assert(degraded.workspaces[1].monitor == "DP-2")

local auto = ctx.monitorPolicy.resolve({ profile = "auto", stream = "off" }, {
	knownOutputs = { ["HDMI-A-2"] = true },
})
assert(auto.status.effectiveProfile == "extended")

local load_controller = assert(loadfile(assert(arg[1])))
local calls = {}
local ctx = {
	hl = {
		monitor = function(spec)
			calls[#calls + 1] = spec
		end,
	},
}
load_controller()(ctx, { mainOutput = "DP-2", tvOutput = "HDMI-A-2" })
assert(#calls == 0, "loading must not change displays or register automatic handlers")
for _, profile in ipairs({ "mirror", "extended", "solo" }) do
	ctx.monitors.setProfile(profile)
	local main, tv = calls[#calls - 1], calls[#calls]
	assert(main.output == "DP-2" and main.disabled == false)
	assert(tv.output == "HDMI-A-2")
	assert(tv.disabled == (profile == "solo"))
	assert(tv.mirror == (profile == "mirror" and "DP-2" or ""), "leaving mirror must clear mirroring")
end
local count = #calls
assert(not pcall(ctx.monitors.setProfile, "remote"))
assert(#calls == count, "invalid actions must not mutate displays")
ctx.monitors.solo()
assert(calls[#calls].disabled)
print("explicit monitor actions ok")

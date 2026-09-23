local watcher_path = assert(arg[1], "usage: state-producers.lua <watcher-module> <sunshine-module>")
local sunshine_path = assert(arg[2], "sunshine module is required")
local load_watchers = assert(loadfile(watcher_path))
local load_sunshine = assert(loadfile(sunshine_path))

local events = {}
local facts = {}
local windows = {
	["game-one"] = { address = "game-one", tags = { "game" } },
}
local function record(source, state, active)
	facts[#facts + 1] = { source = source, state = state, active = active }
end
local ctx = {
	hl = {
		get_windows = function()
			local result = {}
			for _, window in pairs(windows) do
				result[#result + 1] = window
			end
			return result
		end,
		on = function(name, callback)
			events[name] = callback
		end,
	},
	state = { setSource = record },
}

load_watchers()(ctx)
assert(facts[#facts].source == "game-windows" and facts[#facts].active)

events["window.open"]({ address = "ordinary", tags = {} })
assert(facts[#facts].source == "game-windows" and facts[#facts].active)
events["window.close"](windows["game-one"])
windows["game-one"] = nil
assert(not facts[#facts].active, "gaming must clear after the final tagged window closes")

events["screenshare.state"](true, 1, "portal-a")
assert(facts[#facts].source == "hyprland-screenshare:1:portal-a")
assert(facts[#facts].state == "screen-recording" and facts[#facts].active)
events["screenshare.state"](true, 1, "portal-b")
events["screenshare.state"](false, 1, "portal-a")
assert(facts[#facts].source == "hyprland-screenshare:1:portal-a" and not facts[#facts].active)
assert(
	facts[#facts - 1].source == "hyprland-screenshare:1:portal-b" and facts[#facts - 1].active,
	"independent portal sessions must not be collapsed into a reload-sensitive counter"
)

local stream_facts = {}
local sunshine_ctx = {
	state = {
		setSource = function(source, state, active)
			stream_facts[state] = { source = source, active = active }
		end,
	},
}
load_sunshine()(sunshine_ctx, { enable = true })
Juicy.sunshine.setStreaming(true, true, 1920, 1080, 60, 1)
assert(stream_facts["remote-streaming"].active)
assert(not stream_facts.streaming.active)
Juicy.sunshine.setStreaming(false, false)
assert(not stream_facts.streaming.active and not stream_facts["remote-streaming"].active)
Juicy.sunshine.setStreaming(true, false)
assert(stream_facts.streaming.active and not stream_facts["remote-streaming"].active)

local load_module = assert(loadfile(assert(arg[1])))
local original = { open = io.open, popen = io.popen, getenv = os.getenv, execute = os.execute, rename = os.rename }
local files, events, commands, dispatches, timers = {}, {}, {}, {}, {}
local clock = 10
local directory_ready = false
local active = { class = "com.mitchellh.ghostty", stable_id = "180003a8" }
io.open = function(path, mode)
	if mode == "w" then
		if not directory_ready then
			return nil, "directory not created yet"
		end
		return {
			write = function(_, value)
				files[path] = value
			end,
			close = function() end,
		}
	end
	return files[path] and {
		read = function()
			return files[path]
		end,
		close = function() end,
	} or nil
end
io.popen = function()
	error("application I/O must not run in Hyprland")
end
os.getenv = function(name)
	return ({ XDG_RUNTIME_DIR = "/run/test", HYPRLAND_INSTANCE_SIGNATURE = "test" })[name]
end
os.execute = function()
	error("child processes must be launched through Hyprland")
end
os.rename = function(a, b)
	files[b] = files[a]
	files[a] = nil
	return true
end
local hl = {
	get_active_window = function()
		return active
	end,
	exec_cmd = function(command)
		commands[#commands + 1] = command
	end,
	dsp = {
		focus = function(action)
			return action
		end,
	},
	dispatch = function(action)
		dispatches[#dispatches + 1] = action
	end,
	on = function(event, callback)
		events[event] = callback
	end,
	timer = function(callback)
		local t = { callback = callback, set_enabled = function() end }
		timers[#timers + 1] = t
		return t
	end,
}
local opened
load_module()({
	hl = hl,
	terminal = {
		isWindow = function(w)
			return w.class == "com.mitchellh.ghostty"
		end,
		open = function(spec)
			opened = spec
		end,
	},
}, {
	broker = "/bin/smart-focus",
	nvim = "/bin/nvim",
	epoch = "epoch",
	now = function()
		return clock
	end,
})
assert(files["/run/test/smart-focus/test/context"] == nil, "directory creation can finish after config loading")
assert(#commands == 1 and commands[1]:match("^mkdir "), "directory preparation must be asynchronous")
commands = {}
directory_ready = true
Juicy.smartFocus("left")
assert(files["/run/test/smart-focus/test/context"] == "epoch\t0\t180003a8\n", "publication must recover after directory creation")
assert(#commands == 1 and #dispatches == 0, "request must return asynchronously")
Juicy.smartFocusComplete("epoch:1", "moved", "")
assert(#dispatches == 0, "handled movement must not also move desktop focus")
Juicy.smartFocus("right")
Juicy.smartFocusComplete("epoch:2", "edge", "")
assert(#dispatches == 1 and dispatches[1].direction == "right")
Juicy.smartFocusComplete("epoch:2", "edge", "")
assert(#dispatches == 1, "duplicate completion must be ignored")
Juicy.smartFocus("up")
events["window.active"]()
Juicy.smartFocusComplete("epoch:3", "edge", "")
assert(#dispatches == 1, "focus changes invalidate pending requests")
Juicy.smartFocus("down")
clock = 11
Juicy.smartFocusComplete("epoch:4", "edge", "")
assert(#dispatches == 1, "late edge must not move desktop focus")
Juicy.smartFocus("left")
Juicy.smartFocus("right")
local count = #commands
Juicy.smartFocusComplete("epoch:5", "unknown", "")
assert(#commands == count and #dispatches == 1, "unknown outcomes discard queued requests")
Juicy.smartFocus("left")
Juicy.smartFocus("right")
Juicy.smartFocusComplete("epoch:6", "moved", "")
assert(#commands == count + 2, "queued movement starts only after acknowledgement")
Juicy.smartFocusComplete("epoch:7", "blocked", "")
assert(#dispatches == 1)
Juicy.smartFocus("left")
Juicy.smartFocusComplete("epoch:8", "unavailable", "")
assert(#dispatches == 2, "an unavailable broker has not accepted a mutation")
Juicy.smartFocus("left")
timers[#timers].callback()
Juicy.smartFocusComplete("epoch:9", "edge", "")
assert(#dispatches == 2, "watchdog must invalidate late completions")
Juicy.openNvimWindow()
Juicy.smartFocusComplete("epoch:10", "cwd", "/tmp/project with spaces")
assert(opened.cwd == "/tmp/project with spaces" and opened.args[2] == "/bin/nvim")
active = { class = "firefox", stable_id = "b" }
events["window.active"]()
count = #commands
Juicy.smartFocus("right")
assert(#commands == count and #dispatches == 3, "ordinary windows use native focus directly")
Juicy.smartFocus("sideways")
assert(#commands == count and #dispatches == 3)
io.open, io.popen = original.open, original.popen
os.getenv, os.execute, os.rename = original.getenv, original.execute, original.rename

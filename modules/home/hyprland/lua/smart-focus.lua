-- Hyprland owns focus and key ordering. The broker owns application I/O.
return function(ctx, opts)
	local hl = ctx.hl
	local function quote(value)
		return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
	end
	local function line(path)
		local file = io.open(path, "r")
		if not file then
			return nil
		end
		local result = file:read("*l")
		file:close()
		return result
	end
	local now = opts.now or function()
		return tonumber((line("/proc/uptime") or "0"):match("^[%d.]+"))
	end
	local instance = os.getenv("HYPRLAND_INSTANCE_SIGNATURE")
	local runtime = os.getenv("XDG_RUNTIME_DIR")
	local epoch = opts.epoch or line("/proc/sys/kernel/random/uuid")
	local directory = runtime and instance and (runtime .. "/smart-focus/" .. instance)
	local generation, sequence = 0, 0
	local pending, timer
	local queue = {}
	local ready = directory and epoch and opts.broker
	if ready then
		-- Hyprland reaps children itself: os.execute can report ECHILD even
		-- after a successful command. Prepare asynchronously and retry writes.
		hl.exec_cmd("mkdir -p -m 700 " .. quote(directory))
	end
	local function window_id()
		local w = hl.get_active_window()
		return w and tostring(w.stable_id or w.stableId or "") or ""
	end
	local function context()
		return table.concat({ epoch, tostring(generation), window_id() }, "\t")
	end
	local function publish()
		if not ready then
			return false
		end
		local file = io.open(directory .. "/context.tmp", "w")
		if not file then
			return false
		end
		file:write(context() .. "\n")
		file:close()
		return os.rename(directory .. "/context.tmp", directory .. "/context") == true
	end
	local function cancel()
		generation = generation + 1
		pending = nil
		queue = {}
		if timer then
			timer:set_enabled(false)
		end
		publish()
	end
	local function desktop(direction)
		hl.dispatch(hl.dsp.focus({ direction = direction }))
	end
	local begin, advance
	advance = function()
		local next_request = table.remove(queue, 1)
		while next_request and next_request.expires <= now() do
			next_request = table.remove(queue, 1)
		end
		if next_request then
			begin(next_request.direction, next_request.operation, next_request.expires)
		end
	end
	begin = function(direction, operation, expires)
		local w = hl.get_active_window()
		if not ready or not w or not ctx.terminal.isWindow(w) then
			local remaining = queue
			if operation == "focus" then
				desktop(direction)
			end
			queue = remaining
			advance()
			return
		end
		if not publish() then
			return
		end
		sequence = sequence + 1
		local id = epoch .. ":" .. tostring(sequence)
		pending = {
			id = id,
			context = context(),
			direction = direction,
			operation = operation,
			deadline = expires or (now() + 0.2),
		}
		local command = table.concat({
			quote(opts.broker),
			"request",
			quote(instance),
			quote(id),
			quote(pending.context),
			quote(string.format("%.3f", pending.deadline)),
			quote(direction),
			quote(operation),
		}, " ")
		hl.exec_cmd(command)
		-- A timeout has an unknown outcome, so never perform a second movement.
		if timer then
			timer:set_enabled(false)
		end
		timer = hl.timer(function()
			if pending and pending.id == id then
				cancel()
			end
		end, { timeout = 300, type = "oneshot" })
	end
	_G.Juicy = _G.Juicy or {}
	_G.Juicy.smartFocusComplete = function(id, status, cwd)
		local request = pending
		if not request or request.id ~= id then
			return
		end
		if request.context ~= context() or now() >= request.deadline then
			cancel()
			return
		end
		pending = nil
		if timer then
			timer:set_enabled(false)
		end
		local remaining = queue
		queue = {}
		if request.operation == "cwd" then
			if status == "cwd" and type(cwd) == "string" and cwd:sub(1, 1) == "/" then
				ctx.terminal.open({ cwd = cwd, args = { "-e", opts.nvim } })
			elseif ctx.feedback then
				ctx.feedback.notify("Neovim project", "Focus a responsive Neovim pane to open its project")
			end
		elseif status == "edge" or status == "unavailable" then
			desktop(request.direction)
		elseif status ~= "moved" then
			return
		end
		-- Each queued key resolves its new owner after the preceding movement.
		queue = remaining
		advance()
	end
	local function enqueue(direction, operation)
		if direction ~= "left" and direction ~= "right" and direction ~= "up" and direction ~= "down" then
			return
		end
		if pending then
			if #queue < 8 then
				table.insert(queue, { direction = direction, operation = operation, expires = now() + 0.2 })
			end
		else
			begin(direction, operation)
		end
	end
	_G.Juicy.smartFocus = function(direction)
		enqueue(direction, "focus")
	end
	_G.Juicy.openNvimWindow = function()
		local w = hl.get_active_window()
		if not ready or not w or not ctx.terminal.isWindow(w) then
			return false
		end
		enqueue("left", "cwd")
		return true -- completion is asynchronous
	end
	hl.on("window.active", cancel)
	hl.on("workspace.active", cancel)
	hl.on("workspace.special_active", cancel)
	hl.on("config.unload", cancel)
	publish()
end

-- ============================================================
-- RUNTIME STATE
-- ============================================================
return function(ctx, opts)
	opts = opts or {}
	local states = {}
	local manual = {}
	local sources = {}
	local clearUserStates = opts.clearUser or {}

	for _, name in ipairs(opts.states or {}) do
		states[name] = false
		manual[name] = false
	end

	local priority = opts.priority or {}

	local listeners = {}
	local lastPrimary = nil

	local function normalize(name)
		name = tostring(name or "")
		if name == "normal" then
			return nil
		end
		if states[name] == nil then
			error("unknown Hyprland state: " .. name)
		end
		return name
	end

	local function snapshot()
		local out = {}
		for name, enabled in pairs(states) do
			out[name] = enabled
		end
		return out
	end

	local function primary()
		for _, name in ipairs(priority) do
			if states[name] then
				return name
			end
		end
		return "normal"
	end

	local function notify(name, enabled, meta)
		local currentPrimary = primary()
		for _, fn in ipairs(listeners) do
			fn(name, enabled, currentPrimary, meta or {})
		end

		if currentPrimary ~= lastPrimary then
			lastPrimary = currentPrimary
			local publisher = opts.publisher
			if publisher then
				ctx.hl.exec_cmd(publisher .. " " .. currentPrimary)
			end
		end
	end

	local function source_active(name)
		for _, sourceStates in pairs(sources) do
			if sourceStates[name] == true then
				return true
			end
		end
		return false
	end

	local function recompute(name, meta)
		local enabled = manual[name] == true or source_active(name)
		if states[name] == enabled then
			return primary()
		end
		states[name] = enabled
		notify(name, enabled, meta)
		return primary()
	end

	local api = {}

	function api.set(name, enabled, meta)
		name = normalize(name)
		if not name then
			return primary()
		end

		enabled = enabled == true
		if manual[name] == enabled then
			return primary()
		end

		manual[name] = enabled
		return recompute(name, meta)
	end

	function api.setSource(source, name, enabled, meta)
		name = normalize(name)
		if not name then
			return primary()
		end

		source = tostring(source or "")
		if source == "" then
			error("state source is required")
		end

		sources[source] = sources[source] or {}
		enabled = enabled == true
		if sources[source][name] == enabled then
			return primary()
		end

		sources[source][name] = enabled
		return recompute(name, meta)
	end

	function api.toggle(name)
		name = normalize(name)
		if not name then
			return primary()
		end
		return api.set(name, not states[name])
	end

	function api.active(name)
		name = normalize(name)
		return name and states[name] == true or false
	end

	function api.snapshot()
		return snapshot()
	end

	function api.primary()
		return primary()
	end

	function api.onChange(fn)
		listeners[#listeners + 1] = fn
	end

	function api.clearUser()
		for _, name in ipairs(clearUserStates) do
			api.set(name, false)
		end
		return primary()
	end

	ctx.state = api
	_G.Juicy = _G.Juicy or {}
	_G.Juicy.state = api

	notify("normal", true, { initial = true })
end

-- Forward transient desktop facts to the persistent HA presence controller.
-- The controller owns aggregation, priority, qualification, and delivery.
return function(ctx, opts)
	opts = opts or {}
	local allowed = {}
	local published = {}

	for _, name in ipairs(opts.states or {}) do
		allowed[name] = true
	end

	local function normalize(name)
		name = tostring(name or "")
		if not allowed[name] then
			error("unknown Hyprland state: " .. name)
		end
		return name
	end

	local function shell_quote(value)
		return "'" .. tostring(value):gsub("'", "'\"'\"'") .. "'"
	end

	local function set_source(source, name, enabled)
		source = tostring(source or "")
		if source == "" then
			error("state source is required")
		end

		name = normalize(name)
		enabled = enabled == true
		local key = source .. "\0" .. name
		if published[key] == enabled then
			return name
		end

		if opts.sourceCommand and opts.sourceCommand ~= "" then
			local result = ctx.hl.exec_cmd(table.concat({
				opts.sourceCommand,
				shell_quote(source),
				shell_quote(name),
				enabled and "true" or "false",
			}, " "))
			if type(result) == "table" and result.ok == false then
				error(result.error or "Unable to publish presence fact", 0)
			end
		end
		published[key] = enabled
		return name
	end

	local api = {}

	function api.set(name, enabled)
		return set_source("hyprland-manual", name, enabled)
	end

	api.setSource = set_source
	ctx.state = api
	_G.Juicy = _G.Juicy or {}
	_G.Juicy.state = api
end

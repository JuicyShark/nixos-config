-- ============================================================
-- CHEATSHEET STATE
-- ============================================================
return function(ctx)
	local currentSubmap = ""
	local currentReset = nil
	local entries = {}

	local function shell_quote(value)
		return "'" .. tostring(value or ""):gsub("'", "'\\''") .. "'"
	end

	local function active_layout()
		local workspace = ctx.layout and ctx.layout.currentWorkspace and ctx.layout.currentWorkspace()
		return workspace and workspace.tiled_layout or ""
	end

	local function call(...)
		local parts = { ctx.commands.submapCheatsheetCall }
		for _, value in ipairs({ ... }) do
			parts[#parts + 1] = shell_quote(value)
		end
		os.execute(table.concat(parts, " ") .. " >/dev/null 2>&1 &")
	end

	local function json_escape(s)
		return (s:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t"))
	end

	local function add_string_field(parts, key, value)
		if type(value) == "string" then
			parts[#parts + 1] = '"' .. key .. '":"' .. json_escape(value) .. '"'
		end
	end

	local function add_true_field(parts, key, value)
		if value == true then
			parts[#parts + 1] = '"' .. key .. '":true'
		end
	end

	local function encode_entry(entry)
		local parts = {}
		add_string_field(parts, "submap", entry.submap)
		add_string_field(parts, "combo", entry.combo)
		add_string_field(parts, "action", entry.action)
		add_string_field(parts, "targetSubmap", entry.targetSubmap)
		add_true_field(parts, "entersSubmap", entry.entersSubmap)
		add_true_field(parts, "isEscapeExit", entry.isEscapeExit)
		return "{" .. table.concat(parts, ",") .. "}"
	end

	local function push(entry, opts)
		opts = opts or {}
		if opts.cheatsheet == false then
			return
		end
		entries[#entries + 1] = entry
	end

	ctx.cheatsheet = {
		reset = function()
			return currentReset
		end,
		withSubmap = function(name, reset, body)
			local prevSubmap = currentSubmap
			local prevReset = currentReset
			currentSubmap = name
			currentReset = reset
			body()
			currentSubmap = prevSubmap
			currentReset = prevReset
		end,
		recordBind = function(keys, desc, opts)
			if desc and not (opts and opts.mouse) then
				push({ submap = currentSubmap, combo = keys, action = desc }, opts)
			end
		end,
		recordSubmap = function(keys, target, desc, opts)
			push({
				submap = currentSubmap,
				combo = keys,
				action = desc,
				entersSubmap = true,
				targetSubmap = target,
			}, opts)
		end,
		recordExit = function()
			push({
				submap = currentSubmap,
				combo = "Escape",
				action = "Exit submap",
				isEscapeExit = true,
			})
		end,
		show = function(name)
			call("showSubmap", name, active_layout())
		end,
		hide = function()
			call("hideSubmap")
		end,
		toggleOptions = function()
			call("toggleOptions", active_layout())
		end,
		write = function()
			local rt = os.getenv("XDG_RUNTIME_DIR")
			local sig = os.getenv("HYPRLAND_INSTANCE_SIGNATURE")
			if not rt or not sig then
				return
			end

			local f = io.open(rt .. "/hypr/" .. sig .. "/cheatsheet-binds.json", "w")
			if not f then
				return
			end

			local encoded = {}
			for i, entry in ipairs(entries) do
				encoded[i] = "  " .. encode_entry(entry)
			end
			f:write("[\n" .. table.concat(encoded, ",\n") .. "\n]\n")
			f:close()
		end,
	}
end

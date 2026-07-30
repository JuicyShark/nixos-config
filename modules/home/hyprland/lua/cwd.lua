return function(ctx, opts)
	opts = opts or {}

	local function shell_quote(value)
		return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
	end

	local function read_command(command)
		local pipe = io.popen(command .. " 2>/dev/null")
		if not pipe then
			return nil
		end
		local output = pipe:read("*a")
		pipe:close()
		return output
	end

	local function cwd_of(pid)
		local cwd = read_command(shell_quote(opts.readlink) .. " -f /proc/" .. tostring(pid) .. "/cwd")
		if not cwd then
			return nil
		end
		cwd = cwd:gsub("%s+$", "")
		return cwd ~= "" and cwd or nil
	end

	local function child_pids(pid)
		local output = read_command(shell_quote(opts.pgrep) .. " -P " .. tostring(pid))
		local children = {}
		for child in (output or ""):gmatch("%d+") do
			table.insert(children, tonumber(child))
		end
		return children
	end

	local function deepest_cwd(pid, seen, depth)
		if not pid or depth > 16 or seen[pid] then
			return nil
		end
		seen[pid] = true

		-- The Ghostty window PID stays at its launch cwd; the foreground shell
		-- or TUI descendant carries the cwd the user is actually working in.
		local children = child_pids(pid)
		for index = #children, 1, -1 do
			local cwd = deepest_cwd(children[index], seen, depth + 1)
			if cwd then
				return cwd
			end
		end

		return cwd_of(pid)
	end

	ctx.cwd = {
		forWindow = function(window)
			return window and deepest_cwd(tonumber(window.pid), {}, 0) or nil
		end,
	}
end

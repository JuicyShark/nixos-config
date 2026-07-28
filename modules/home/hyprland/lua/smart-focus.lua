-- Directional focus router. Decides per-keypress whether a SUPER+arrow
-- should move focus inside emacs (window-in-direction), inside direct
-- terminal neovim, inside tmux, inside Kitty's own window grid, or to
-- the next Hyprland window. Exported as ctx.smartFocus.
--
-- Behaviour:
--   1. If active window is emacs-class, or a terminal with an emacs
--      descendant, try emacsclient --eval window-in-direction (~50ms cap).
--   2. Else if active is a terminal with direct neovim in its process tree,
--      query the RPC socket for a target split and move there only if one
--      exists.
--   3. Else if active is a terminal with tmux in its process tree, preflight
--      tmux pane-edge state and send the configured shortcut only when a pane
--      exists in that direction.
--   4. Else if active is Kitty, focus Kitty's neighboring window when one
--      exists in that direction.
--   5. Else move Hyprland focus.

return function(ctx, opts)
	local hl = ctx.hl
	opts = opts or {}
	local hasEmacs = opts.features and opts.features.emacs or false
	local hasNeovim = opts.features and opts.features.neovim or false
	local apps = opts.apps or {}
	local smartFocusConfig = opts.smartFocus or {}
	local smartFocusKeys = smartFocusConfig.keys or {}
	local smartFocusMultiplexers = smartFocusConfig.multiplexers or {}

	local terminal_classes = {
		kitty = true,
		dropdown = true,
		pinned = true,
		["floating-editor"] = true,
		["com.mitchellh.ghostty"] = true,
		["org.wezfurlong.wezterm"] = true,
		["org.alacritty"] = true,
		foot = true,
	}

	local kitty_classes = {
		kitty = true,
		dropdown = true,
		pinned = true,
		["floating-editor"] = true,
	}

	local emacs_classes = {
		emacs = true,
		["org.gnu.Emacs"] = true,
	}

	local DIRS = {
		left = {
			emacs = "left",
			kitty = "left",
			key = smartFocusKeys.left or "left",
			hypr = "left",
			tmux_edge = "pane_at_left",
		},
		right = {
			emacs = "right",
			kitty = "right",
			key = smartFocusKeys.right or "right",
			hypr = "right",
			tmux_edge = "pane_at_right",
		},
		up = {
			emacs = "above",
			kitty = "top",
			key = smartFocusKeys.up or "up",
			hypr = "up",
			tmux_edge = "pane_at_top",
		},
		down = {
			emacs = "below",
			kitty = "bottom",
			key = smartFocusKeys.down or "down",
			hypr = "down",
			tmux_edge = "pane_at_bottom",
		},
	}

	local function multiplexer_mod(name, default)
		local config = smartFocusMultiplexers[name] or {}
		return config.mod or default
	end

	local function read_first_line(path)
		local f = io.open(path, "r")
		if not f then
			return nil
		end
		local s = f:read("*l")
		f:close()
		return s
	end

	local function proc_comm(pid)
		return read_first_line("/proc/" .. pid .. "/comm")
	end

	-- Read children of a pid's main thread directly from /proc — no fork.
	-- Misses children spawned from non-main threads, which is rare for the
	-- shell/terminal/editor trees we care about here.
	local function proc_children(pid)
		local line = read_first_line("/proc/" .. pid .. "/task/" .. pid .. "/children")
		if not line or line == "" then
			return {}
		end
		local out = {}
		for c in line:gmatch("%S+") do
			out[#out + 1] = c
		end
		return out
	end

	local function proc_name_matches(comm, name)
		return comm == name or comm == "." .. name .. "-wrapped"
	end

	local function shell_quote(s)
		return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
	end

	local function read_command(cmd)
		local p = io.popen(cmd)
		if not p then
			return nil
		end
		local out = p:read("*a")
		local ok = p:close()
		if not ok then
			return nil
		end
		return out
	end

	local function read_command_output(cmd)
		local p = io.popen(cmd)
		if not p then
			return nil
		end
		local out = p:read("*a")
		p:close()
		return out
	end

	local function trim_output(out)
		if not out then
			return nil
		end
		return out:gsub("%s+$", "")
	end

	local function nvim_socket(pid)
		local rt = os.getenv("XDG_RUNTIME_DIR")
		if not rt or not pid then
			return nil
		end
		return rt .. "/nvim-smart-focus-" .. tostring(pid) .. ".sock"
	end

	local function nvim_kitty_window_socket(window_id)
		local rt = os.getenv("XDG_RUNTIME_DIR")
		if not rt or not window_id then
			return nil
		end
		return rt .. "/nvim-smart-focus-kitty-window-" .. tostring(window_id) .. ".sock"
	end

	local function kitty_socket(pid)
		local rt = os.getenv("XDG_RUNTIME_DIR")
		if not rt or not pid then
			return nil
		end
		return "unix:" .. rt .. "/kitty-" .. tostring(pid)
	end

	-- TTL cache for descendant scans. A held SUPER+arrow repeats ~50/sec;
	-- without this, every repeat re-walks the same tree.
	local scan_cache = {}
	local SCAN_TTL = 2

	-- BFS over the descendant tree; bail as soon as both flags are set,
	-- and cap iterations so a runaway process tree can't stall the keypress.
	local function scan_descendants(root_pid)
		if not root_pid or root_pid <= 0 then
			return false, false, false, nil
		end
		local key = tostring(root_pid)
		local now = os.time()
		local cached = scan_cache[key]
		if cached and (now - cached.t) < SCAN_TTL then
			return cached.tmux, cached.emacs, cached.nvim, cached.nvim_pid
		end

		local has_tmux, has_emacs, has_nvim = false, false, false
		local nvim_pid = nil
		local queue = { key }
		local seen = {}
		local steps = 0
		while #queue > 0 and steps < 500 do
			steps = steps + 1
			local pid = table.remove(queue, 1)
			if not seen[pid] then
				seen[pid] = true
				local comm = proc_comm(pid) or ""
				if not has_tmux and proc_name_matches(comm, "tmux") then
					has_tmux = true
				end
				if not has_emacs and proc_name_matches(comm, "emacs") then
					has_emacs = true
				end
				if proc_name_matches(comm, "nvim") or proc_name_matches(comm, "nvim-python3") then
					has_nvim = true
					-- NixVim's launcher can leave an outer nvim process above
					-- the embedded editor that owns the RPC socket. Keep the
					-- deepest matching descendant rather than the wrapper.
					nvim_pid = tonumber(pid)
				end
				if has_tmux and has_emacs and has_nvim then
					break
				end
				for _, c in ipairs(proc_children(pid)) do
					queue[#queue + 1] = c
				end
			end
		end

		scan_cache[key] = {
			t = now,
			tmux = has_tmux,
			emacs = has_emacs,
			nvim = has_nvim,
			nvim_pid = nvim_pid,
		}
		return has_tmux, has_emacs, has_nvim, nvim_pid
	end

	local function emacs_cmd(expr)
		if not apps.emacsclient or not apps.timeout then
			return nil
		end
		return shell_quote(apps.timeout)
			.. " 0.12s "
			.. shell_quote(apps.emacsclient)
			.. " --eval "
			.. shell_quote(expr)
			.. " 2>/dev/null"
	end

	local function nvim_expr_cmd(socket, expr)
		if not apps.nvim or not apps.timeout or not socket then
			return nil
		end
		return shell_quote(apps.timeout)
			.. " 0.35s "
			.. shell_quote(apps.nvim)
			.. " --server "
			.. shell_quote(socket)
			.. " --remote-expr "
			.. shell_quote(expr)
			.. " 2>/dev/null"
	end

	local function tmux_cmd(action)
		if not apps.tmux or not apps.timeout then
			return nil
		end
		return shell_quote(apps.timeout) .. " 0.12s " .. shell_quote(apps.tmux) .. " " .. action .. " 2>/dev/null"
	end

	local function kitty_cmd(pid, action)
		if not apps.kitty or not apps.timeout then
			return nil
		end
		local socket = kitty_socket(pid)
		if not socket then
			return nil
		end
		return shell_quote(apps.timeout)
			.. " 0.12s "
			.. shell_quote(apps.kitty)
			.. " @ --to "
			.. shell_quote(socket)
			.. " "
			.. action
			.. " 2>/dev/null"
	end

	local function kitty_active_context(pid)
		if not apps.jq then
			return nil, nil
		end
		local cmd = kitty_cmd(
			pid,
			"ls | "
				.. shell_quote(apps.jq)
				.. " -r "
				.. shell_quote(
					"[.[] | select(.is_active)][0].tabs"
						.. " | [.[] | select(.is_active)][0].windows"
						.. " | [.[] | select(.is_active)][0]"
						.. " | [.env.KITTY_WINDOW_ID, (.foreground_processes[0].pid // .pid // empty)]"
						.. " | @tsv"
				)
		)
		local context = trim_output(read_command(cmd))
		if not context or context == "" then
			return nil, nil
		end
		local window_id, foreground_pid = context:match("^([^\t]+)\t(%d+)$")
		return window_id, tonumber(foreground_pid)
	end

	-- Cheap precheck: does the emacs daemon socket exist? Avoids paying the
	-- timeout+emacsclient fork cost when emacs isn't running.
	local function emacs_daemon_running()
		local rt = os.getenv("XDG_RUNTIME_DIR")
		if not rt then
			return true
		end
		local ok = os.rename(rt .. "/emacs/server", rt .. "/emacs/server")
		return ok == true
	end

	local function try_emacs(d)
		if not emacs_daemon_running() then
			return false
		end
		local expr = string.format(
			[[(let* ((direction '%s)
         (source (selected-window))
         (source-edges (window-absolute-pixel-edges source))
         (source-left (nth 0 source-edges))
         (source-top (nth 1 source-edges))
         (source-right (nth 2 source-edges))
         (source-bottom (nth 3 source-edges))
         (source-x (/ (+ source-left source-right) 2.0))
         (source-y (/ (+ source-top source-bottom) 2.0))
         (target
          (or (window-in-direction direction source t nil nil 'never)
              (let (best best-score)
                (walk-windows
                 (lambda (candidate)
                   (unless (eq candidate source)
                     (let* ((edges (window-absolute-pixel-edges candidate))
                            (left (nth 0 edges))
                            (top (nth 1 edges))
                            (right (nth 2 edges))
                            (bottom (nth 3 edges))
                            (x (/ (+ left right) 2.0))
                            (y (/ (+ top bottom) 2.0))
                            (horizontal-overlap (and (< left source-right) (< source-left right)))
                            (vertical-overlap (and (< top source-bottom) (< source-top bottom)))
                            primary secondary)
                       (cond
                        ((and (eq direction 'left) vertical-overlap (<= right source-left))
                         (setq primary (- source-left right)
                               secondary (abs (- y source-y))))
                        ((and (eq direction 'right) vertical-overlap (>= left source-right))
                         (setq primary (- left source-right)
                               secondary (abs (- y source-y))))
                        ((and (eq direction 'above) horizontal-overlap (<= bottom source-top))
                         (setq primary (- source-top bottom)
                               secondary (abs (- x source-x))))
                        ((and (eq direction 'below) horizontal-overlap (>= top source-bottom))
                         (setq primary (- top source-bottom)
                               secondary (abs (- x source-x)))))
                       (when primary
                         (let ((score (+ primary (/ secondary 10000.0))))
                           (when (or (not best-score) (< score best-score))
                             (setq best candidate
                                   best-score score)))))))
                 'never 'visible)
                best))))
    (when target
      (select-frame-set-input-focus (window-frame target))
      (select-window target)
      t))]],
			d.emacs
		)
		local cmd = emacs_cmd(expr)
		if not cmd then
			return false
		end
		local p = io.popen(cmd)
		if not p then
			return false
		end
		local first = p:read("*l")
		p:close()
		return first ~= nil and first:match("^t") ~= nil
	end

	local function try_nvim(socket, d)
		local expr = "luaeval(\"require('juicy.smart_focus').move(_A)\", " .. shell_quote(d.hypr) .. ")"
		local cmd = nvim_expr_cmd(socket, expr)
		if not cmd then
			return nil
		end
		local out = read_command_output(cmd)
		if out and out:match("^1") then
			return true
		end
		if out and out:match("^0") then
			return false
		end
		return nil
	end

	local function nvim_remote_expr(socket, expr)
		local cmd = nvim_expr_cmd(socket, expr)
		if not cmd then
			return nil
		end
		return trim_output(read_command_output(cmd))
	end

	local function tmux_has_pane_in_direction(d)
		if not d.tmux_edge then
			return nil
		end
		local cmd = tmux_cmd("display-message -p '#{" .. d.tmux_edge .. "}'")
		if not cmd then
			return nil
		end
		local out = read_command(cmd)
		if not out then
			return nil
		end
		if out:match("^0") then
			return true
		end
		if out:match("^1") then
			return false
		end
		return nil
	end

	local function try_kitty(pid, d)
		if not d.kitty then
			return false
		end
		local cmd = kitty_cmd(pid, "focus-window --match neighbor:" .. d.kitty)
		if not cmd then
			return false
		end
		return read_command(cmd) ~= nil
	end

	local function send_terminal_shortcut(mods, d)
		-- send_shortcut inherits the current bind press state; from SUPER+arrow
		-- key-down it can leave the injected shortcut pressed in the newly
		-- focused pane.
		hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = d.key, state = "down", window = "activewindow" }))
		hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = d.key, state = "up", window = "activewindow" }))
	end

	local function move_hypr(d)
		hl.dispatch(hl.dsp.focus({ direction = d.hypr }))
	end

	local function open_nvim_window()
		if not hasNeovim or not apps.kitty then
			return false
		end

		local w = hl.get_active_window and hl.get_active_window()
		if not w then
			return false
		end

		local class = w.class or ""
		local pid = tonumber(w.pid) or 0
		if kitty_classes[class] ~= true or pid <= 0 then
			return false
		end

		-- Kitty already knows the cwd of the focused terminal window. Asking it
		-- to launch with --cwd=current avoids depending on Neovim RPC state (or
		-- on the shell being a direct child of Kitty).
		hl.exec_cmd(
			apps.kitty
				.. " @ --to "
				.. shell_quote(kitty_socket(pid))
				.. " launch --type=os-window --cwd=current "
				.. shell_quote(apps.nvim)
		)
		return true
	end

	local function smart_focus(direction)
		local d = DIRS[direction]
		if not d then
			return
		end

		local w = hl.get_active_window and hl.get_active_window()
		if not w then
			move_hypr(d)
			return
		end

		local class = w.class or ""
		local pid = tonumber(w.pid) or 0

		local is_emacs_class = emacs_classes[class] == true
		local is_terminal = terminal_classes[class] == true
		local kitty_window_id, kitty_foreground_pid = nil, nil
		if kitty_classes[class] == true and pid > 0 then
			kitty_window_id, kitty_foreground_pid = kitty_active_context(pid)
		end

		-- Pure emacs window: skip the descendant scan entirely.
		if hasEmacs and is_emacs_class then
			if try_emacs(d) then
				return
			end
			move_hypr(d)
			return
		end

		local has_tmux, has_emacs_proc, has_nvim_proc, nvim_pid = false, false, false, nil
		local scan_pid = kitty_foreground_pid or (kitty_classes[class] ~= true and pid or nil)
		if is_terminal and scan_pid and scan_pid > 0 then
			has_tmux, has_emacs_proc, has_nvim_proc, nvim_pid = scan_descendants(scan_pid)
		end

		if hasEmacs and has_emacs_proc then
			if try_emacs(d) then
				return
			end
		end

		if is_terminal and hasNeovim and not has_tmux then
			if kitty_classes[class] == true then
				local result = try_nvim(nvim_kitty_window_socket(kitty_window_id), d)
				if result == true then
					return
				end
			end
			if kitty_classes[class] ~= true and try_nvim(nvim_socket(nvim_pid), d) then
				return
			end
		end

		if is_terminal and has_tmux then
			local has_tmux_pane = tmux_has_pane_in_direction(d)
			if has_tmux_pane == true then
				send_terminal_shortcut(multiplexer_mod("tmux", "CTRL"), d)
				return
			end
		end

		if kitty_classes[class] == true and pid > 0 then
			if try_kitty(pid, d) then
				return
			end
		end

		move_hypr(d)
	end

	_G.Juicy = _G.Juicy or {}
	_G.Juicy.smartFocus = smart_focus
	_G.Juicy.openNvimWindow = open_nvim_window
end

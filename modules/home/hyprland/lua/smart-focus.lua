-- Directional focus router. Decides per-keypress whether a SUPER+arrow
-- should move focus inside emacs (window-in-direction), inside zellij
-- (configured shortcut sent to the active terminal), inside tmux
-- (configured shortcut sent to the active terminal), or to the next
-- Hyprland window. Exported as ctx.smartFocus.
--
-- Behaviour:
--   1. If active window is emacs-class, or a terminal with an emacs
--      descendant, try emacsclient --eval window-in-direction (~50ms cap).
--   2. Else if active is a terminal with zellij in its process tree,
--      dispatch the configured shortcut so zellij's pane navigation handles
--      the move.
--   3. Else if active is a terminal with tmux in its process tree,
--      dispatch the configured shortcut so tmux's pane navigation handles
--      the move.
--   4. Else move Hyprland focus, using hy3's dispatcher on hy3 workspaces.

return function(ctx)
local hl = ctx.hl
local hasEmacs = ctx.features.emacs
local apps = ctx.cfg.apps or {}
local smartFocusConfig = ctx.cfg.smartFocus or {}
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

local emacs_classes = {
    emacs = true,
    ["org.gnu.Emacs"] = true,
}

local DIRS = {
    left  = { emacs = "left",  key = smartFocusKeys.left  or "left",  hypr = "left",  axis = "x", sign = -1 },
    right = { emacs = "right", key = smartFocusKeys.right or "right", hypr = "right", axis = "x", sign = 1  },
    up    = { emacs = "above", key = smartFocusKeys.up    or "up",    hypr = "up",    axis = "y", sign = -1 },
    down  = { emacs = "below", key = smartFocusKeys.down  or "down",  hypr = "down",  axis = "y", sign = 1  },
}

local function multiplexer_mod(name, default)
    local config = smartFocusMultiplexers[name] or {}
    return config.mod or default
end

local function read_first_line(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local s = f:read("*l")
    f:close()
    return s
end

local function proc_comm(pid)
    return read_first_line("/proc/" .. pid .. "/comm")
end

local function proc_cmdline(pid)
    local f = io.open("/proc/" .. pid .. "/cmdline", "r")
    if not f then return {} end
    local s = f:read("*a") or ""
    f:close()

    local out = {}
    for arg in s:gmatch("[^\0]+") do out[#out+1] = arg end
    return out
end

-- Read children of a pid's main thread directly from /proc — no fork.
-- Misses children spawned from non-main threads, which is rare for the
-- shell/terminal/editor trees we care about here.
local function proc_children(pid)
    local line = read_first_line("/proc/" .. pid .. "/task/" .. pid .. "/children")
    if not line or line == "" then return {} end
    local out = {}
    for c in line:gmatch("%S+") do out[#out+1] = c end
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
    if not p then return nil end
    local out = p:read("*a")
    local ok = p:close()
    if not ok then return nil end
    return out
end

local function zellij_session_from_cmdline(args)
    for i, arg in ipairs(args) do
        if arg == "-s" or arg == "--session" then return args[i + 1] end
        local session = arg:match("^%-%-session=(.+)$")
        if session then return session end
    end

    for i, arg in ipairs(args) do
        if arg == "attach" or arg == "a" then
            local session = args[i + 1]
            if session and not session:match("^%-") then return session end
        end
    end

    return nil
end

-- TTL cache for descendant scans. A held SUPER+arrow repeats ~50/sec;
-- without this, every repeat re-walks the same tree.
local scan_cache = {}
local SCAN_TTL = 2

-- BFS over the descendant tree; bail as soon as both flags are set,
-- and cap iterations so a runaway process tree can't stall the keypress.
local function scan_descendants(root_pid)
    if not root_pid or root_pid <= 0 then return false, false, false end
    local key = tostring(root_pid)
    local now = os.time()
    local cached = scan_cache[key]
    if cached and (now - cached.t) < SCAN_TTL then
        return cached.tmux, cached.zellij, cached.emacs, cached.zellij_session
    end

    local has_tmux, has_zellij, has_emacs = false, false, false
    local zellij_session = nil
    local queue = { key }
    local seen = {}
    local steps = 0
    while #queue > 0 and steps < 500 do
        steps = steps + 1
        local pid = table.remove(queue, 1)
        if not seen[pid] then
            seen[pid] = true
            local comm = proc_comm(pid) or ""
            if not has_tmux   and proc_name_matches(comm, "tmux")   then has_tmux   = true end
            if proc_name_matches(comm, "zellij") then
                has_zellij = true
                zellij_session = zellij_session or zellij_session_from_cmdline(proc_cmdline(pid))
            end
            if not has_emacs  and proc_name_matches(comm, "emacs")  then has_emacs  = true end
            if has_tmux and has_zellij and has_emacs then break end
            for _, c in ipairs(proc_children(pid)) do queue[#queue+1] = c end
        end
    end

    scan_cache[key] = { t = now, tmux = has_tmux, zellij = has_zellij, emacs = has_emacs, zellij_session = zellij_session }
    return has_tmux, has_zellij, has_emacs, zellij_session
end

local function zellij_cmd(session, action)
    if not apps.zellij or not apps.timeout then return nil end
    return shell_quote(apps.timeout) .. " 0.12s " .. shell_quote(apps.zellij) ..
        " --session " .. shell_quote(session) .. " action " .. action .. " 2>/dev/null"
end

local function zellij_action(session, action)
    local cmd = zellij_cmd(session, action)
    if not cmd then return nil end
    return read_command(cmd)
end

local function emacs_cmd(expr)
    if not apps.emacsclient or not apps.timeout then return nil end
    return shell_quote(apps.timeout) .. " 0.12s " .. shell_quote(apps.emacsclient) ..
        " --eval " .. shell_quote(expr) .. " 2>/dev/null"
end

local function json_number(obj, key)
    local value = obj:match('"' .. key .. '"%s*:%s*(-?%d+)')
    return value and tonumber(value) or nil
end

local function json_true(obj, key)
    return obj:match('"' .. key .. '"%s*:%s*true') ~= nil
end

local function zellij_current_tab(session)
    local info = zellij_action(session, "current-tab-info --json")
    if not info then return nil end
    return {
        id = json_number(info, "tab_id"),
        tiled_count = json_number(info, "selectable_tiled_panes_count"),
    }
end

local function zellij_tab_panes(session, tab_id)
    local panes_json = zellij_action(session, "list-panes --json --geometry --state --tab")
    if not panes_json then return nil end

    local panes = {}
    local depth, start = 0, nil
    for i = 1, #panes_json do
        local c = panes_json:sub(i, i)
        if c == "{" then
            if depth == 0 then start = i end
            depth = depth + 1
        elseif c == "}" then
            depth = depth - 1
            if depth == 0 and start then
                local obj = panes_json:sub(start, i)
                if json_number(obj, "tab_id") == tab_id
                    and not json_true(obj, "is_plugin")
                    and json_true(obj, "is_selectable")
                    and not json_true(obj, "is_floating")
                then
                    panes[#panes + 1] = {
                        focused = json_true(obj, "is_focused"),
                        x = json_number(obj, "pane_x"),
                        y = json_number(obj, "pane_y"),
                        w = json_number(obj, "pane_columns"),
                        h = json_number(obj, "pane_rows"),
                    }
                end
            end
        end
    end

    return panes
end

local function ranges_overlap(a_start, a_len, b_start, b_len)
    return a_start < b_start + b_len and b_start < a_start + a_len
end

local function zellij_has_pane_in_direction(session, d)
    if not session then return nil end

    local tab = zellij_current_tab(session)
    if not tab or not tab.id or not tab.tiled_count then return nil end
    if tab.tiled_count <= 1 then return false end

    local panes = zellij_tab_panes(session, tab.id)
    if not panes then return nil end

    local focused = nil
    for _, pane in ipairs(panes) do
        if pane.focused then focused = pane; break end
    end
    if not focused or not focused.x or not focused.y or not focused.w or not focused.h then return nil end

    local focus_after_x = focused.x + focused.w
    local focus_after_y = focused.y + focused.h
    for _, pane in ipairs(panes) do
        if pane ~= focused and pane.x and pane.y and pane.w and pane.h then
            if d.axis == "x"
                and ranges_overlap(focused.y, focused.h, pane.y, pane.h)
                and ((d.sign < 0 and pane.x + pane.w <= focused.x) or (d.sign > 0 and pane.x >= focus_after_x))
            then
                return true
            end
            if d.axis == "y"
                and ranges_overlap(focused.x, focused.w, pane.x, pane.w)
                and ((d.sign < 0 and pane.y + pane.h <= focused.y) or (d.sign > 0 and pane.y >= focus_after_y))
            then
                return true
            end
        end
    end

    return false
end

-- Cheap precheck: does the emacs daemon socket exist? Avoids paying the
-- timeout+emacsclient fork cost when emacs isn't running.
local function emacs_daemon_running()
    local rt = os.getenv("XDG_RUNTIME_DIR")
    if not rt then return true end
    local f = io.open(rt .. "/emacs/server", "r")
    if f then f:close(); return true end
    return false
end

local function try_emacs(d)
    if not emacs_daemon_running() then return false end
    local expr = string.format(
        "(let ((target (window-in-direction '%s))) (when target (select-window target) t))",
        d.emacs)
    local cmd = emacs_cmd(expr)
    if not cmd then return false end
    local p = io.popen(cmd)
    if not p then return false end
    local first = p:read("*l")
    p:close()
    return first ~= nil and first:match("^t") ~= nil
end

local function send_terminal_shortcut(mods, d)
    -- send_shortcut inherits the current bind press state; from SUPER+arrow
    -- key-down it can leave the injected shortcut pressed in the newly
    -- focused pane.
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = d.key, state = "down", window = "activewindow" }))
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = d.key, state = "up", window = "activewindow" }))
end

local function move_hypr(d)
	ctx.layout.bind({
		hy3 = ctx.layout.hy3.moveFocus(d.hypr),
		default = hl.dsp.focus({ direction = d.hypr }),
	})()
end

ctx.smartFocus = function(direction)
    local d = DIRS[direction]
    if not d then return end

    local w = hl.get_active_window and hl.get_active_window()
    if not w then move_hypr(d); return end

    local class = w.class or ""
    local pid   = tonumber(w.pid) or 0

    local is_emacs_class = emacs_classes[class] == true
    local is_terminal    = terminal_classes[class] == true

    -- Pure emacs window: skip the descendant scan entirely.
    if hasEmacs and is_emacs_class then
        if try_emacs(d) then return end
        move_hypr(d); return
    end

    local has_tmux, has_zellij, has_emacs_proc, zellij_session = false, false, false, nil
    if is_terminal and pid > 0 then
        has_tmux, has_zellij, has_emacs_proc, zellij_session = scan_descendants(pid)
    end

    if hasEmacs and has_emacs_proc then
        if try_emacs(d) then return end
    end

    if is_terminal and has_zellij then
        local has_zellij_pane = zellij_has_pane_in_direction(zellij_session, d)
        if has_zellij_pane == false then move_hypr(d); return end

        send_terminal_shortcut(multiplexer_mod("zellij", "ALT"), d)
        return
    end

    if is_terminal and has_tmux then
        send_terminal_shortcut(multiplexer_mod("tmux", "CTRL"), d)
        return
    end

    move_hypr(d)
end

end

-- Directional focus router. Decides per-keypress whether a SUPER+arrow
-- should move focus inside emacs (window-in-direction), inside tmux
-- (CTRL+arrow sent to the active terminal), or to the next Hyprland
-- window. Exported as ctx.smartFocus.
--
-- Behaviour:
--   1. If active window is emacs-class, or a terminal with an emacs
--      descendant, try emacsclient --eval window-in-direction (~50ms cap).
--   2. Else if active is a terminal with tmux in its process tree,
--      dispatch sendshortcut "CTRL, <arrow>, activewindow" so tmux's
--      pane navigation handles the move.
--   3. Else fall back to plain `movefocus`.

return function(ctx)
local hl = ctx.hl
local hasEmacs = ctx.cfg.flags.emacs

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
    left  = { emacs = "left",  key = "left"  },
    right = { emacs = "right", key = "right" },
    up    = { emacs = "above", key = "up"    },
    down  = { emacs = "below", key = "down"  },
}

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

-- TTL cache for descendant scans. A held SUPER+arrow repeats ~50/sec;
-- without this, every repeat re-walks the same tree.
local scan_cache = {}
local SCAN_TTL = 2

-- BFS over the descendant tree; bail as soon as both flags are set,
-- and cap iterations so a runaway process tree can't stall the keypress.
local function scan_descendants(root_pid)
    if not root_pid or root_pid <= 0 then return false, false end
    local key = tostring(root_pid)
    local now = os.time()
    local cached = scan_cache[key]
    if cached and (now - cached.t) < SCAN_TTL then
        return cached.tmux, cached.emacs
    end

    local has_tmux, has_emacs = false, false
    local queue = { key }
    local seen = {}
    local steps = 0
    while #queue > 0 and steps < 500 do
        steps = steps + 1
        local pid = table.remove(queue, 1)
        if not seen[pid] then
            seen[pid] = true
            local comm = proc_comm(pid) or ""
            if not has_tmux  and comm:match("^tmux")  then has_tmux  = true end
            if not has_emacs and comm:match("^emacs") then has_emacs = true end
            if has_tmux and has_emacs then break end
            for _, c in ipairs(proc_children(pid)) do queue[#queue+1] = c end
        end
    end

    scan_cache[key] = { t = now, tmux = has_tmux, emacs = has_emacs }
    return has_tmux, has_emacs
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
    local cmd = string.format(
        "timeout 0.05s emacsclient --eval \"(let ((target (window-in-direction '%s))) (when target (select-window target) t))\" 2>/dev/null",
        d.emacs)
    local p = io.popen(cmd)
    if not p then return false end
    local first = p:read("*l")
    p:close()
    return first ~= nil and first:match("^t") ~= nil
end

local function send_tmux_shortcut(d)
    -- send_shortcut inherits the current bind press state; from SUPER+arrow
    -- key-down it can leave Ctrl+arrow pressed in the newly focused pane.
    hl.dispatch(hl.dsp.send_key_state({ mods = "CTRL", key = d.key, state = "down", window = "activewindow" }))
    hl.dispatch(hl.dsp.send_key_state({ mods = "CTRL", key = d.key, state = "up", window = "activewindow" }))
end

local function move_hypr(d)
    hl.dispatch(hl.dsp.focus({ direction = d.key }))
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

    local has_tmux, has_emacs_proc = false, false
    if is_terminal and pid > 0 then
        has_tmux, has_emacs_proc = scan_descendants(pid)
    end

    if hasEmacs and has_emacs_proc then
        if try_emacs(d) then return end
    end

    if is_terminal and has_tmux then
        send_tmux_shortcut(d)
        return
    end

    move_hypr(d)
end

end

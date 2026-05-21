-- ============================================================
-- HELPERS
-- ============================================================
-- Shared bind helpers exported through ctx for later modules.

return function(ctx)
local hl = ctx.hl
local mod = "SUPER"
ctx.mod = mod

-- Cheatsheet bind registry: every bind() / submap-entry call appends here,
-- and we serialize the table to JSON at the end of binds.lua so the
-- submap-cheatsheet UI can render binds without shelling out to hyprctl.
local cheatsheet = {}
local current_submap = ""
local current_reset = nil
ctx.cheatsheet = cheatsheet

local function push_cheatsheet(entry, opts)
    opts = opts or {}
    if opts.cheatsheet == false then return end
    cheatsheet[#cheatsheet + 1] = entry
end

--- bind(keys, action, desc, opts?) — lifts description out of the opts table.
local function bind(keys, action, desc, opts)
    opts = opts or {}
    local bind_opts = {}
    for key, value in pairs(opts) do
        bind_opts[key] = value
    end
    local show_cheatsheet = bind_opts.cheatsheet
    bind_opts.cheatsheet = nil
    bind_opts.description = desc
    if desc and not opts.mouse then
        push_cheatsheet({
            submap = current_submap,
            combo  = keys,
            action = desc,
        }, { cheatsheet = show_cheatsheet })
    end
    local bound = hl.bind(keys, action, bind_opts)
    if current_reset then
        hl.bind(keys, hl.dsp.submap(current_reset))
    end
    return bound
end

--- mbind(key, ...) — bind with mod prefix already applied.
local function mbind(key, action, desc, opts)
    return bind(mod .. " + " .. key, action, desc, opts)
end

--- bindSubmap(keys, target, desc, opts?) — bind that enters a submap; tagged so
--  the cheatsheet can list submap entry points distinctly.
local function bindSubmap(keys, target, desc, opts)
    opts = opts or {}
    push_cheatsheet({
        submap       = current_submap,
        combo        = keys,
        action       = desc,
        entersSubmap = true,
        targetSubmap = target,
    }, opts)
    return hl.bind(keys, hl.dsp.submap(target), { description = desc })
end

local function mbindSubmap(key, target, desc, opts)
    return bindSubmap(mod .. " + " .. key, target, desc, opts)
end

--- bindBack(target, desc?) — return to a parent submap without leaving modes.
local function bindBack(target, desc)
    desc = desc or "Back"
    push_cheatsheet({
        submap       = current_submap,
        combo        = "BackSpace",
        action       = desc,
        entersSubmap = true,
        targetSubmap = target,
    })
    return hl.bind("BackSpace", hl.dsp.submap(target), { description = desc })
end

--- submap(name, body, opts?) — normal binds are one-shot by default; submap
--  entry binds can still move to child submaps without being reset afterward.
local function submap(name, body, opts)
    opts = opts or {}
    local reset = opts.reset
    if reset == nil and opts.persistent ~= true then
        reset = "reset"
    end

    local function define_body()
        local prev = current_submap
        local prev_reset = current_reset
        current_submap = name
        current_reset = reset
        body()
        push_cheatsheet({
            submap       = name,
            combo        = "Escape",
            action       = "Exit submap",
            isEscapeExit = true,
        })
        hl.bind("escape", hl.dsp.submap("reset"))
        current_reset = prev_reset
        current_submap = prev
    end

    hl.define_submap(name, define_body)
end

-- ============================================================
-- MARK & SWAP
-- ============================================================
-- SUPER+X tags the active window as `marked` (thick orange border, sharp
-- corners — see the matching window_rule in rules.lua). Pressing again on
-- a different window swaps the two via hl.dsp.window.swap; on the marked
-- window itself, toggles the mark off.
local mark = { addr = nil, selector = nil }

local function window_selector(window)
    if not window or not window.address then return nil end
    return "address:" .. tostring(window.address)
end

local function window_workspace(window)
    return window and window.workspace and window.workspace.name or nil
end

local function window_matches(window, match)
    if type(match) == "function" then
        return match(window)
    end
    if not window or not match then return false end
    for key, pattern in pairs(match) do
        local value = window[key]
        if not value or not tostring(value):match(pattern) then
            return false
        end
    end
    return true
end

local function find_matching_window(match, workspace)
    local fallback = nil
    for _, window in ipairs(hl.get_windows() or {}) do
        if window_matches(window, match) then
            if window_workspace(window) == workspace then
                return window
            end
            fallback = fallback or window
        end
    end
    return fallback
end

local function open_special_app(spec)
    local workspace = "special:" .. spec.name
    local window = find_matching_window(spec.match, workspace)
    if window then
        if window_workspace(window) ~= workspace then
            local selector = window_selector(window)
            if selector then
                hl.dispatch(hl.dsp.window.move({ workspace = workspace, silent = true, window = selector }))
            end
        end
    elseif spec.cmd then
        hl.exec_cmd(spec.cmd, { workspace = workspace .. " silent" })
    end
    hl.dispatch(hl.dsp.workspace.toggle_special(spec.name))
end

local function find_window(addr)
    if not addr then return nil end
    for _, w in ipairs(hl.get_windows() or {}) do
        if w.address == addr then return w end
    end
    return nil
end

local function set_marked(window, on)
    hl.dispatch(hl.dsp.window.tag({
        tag = (on and "+marked" or "-marked"),
        window = window,
    }))
end

local function mark_or_swap()
    local active = hl.get_active_window and hl.get_active_window()
    if not active then return end
    local active_selector = window_selector(active)
    if not active_selector then return end

    if not mark.addr then
        mark.addr = active.address
        mark.selector = active_selector
        set_marked(active_selector, true)
        return
    end

    if mark.addr == active.address then
        set_marked(active_selector, false)
        mark.addr = nil
        mark.selector = nil
        return
    end

    local marked_win = find_window(mark.addr)
    if not marked_win then
        -- Marked window is gone; treat this press as a fresh mark.
        mark.addr = active.address
        mark.selector = active_selector
        set_marked(active_selector, true)
        return
    end

    hl.dispatch(hl.dsp.window.swap({ window = active_selector, target = mark.selector }))
    set_marked(mark.selector, false)
    mark.addr = nil
    mark.selector = nil
end
ctx.bind = bind
ctx.mbind = mbind
ctx.bindSubmap = bindSubmap
ctx.mbindSubmap = mbindSubmap
ctx.bindBack = bindBack
ctx.submap = submap
ctx.mark_or_swap = mark_or_swap
ctx.openSpecialApp = open_special_app

-- smart-focus.lua assigns this before binds.lua consumes it.
ctx.smartFocus = nil
end

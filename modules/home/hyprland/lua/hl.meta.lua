---@meta hl
---@diagnostic disable: lowercase-global, duplicate-set-field, missing-fields

-- Type stubs for Hyprland's 0.55+ Lua API. Loaded by lua-language-server
-- (via .luarc.json) so editor LSP and `lua-language-server --check` know
-- what hl.* members exist. NOT included in the rendered hyprland.lua —
-- lua.nix only reads the files listed in its `files` array.
--
-- Upstream reference:
--   https://github.com/hyprwm/Hyprland/blob/main/example/hyprland.lua
--   https://github.com/hyprwm/Hyprland/blob/main/meta/hl.meta.lua

---@class HlAction
local HlAction = {}

---@class HlWindow
---@field address string
---@field class string
---@field title string|nil
---@field initial_title string|nil
---@field pid integer|string
---@field workspace { name: string }|nil

---@class HlWorkspace
---@field name string

---@class HlMonitor
---@field name string
---@field position { x: integer, y: integer }

hl = {}

---@param keys string
---@param action HlAction
---@param opts table?
function hl.bind(keys, action, opts) end

---@param t table
function hl.config(t) end

---@param t table
function hl.window_rule(t) end

---@param t table
function hl.workspace_rule(t) end

---@param t table
function hl.layer_rule(t) end

---@param t table
function hl.gesture(t) end

---@param name string
---@param t table
function hl.curve(name, t) end

---@param t table
function hl.animation(t) end

---@param k string
---@param v string
function hl.env(k, v) end

---@param t table
function hl.monitor(t) end

---@param action HlAction
function hl.dispatch(action) end

---@param cmd string
---@param opts table?
function hl.exec_cmd(cmd, opts) end

---@param opts table?
---@return HlWindow[]
function hl.get_windows(opts) end

---@return HlWindow|nil
function hl.get_active_window() end

---@return HlWorkspace|nil
function hl.get_last_workspace() end

---@return HlMonitor[]
function hl.get_monitors() end

---@param name string
---@param reset string
---@param body fun()
function hl.define_submap(name, reset, body) end

---@param event string
---@param handler fun(arg: any)
function hl.on(event, handler) end

hl.dsp = {}

---@param cmd string
---@return HlAction
function hl.dsp.exec_cmd(cmd) end

---@param name string
---@return HlAction
function hl.dsp.submap(name) end

---@param arg string
---@return HlAction
function hl.dsp.layout(arg) end

---@param arg string
---@return HlAction
function hl.dsp.global(arg) end

---@param opts table
---@return HlAction
function hl.dsp.focus(opts) end

---@param opts table
---@return HlAction
function hl.dsp.send_shortcut(opts) end

---@param opts table
---@return HlAction
function hl.dsp.send_key_state(opts) end

hl.dsp.workspace = {}

---@param name string?
---@return HlAction
function hl.dsp.workspace.toggle_special(name) end

---@param opts table
---@return HlAction
function hl.dsp.workspace.move(opts) end

hl.dsp.window = {}

---@param opts table?
---@return HlAction
function hl.dsp.window.move(opts) end

---@param opts table?
---@return HlAction
function hl.dsp.window.resize(opts) end

---@return HlAction
function hl.dsp.window.close() end

---@param opts table?
---@return HlAction
function hl.dsp.window.float(opts) end

---@param opts table?
---@return HlAction
function hl.dsp.window.fullscreen(opts) end

---@param opts table
---@return HlAction
function hl.dsp.window.fullscreen_state(opts) end

---@return HlAction
function hl.dsp.window.pin() end

---@return HlAction
function hl.dsp.window.drag() end

---@param opts table
---@return HlAction
function hl.dsp.window.swap(opts) end

---@param opts table
---@return HlAction
function hl.dsp.window.tag(opts) end

hl.dsp.group = {}

---@return HlAction
function hl.dsp.group.toggle() end

---@return HlAction
function hl.dsp.group.next() end

---@return HlAction
function hl.dsp.group.prev() end

---@param opts table
---@return HlAction
function hl.dsp.group.lock_active(opts) end

---@param opts table
---@return HlAction
function hl.dsp.group.active(opts) end

---@class HlCfg
---@field terminalCommands { main: string, dropdown: string, pinned: string }
---@field browser string
---@field privateBrowser string
---@field passManager string
---@field locker string
---@field volumeMixer string
---@field hyprpicker string
---@field noctalia string
---@field submapCheatsheet string
---@field submapCheatsheetToggle string
---@field screenshot { fullscreen: string, region: string, window: string }
---@field primary { output: string, selector: string, wideColor: boolean }
---@field monitorWorkspace { enable: boolean, target: string, workspaces: string[] }
---@field flags { gaming: boolean, bloat: boolean, zsa: boolean, emacs: boolean, haPresence: boolean }
---@field sunshine { enable: boolean, virtualMonitor: string, virtualMode: string, virtualPosition: string, virtualScale: string, steamWorkspace: string, gameWorkspace: string }
---@field theme { gaps_in: integer, gaps_out: integer, rounding: integer }
---@field colors table<string, string>
cfg = {}

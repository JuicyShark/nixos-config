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

---@class HlRule
local HlRule = {}

---@param enabled boolean
function HlRule:set_enabled(enabled) end

---@return boolean
function HlRule:is_enabled() end

---@class HlWindow
---@field address string
---@field class string
---@field title string|nil
---@field initial_title string|nil
---@field pid integer|string
---@field workspace { name: string }|nil

---@class HlWorkspace
---@field name string
---@field tiled_layout string

---@class HlMonitor
---@field name string
---@field position { x: integer, y: integer }

hl = {}

hl.plugin = {
    hyprbars = {},
    hy3 = {},
}

---@param keys string
---@param action HlAction
---@param opts table?
function hl.bind(keys, action, opts) end

---@param t table
function hl.config(t) end

---@param t table
function hl.plugin.hyprbars.add_button(t) end

---@param arg string
---@param opts table?
---@return HlAction
function hl.plugin.hy3.move_focus(arg, opts) end

---@param arg string
---@param opts table?
---@return HlAction
function hl.plugin.hy3.move_window(arg, opts) end

---@param arg string
---@param opts table?
---@return HlAction
function hl.plugin.hy3.make_group(arg, opts) end

---@param arg string
---@return HlAction
function hl.plugin.hy3.change_group(arg) end

---@param t table
---@return HlRule
function hl.window_rule(t) end

---@param t table
function hl.workspace_rule(t) end

---@param t table
---@return HlRule
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

---@return HlWorkspace|nil
function hl.get_active_workspace() end

---@return HlWorkspace|nil
function hl.get_active_special_workspace() end

---@return HlMonitor[]
function hl.get_monitors() end

---@return string
function hl.get_current_submap() end

---@param name string
---@param reset_or_body string|fun()
---@param body fun()?
function hl.define_submap(name, reset_or_body, body) end

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

---@param opts table?
---@return HlAction
function hl.dsp.window.pseudo(opts) end

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
---@field apps { terminal: string, nvim: string, tmux: string, zellij: string, timeout: string, yazi: string, emacsclient: string, thunar: string, elephant: string, walker: string, noctalia: string, qutebrowser: string, vivaldi: string|nil, pwvucontrol: string, hyprpicker: string, wayscriber: string, jellyfinMpvShim: string }
---@field scripts { submapCheatsheet: string, submapCheatsheetCall: string }
---@field hyprctl string
---@field uwsmAppPrefix string
---@field screenshot { fullscreen: string, region: string, window: string }
---@field features { gaming: boolean, bloat: boolean, zsa: boolean, emacs: boolean, neovim: boolean, tmux: boolean }
---@field smartFocus { keys: { left: string, right: string, up: string, down: string }, multiplexers: { tmux: { mod: string }, zellij: { mod: string } } }
---@field sunshine { enable: boolean, virtualMonitor: string, virtualMode: string, virtualPosition: string, virtualScale: string, steamWorkspace: string, gameWorkspace: string }
cfg = {}

---@class HyprCommands
---@field app fun(cmd: string): string
---@field browser string
---@field privateBrowser string
---@field terminal { main: string, dropdown: string, pinned: string }
---@field files { emacs: string, thunar: string, yazi: string }
---@field emacs { raise: string, focusOrRaise: string, newFrame: string, cwd: string, capture: string, today: string, agenda: string, projects: string, weeklyReview: string, roamFind: string, roamCapture: string, roamSearch: string }
---@field walker { launcher: string, commands: string, clipboard: string, bitwarden: string, windows: string, service: string }
---@field autostart { elephant: string, noctalia: string, submapCheatsheet: string, wayscriber: string, jellyfinMpvShim: string }
---@field screenshot { fullscreen: string, region: string, window: string }
---@field volumeMixer string
---@field hyprpicker string
---@field notifications { clearActive: string }
---@field media { toggle: string, previous: string, next: string, stop: string }
---@field session { lock: string, logout: string, reboot: string, shutdown: string }
---@field volume { up: string, down: string, mute: string }
---@field noctaliaLauncher string
---@field noctalia string
---@field submapCheatsheetCall string

---@class HyprBindHelpers
---@field mod string
---@field bind fun(keys: string, action: HlAction|fun(), desc: string?, opts: table?)
---@field mbind fun(key: string, action: HlAction|fun(), desc: string?, opts: table?)
---@field bindSubmap fun(keys: string, target: string, desc: string, opts: table?)
---@field mbindSubmap fun(key: string, target: string, desc: string, opts: table?)
---@field bindBack fun(target: string, desc: string?)
---@field defineSubmap fun(name: string, body: fun(), opts: table?)
---@field toggleOptions fun()
---@field writeCheatsheet fun()
---@field entrySubmaps fun(bind_fn: fun(key: string, target: string, desc: string, opts: table?))
---@field walkerSubmap fun()
---@field groupSubmap fun()

---@class HyprCheatsheet
---@field reset fun(): string|nil
---@field withSubmap fun(name: string, reset: string|nil, body: fun())
---@field recordBind fun(keys: string, desc: string?, opts: table?)
---@field recordSubmap fun(keys: string, target: string, desc: string, opts: table?)
---@field recordExit fun()
---@field show fun(name: string)
---@field hide fun()
---@field toggleOptions fun()
---@field write fun()

---@class HyprDesktopPolicy
---@field mod string
---@field primary { output: string, selector: string, wideColor: boolean }
---@field monitorWorkspace { enable: boolean, target: string, workspaces: string[] }

{
  osConfig,
  config,
  commands,
  lib,
}: let
  inherit (lib) all filterAttrs mapAttrs optionals optionalString;
  toLua = lib.generators.toLua {};
  inline = lib.generators.mkLuaInline;

  mod = "SUPER";
  hasTvProfile = config.modules.desktop.hyprland.tvMonitor != "" && config.modules.desktop.hyprland.primaryMonitor != "";
  standardKeyboard = config.modules.desktop.hyprland.keyboard == "standard";
  hasApplications = osConfig.modules.desktop.applications.enable or false;
  hasGaming = osConfig.modules.desktop.gaming.enable or false;
  hasCouchMode = commands.couchModeEnter != "";
  hasZellij = config.programs.zellij.enable or false;

  helperKeys = ["reset" "hidden" "noReset" "entersSubmap"];
  stripHelperOpts = opts: builtins.removeAttrs opts helperKeys;
  bindOpts = desc: opts:
    stripHelperOpts opts
    // {
      description = optionalString (opts.hidden or false) "[hidden] " + desc;
    };
  runtimeOptKeys = ["reset"];
  runtimeOpts = opts:
    filterAttrs (name: value: value != null && builtins.elem name runtimeOptKeys) opts;

  guarded = action: opts: let
    opts' = runtimeOpts opts;
  in
    inline "Juicy.dispatch.bind(${action}, ${toLua opts'})";
  layout = actions: _opts: opts:
    inline "Juicy.dispatch.layout(${actions}, ${toLua (runtimeOpts opts)})";
  luaFn = body: "function()\n${body}\nend";
  luaAction = body: _opts: opts: guarded (luaFn body) opts;
  focusOrSpawn = match: command: _opts: opts:
    guarded "Juicy.dispatch.focusOrSpawn(${toLua match}, ${toLua command})" opts;
  exec = command: _opts: opts: guarded "hl.dsp.exec_cmd(${toLua command})" opts;
  dsp = expr: _opts: opts: guarded expr opts;
  enter = target: _opts: opts: guarded "hl.dsp.submap(${toLua target})" opts;
  reset = _opts: opts: dsp ''hl.dsp.submap("reset")'' {} opts;

  mkBind = combo: desc: action: opts: {
    inherit combo desc action opts;
  };
  bind = combo: desc: action: opts: mkBind combo desc action opts;
  mbind = combo: desc: action: opts: mkBind "${mod} + ${combo}" desc action opts;
  submapEntry = combo: target: desc: opts:
    mkBind combo desc (enter target opts) (opts
      // {
        entersSubmap = true;
      });

  renderBind = entry: {
    _args = [
      entry.combo
      (entry.action entry.opts)
      (bindOpts entry.desc entry.opts)
    ];
  };

  navCore = {
    allow_input_capture = true;
    submap_universal = true;
  };
  navCoreHidden =
    navCore
    // {
      hidden = true;
    };
  navRepeat =
    navCore
    // {
      repeating = true;
    };

  resetBind = {
    combo = "Escape";
    desc = "Exit submap";
    action = reset {};
    opts = {
      reset = null;
    };
  };

  withReset = entries:
    map (entry:
      entry
      // {
        opts =
          entry.opts
          // lib.optionalAttrs (! (entry.opts.entersSubmap or false) && ! (entry.opts.noReset or false)) {
            reset = "reset";
          };
      })
    entries;

  nativeOnDispatchReset = entries:
    entries
    != []
    && all (entry: ! (entry.opts.entersSubmap or false) && ! (entry.opts.noReset or false)) entries;
  withoutRuntimeReset = entry:
    entry
    // {
      opts = entry.opts // {reset = null;};
    };
  nativeResetEntries = entries:
    if nativeOnDispatchReset entries
    then map withoutRuntimeReset entries
    else entries;
  hmSubmap = entries: {
    onDispatch = optionalString (nativeOnDispatchReset entries) "reset";
    settings.bind = map renderBind (nativeResetEntries (entries ++ [resetBind]));
  };

  entrySubmaps =
    [
      {
        key = "W";
        target = "window";
        desc = "Windows";
      }
      {
        key = "Tab";
        target = "apps";
        desc = "Apps";
      }
      {
        key = "L";
        target = "layout";
        desc = "Layout";
      }
      {
        key = "G";
        target = "group";
        desc = "Groups";
      }
      {
        key = "bracketleft";
        target = "system";
        desc = "System";
      }
      {
        key = "V";
        target = "media";
        desc = "Media";
      }
      {
        key = "S";
        target = "state";
        desc = "State";
      }
    ]
    ++ optionals hasZellij [
      {
        key = "T";
        target = "zellij";
        desc = "Zellij";
      }
    ];

  workspaceLabels = {
    "2" = "Web";
    "3" = "Social";
    "5" = "Game";
  };
  workspaceBinds = builtins.concatLists (map (i: let
      key = toString i;
      workspace = toString i;
      label = workspaceLabels.${workspace} or "Workspace ${key}";
    in [
      (mbind key label (dsp "hl.dsp.focus({ workspace = ${toLua workspace} })" navCore) navCore)
      (mbind "SHIFT + ${key}" "Move to ${label}" (dsp "hl.dsp.window.move({ workspace = ${toLua workspace}, follow = false })" {}) {})
    ])
    [1 2 3 4 5 6 7 8 9]);

  topLevel =
    [
      (bind "${mod} + mouse:272" "Move window" (dsp "hl.dsp.window.drag()" {mouse = true;}) {mouse = true;})
      (bind "${mod} + mouse:273" "Resize window" (dsp "hl.dsp.window.resize()" {mouse = true;}) {mouse = true;})
      (bind "${mod} + mouse_up" "Scroll layout left" (layout ''{ scrolling = hl.dsp.layout("move -200") }'' {mouse = true;}) {mouse = true;})
      (bind "${mod} + mouse_down" "Scroll layout right" (layout ''{ scrolling = hl.dsp.layout("move +200") }'' {mouse = true;}) {mouse = true;})
    ]
    ++ optionals standardKeyboard [
      (mbind "ALT + left" "Shrink width" (dsp ''hl.dsp.window.resize({ x = -40, y = 0, relative = true })'' navRepeat) navRepeat)
      (mbind "ALT + right" "Grow width" (dsp ''hl.dsp.window.resize({ x = 40, y = 0, relative = true })'' navRepeat) navRepeat)
      (mbind "ALT + up" "Shrink height" (dsp ''hl.dsp.window.resize({ x = 0, y = -40, relative = true })'' navRepeat) navRepeat)
      (mbind "ALT + down" "Grow height" (dsp ''hl.dsp.window.resize({ x = 0, y = 40, relative = true })'' navRepeat) navRepeat)
      (mbind "equal" "Grow column / master" (layout ''{ scrolling = hl.dsp.layout("colresize +conf"), master = hl.dsp.layout("mfact +0.05") }'' navRepeat) navRepeat)
    ]
    ++ map (entry: submapEntry "${mod} + ${entry.key}" entry.target entry.desc {}) entrySubmaps
    ++ [
      (submapEntry "${mod} + A" "apps" "Apps" {})
      (mbind "Space" "Launcher" (exec commands.launcher {}) {})
      (mbind "C" "Clipboard history" (exec commands.clipboard {}) {})
      (mbind "SHIFT + slash" "Submap options" (dsp ''hl.dsp.submap("submap-options")'' {}) {})
      (mbind "SHIFT + Q" "Close" (dsp "hl.dsp.window.close()" {}) {})
      (submapEntry "${mod} + ALT + BackSpace" "state" "State" navCore)
      (mbind "left" "Focus left" (luaAction ''Juicy.smartFocus("left")'' navCoreHidden) navCoreHidden)
      (mbind "CONTROL + ALT + left" "Focus Hyprland left" (dsp ''hl.dsp.focus({ direction = "left" })'' navCore) navCore)
      (mbind "SHIFT + left" "Move left" (dsp ''hl.dsp.window.move({ direction = "l" })'' {}) {})
      (mbind "CONTROL + left" "Layout left / previous monocle window" (layout ''{ dwindle = hl.dsp.layout("preselect l"), master = hl.dsp.layout("orientationleft"), scrolling = hl.dsp.layout("move -col"), monocle = hl.dsp.layout("cycleprev") }'' navCore) navCore)
      (mbind "ALT + SHIFT + left" "Resize left" (dsp ''hl.dsp.window.resize({ x = 75, y = 0, relative = true })'' navRepeat) navRepeat)
      (mbind "right" "Focus right" (luaAction ''Juicy.smartFocus("right")'' navCoreHidden) navCoreHidden)
      (mbind "CONTROL + ALT + right" "Focus Hyprland right" (dsp ''hl.dsp.focus({ direction = "right" })'' navCore) navCore)
      (mbind "SHIFT + right" "Move right" (dsp ''hl.dsp.window.move({ direction = "r" })'' {}) {})
      (mbind "CONTROL + right" "Layout right / next monocle window" (layout ''{ dwindle = hl.dsp.layout("preselect r"), master = hl.dsp.layout("orientationright"), scrolling = hl.dsp.layout("move +col"), monocle = hl.dsp.layout("cyclenext") }'' navCore) navCore)
      (mbind "ALT + SHIFT + right" "Resize right" (dsp ''hl.dsp.window.resize({ x = -75, y = 0, relative = true })'' navRepeat) navRepeat)
      (mbind "up" "Focus up" (luaAction ''Juicy.smartFocus("up")'' navCoreHidden) navCoreHidden)
      (mbind "CONTROL + ALT + up" "Focus Hyprland up" (dsp ''hl.dsp.focus({ direction = "up" })'' navCore) navCore)
      (mbind "SHIFT + up" "Move up" (dsp ''hl.dsp.window.move({ direction = "u" })'' {}) {})
      (mbind "CONTROL + up" "Layout up / promote" (layout ''{ dwindle = hl.dsp.layout("preselect u"), master = hl.dsp.layout("orientationcenter"), scrolling = hl.dsp.layout("promote") }'' navCore) navCore)
      (mbind "ALT + SHIFT + up" "Resize up" (dsp ''hl.dsp.window.resize({ x = 0, y = -75, relative = true })'' navRepeat) navRepeat)
      (mbind "down" "Focus down" (luaAction ''Juicy.smartFocus("down")'' navCoreHidden) navCoreHidden)
      (mbind "CONTROL + ALT + down" "Focus Hyprland down" (dsp ''hl.dsp.focus({ direction = "down" })'' navCore) navCore)
      (mbind "SHIFT + down" "Move down" (dsp ''hl.dsp.window.move({ direction = "d" })'' {}) {})
      (mbind "CONTROL + down" "Layout down / expel" (layout ''{ dwindle = hl.dsp.layout("preselect d"), master = hl.dsp.layout("orientationcenter"), scrolling = hl.dsp.layout("expel") }'' navCore) navCore)
      (mbind "ALT + SHIFT + down" "Resize down" (dsp ''hl.dsp.window.resize({ x = 0, y = 75, relative = true })'' navRepeat) navRepeat)
      (mbind "Page_Up" "Previous workspace" (dsp ''hl.dsp.focus({ workspace = "r-1" })'' navCore) navCore)
      (mbind "Page_Down" "Next workspace" (dsp ''hl.dsp.focus({ workspace = "r+1" })'' navCore) navCore)
      (mbind "SHIFT + Page_Up" "Move to previous workspace" (dsp ''hl.dsp.window.move({ workspace = "r-1", follow = false })'' navCore) navCore)
      (mbind "SHIFT + Page_Down" "Move to next workspace" (dsp ''hl.dsp.window.move({ workspace = "r+1", follow = false })'' navCore) navCore)
      (mbind "Home" "Previous workspace" (dsp ''hl.dsp.focus({ workspace = "previous_per_monitor" })'' navCore) navCore)
      (mbind "Return" "Terminal" (luaAction "Juicy.terminal.open()" {}) {})
      (mbind "CONTROL + Return" "Neovim project window" (luaAction ''
        if not Juicy.openNvimWindow() then
          error("Focus a responsive Neovim pane to open its project in a new window", 0)
        end
      '' {}) {})
    ]
    ++ workspaceBinds
    ++ [
      (mbind "0" "Workspace 10" (dsp ''hl.dsp.focus({ workspace = "10" })'' navCore) navCore)
      (mbind "SHIFT + 0" "Move to ws 10" (dsp ''hl.dsp.window.move({ workspace = "10", follow = false })'' {}) {})
      (mbind "minus" "Master ratio -" (layout ''{ master = hl.dsp.layout("mfact -0.05") }'' {repeating = true;}) {repeating = true;})
      (mbind "SHIFT + minus" "Master ratio --" (layout ''{ master = hl.dsp.layout("mfact -0.125") }'' {repeating = true;}) {repeating = true;})
      (mbind "plus" "Master ratio +" (layout ''{ master = hl.dsp.layout("mfact +0.05") }'' {repeating = true;}) {repeating = true;})
      (mbind "SHIFT + plus" "Master ratio ++" (layout ''{ master = hl.dsp.layout("mfact +0.125") }'' {repeating = true;}) {repeating = true;})
      (bind "XF86AudioRaiseVolume" "Volume up" (exec commands.volumeUp {
          allow_input_capture = true;
          repeating = true;
          submap_universal = true;
        }) {
          allow_input_capture = true;
          repeating = true;
          submap_universal = true;
        })
      (bind "XF86AudioLowerVolume" "Volume down" (exec commands.volumeDown {
          allow_input_capture = true;
          repeating = true;
          submap_universal = true;
        }) {
          allow_input_capture = true;
          repeating = true;
          submap_universal = true;
        })
      (bind "XF86AudioForward" "Seek +10s" (exec commands.mediaSeekForward {
          allow_input_capture = true;
          repeating = true;
          submap_universal = true;
        }) {
          allow_input_capture = true;
          repeating = true;
          submap_universal = true;
        })
      (bind "XF86AudioRewind" "Seek -10s" (exec commands.mediaSeekBackward {
          allow_input_capture = true;
          repeating = true;
          submap_universal = true;
        }) {
          allow_input_capture = true;
          repeating = true;
          submap_universal = true;
        })
      (bind "XF86AudioPrev" "Previous track" (exec commands.mediaPrevious {
          allow_input_capture = true;
          locked = true;
          submap_universal = true;
        }) {
          allow_input_capture = true;
          locked = true;
          submap_universal = true;
        })
      (bind "XF86AudioNext" "Next track" (exec commands.mediaNext {
          allow_input_capture = true;
          locked = true;
          submap_universal = true;
        }) {
          allow_input_capture = true;
          locked = true;
          submap_universal = true;
        })
      (bind "XF86AudioPlay" "Play" (exec commands.mediaToggle {
          allow_input_capture = true;
          locked = true;
          submap_universal = true;
        }) {
          allow_input_capture = true;
          locked = true;
          submap_universal = true;
        })
      (bind "XF86AudioPause" "Pause" (exec commands.mediaToggle {
          allow_input_capture = true;
          locked = true;
          submap_universal = true;
        }) {
          allow_input_capture = true;
          locked = true;
          submap_universal = true;
        })
      (submapEntry "XF86AudioMedia" "media" "Media" {
        allow_input_capture = true;
        locked = true;
        submap_universal = true;
      })
      (bind "XF86Messenger" "Special workspace" (dsp "hl.dsp.workspace.toggle_special()" {locked = true;}) {locked = true;})
    ]
    ++ optionals hasCouchMode [
      (bind "F13" "Enter couch mode" (exec commands.couchModeEnter {
          allow_input_capture = true;
          submap_universal = true;
        }) {
          allow_input_capture = true;
          submap_universal = true;
        })
      (bind "F14" "Exit couch mode" (exec commands.couchModeExit {
          allow_input_capture = true;
          submap_universal = true;
        }) {
          allow_input_capture = true;
          submap_universal = true;
        })
    ];

  submaps =
    {
      "submap-options" = withReset (map (entry: submapEntry entry.key entry.target entry.desc {}) entrySubmaps);
      apps =
        withReset
        ([
            (bind "Return" "Terminal" (luaAction "Juicy.terminal.open()" {}) {})
            (bind "W" "Web Browser" (exec commands.browser {}) {})
          ]
          ++ optionals (commands.qutebrowser != "") [
            (bind "CONTROL + W" "Qutebrowser" (exec commands.qutebrowser {}) {})
          ]
          ++ [
            (bind "SHIFT + W" "Private Browser" (exec commands.privateBrowser {hidden = true;}) {hidden = true;})
            (bind "CONTROL + F" "Yazi" (focusOrSpawn {title = "^[Yy]azi(: .*)?$";} commands.yazi {hidden = true;}) {hidden = true;})
            (bind "Y" "Yazi" (focusOrSpawn {title = "^[Yy]azi(: .*)?$";} commands.yazi {}) {})
            (bind "S" "Screenshot" (exec commands.screenshotRegion {}) {})
          ]
          ++ optionals hasApplications [
            (bind "D" "Discord" (focusOrSpawn {class = "^(discord|vesktop)$";} commands.discord {}) {})
          ]
          ++ optionals hasGaming [
            (bind "CONTROL + G" "Steam" (focusOrSpawn {
                class = "^steam$";
                initial_title = "^Steam$";
              }
              commands.steam {}) {})
          ]
          ++ optionals hasApplications [
            (bind "M" "Music" (focusOrSpawn {class = "^tidal-hifi$";} commands.music {}) {})
          ]
          ++ [
            (bind "Space" "Launcher" (exec commands.launcher {}) {})
            (bind "V" "Volume Mixer" (focusOrSpawn {class = "^(pwvucontrol|com.saivert.pwvucontrol)$";} commands.volumeMixer {}) {})
          ]
          ++ optionals hasZellij [
            (submapEntry "T" "zellij" "Zellij" {})
          ]);

      group = withReset (
        [
          (bind "left" "Group previous" (dsp "hl.dsp.group.prev()" {repeating = true;}) {repeating = true;})
          (bind "right" "Group next" (dsp "hl.dsp.group.next()" {repeating = true;}) {repeating = true;})
          (bind "SHIFT + left" "Group into left" (dsp ''hl.dsp.window.move({ into_or_create_group = "l" })'' {}) {})
          (bind "SHIFT + right" "Group into right" (dsp ''hl.dsp.window.move({ into_or_create_group = "r" })'' {}) {})
          (bind "R" "Group previous" (dsp "hl.dsp.group.prev()" {
              repeating = true;
              hidden = true;
            }) {
              repeating = true;
              hidden = true;
            })
          (bind "T" "Group next" (dsp "hl.dsp.group.next()" {
              repeating = true;
              hidden = true;
            }) {
              repeating = true;
              hidden = true;
            })
          (bind "G" "Toggle group" (dsp "hl.dsp.group.toggle()" {}) {})
          (bind "L" "Lock group" (dsp ''hl.dsp.group.lock_active({ action = "toggle" })'' {}) {})
          (bind "U" "Ungroup active" (dsp "hl.dsp.window.move({ out_of_group = true })" {}) {})
        ]
        ++ map (tab:
          bind (toString tab) "Focus group ${toString tab}" (dsp "hl.dsp.group.active({ index = ${toString tab} })" {}) {
            hidden = tab > 3;
          }) [1 2 3 4 5 6 7 8 9]
      );

      layout = withReset [
        (bind "M" "Master Layout" (luaAction ''Juicy.layout.setCurrentLayout("master")'' {}) {})
        (bind "D" "Dwindle Layout" (luaAction ''Juicy.layout.setCurrentLayout("dwindle")'' {}) {})
        (bind "S" "Scrolling Layout" (luaAction ''Juicy.layout.setCurrentLayout("scrolling")'' {}) {})
        (bind "O" "Monocle Layout" (luaAction ''Juicy.layout.setCurrentLayout("monocle")'' {}) {})
        (submapEntry "CONTROL + S" "scrolling" "Scrolling Actions" {})
        (submapEntry "W" "window" "Window Actions" {})
        (submapEntry "G" "group" "Group Actions" {})
        (bind "SHIFT + O" "Master ratio 50%" (layout ''{ master = hl.dsp.layout("mfact exact 0.5") }'' {}) {})
        (bind "U" "Master ratio 65%" (layout ''{ master = hl.dsp.layout("mfact exact 0.65") }'' {}) {})
        (bind "left" "Orient left / previous monocle window" (layout ''{ master = hl.dsp.layout("orientationleft"), monocle = hl.dsp.layout("cycleprev") }'' {}) {})
        (bind "up" "Orient center" (layout ''{ master = hl.dsp.layout("orientationcenter") }'' {}) {})
        (bind "right" "Orient right / next monocle window" (layout ''{ master = hl.dsp.layout("orientationright"), monocle = hl.dsp.layout("cyclenext") }'' {}) {})
        (bind "N" "Global gapless preset" (luaAction "Juicy.layout.gaplessPreset()" {}) {})
        (bind "P" "Global default preset" (luaAction "Juicy.layout.defaultPreset()" {}) {})
      ];

      scrolling = withReset [
        (submapEntry "BackSpace" "layout" "Back to layout" {})
        (bind "left" "Previous column" (layout ''{ scrolling = hl.dsp.layout("move -col") }'' {}) {})
        (bind "right" "Next column" (layout ''{ scrolling = hl.dsp.layout("move +col") }'' {}) {})
        (bind "bracketright" "Grow column" (layout ''{ scrolling = hl.dsp.layout("colresize +conf") }'' {}) {})
        (bind "bracketleft" "Shrink column" (layout ''{ scrolling = hl.dsp.layout("colresize -conf") }'' {}) {})
        (bind "F" "Fit visible" (layout ''{ scrolling = hl.dsp.layout("fit visible") }'' {}) {})
        (bind "SHIFT + F" "Fit all" (layout ''{ scrolling = hl.dsp.layout("fit all") }'' {}) {})
        (bind "A" "Fit active" (layout ''{ scrolling = hl.dsp.layout("fit active") }'' {}) {})
        (bind "Home" "Fit start" (layout ''{ scrolling = hl.dsp.layout("fit tobeg") }'' {}) {})
        (bind "End" "Fit end" (layout ''{ scrolling = hl.dsp.layout("fit toend") }'' {}) {})
        (bind "CONTROL + P" "Promote to column" (layout ''{ scrolling = hl.dsp.layout("promote") }'' {}) {})
        (bind "SHIFT + P" "Promote to column" (layout ''{ scrolling = hl.dsp.layout("promote") }'' {hidden = true;}) {hidden = true;})
        (bind "E" "Expel to column" (layout ''{ scrolling = hl.dsp.layout("expel") }'' {}) {})
        (bind "B" "Consume or expel previous" (layout ''{ scrolling = hl.dsp.layout("consume_or_expel prev") }'' {}) {})
        (bind "V" "Consume or expel next" (layout ''{ scrolling = hl.dsp.layout("consume_or_expel next") }'' {}) {})
        (bind "I" "Toggle scroll lock" (layout ''{ scrolling = hl.dsp.layout("inhibit_scroll") }'' {}) {})
        (bind "Y" "Toggle fit" (layout ''{ scrolling = hl.dsp.layout("togglefit") }'' {}) {})
        (bind "C" "Global centered focus" (layout ''{ scrolling = function() Juicy.layout.toggleCenteredFocus() end }'' {}) {})
      ];

      media = withReset [
        (bind "Space" "Play pause" (exec commands.mediaToggle {}) {})
        (bind "P" "Previous track" (exec commands.mediaPrevious {}) {})
        (bind "N" "Next track" (exec commands.mediaNext {}) {})
        (bind "left" "Seek -10s" (exec commands.mediaSeekBackward {}) {})
        (bind "right" "Seek +10s" (exec commands.mediaSeekForward {}) {})
        (bind "minus" "Volume down" (exec commands.volumeDown {}) {})
        (bind "plus" "Volume up" (exec commands.volumeUp {}) {})
        (bind "M" "Toggle mute" (exec commands.volumeMute {}) {})
        (bind "V" "Volume Mixer" (focusOrSpawn {class = "^(pwvucontrol|com.saivert.pwvucontrol)$";} commands.volumeMixer {}) {})
      ];

      displays = withReset (optionals hasTvProfile [
        (submapEntry "BackSpace" "state" "Back to state" {})
        (bind "S" "Solo monitor" (luaAction "Juicy.monitors.solo()" {}) {})
        (bind "V" "Mirror TV" (luaAction ''Juicy.monitors.setProfile("mirror")'' {}) {})
        (bind "M" "Extend to TV" (luaAction ''Juicy.monitors.setProfile("extended")'' {}) {})
      ]);

      state = withReset (optionals hasTvProfile [(submapEntry "M" "displays" "Displays" {})]
        ++ [
          (bind "D" "Toggle do not disturb" (exec commands.dndToggle {}) {})
          (submapEntry "P" "passthrough" "Passthrough mode" {noReset = true;})
        ]);

      passthrough = [
        (bind "${mod} + ALT + BackSpace" "Exit passthrough" (dsp ''hl.dsp.submap("reset")'' {
            allow_input_capture = true;
            submap_universal = true;
          }) {
            allow_input_capture = true;
            submap_universal = true;
          })
      ];

      system =
        withReset
        ([
            (bind "N" "Clear notifs" (exec commands.clearNotifications {}) {})
            (bind "S" "Screenshot (region)" (exec commands.screenshotRegion {}) {})
            (bind "CONTROL + S" "Screenshot (full)" (exec commands.screenshotFullscreen {}) {})
            (bind "SHIFT + S" "Screenshot (full)" (exec commands.screenshotFullscreen {hidden = true;}) {hidden = true;})
          ]
          ++ [
            (bind "C" "Color picker" (exec commands.colorPicker {}) {})
            (bind "L" "Lock" (exec commands.lock {}) {})
            (bind "CONTROL + O" "Logout" (exec commands.logout {}) {})
            (bind "SHIFT + O" "Logout" (exec commands.logout {hidden = true;}) {hidden = true;})
            (submapEntry "R" "confirmSystem" "Reboot" {})
            (submapEntry "X" "confirmSystem" "Shutdown" {})
          ]);

      confirmSystem = withReset [
        (submapEntry "BackSpace" "system" "Back to system" {})
        (bind "R" "Reboot, NOW!!" (exec commands.reboot {}) {})
        (bind "X" "Shutdown, NOW!!" (exec commands.shutdown {}) {})
      ];

      window = withReset (
        [
          (bind "M" "Fake fullscreen over maximize" (dsp ''hl.dsp.window.fullscreen_state({ internal = 0, client = 2, action = "toggle" })'' {}) {})
          (bind "CONTROL + M" "Toggle fullscreen" (dsp ''hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" })'' {}) {})
        ]
        ++ optionals hasCouchMode [
          (bind "CONTROL + SHIFT + M" "Toggle HDMI display" (exec commands.hdmiToggle {}) {})
        ]
        ++ [
          (bind "F" "Toggle floating" (dsp ''hl.dsp.window.float({ action = "toggle" })'' {}) {})
          (bind "P" "Picture in picture" (luaAction "Juicy.dispatch.togglePip()" {}) {})
          (bind "S" "Swap split" (dsp ''hl.dsp.layout("swapsplit")'' {}) {})
          (submapEntry "G" "group" "Groups" {})
        ]
      );
    }
    // lib.optionalAttrs hasZellij {
      zellij = withReset [
        (bind "N" "Zellij new session" (exec commands.zellijNewSession {}) {})
        (bind "A" "Zellij attach" (exec commands.zellijAttachSession {}) {})
      ];
    };

  hmSubmaps =
    mapAttrs (_: hmSubmap) (filterAttrs (name: _: name != "passthrough") submaps)
    // {
      passthrough = {
        onDispatch = "";
        settings.bind = map renderBind submaps.passthrough;
      };
    };
in {
  settings.bind = map renderBind topLevel;
  submaps = hmSubmaps;
}

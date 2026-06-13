-- ============================================================
-- COMMANDS
-- ============================================================
return function(ctx)
	local cfg = ctx.cfg
	local apps = cfg.apps or {}
	local features = cfg.features or {}

	local function app(cmd)
		return cfg.uwsmAppPrefix .. " " .. cmd
	end

	local browser = apps.qutebrowser
	local privateBrowser = apps.qutebrowser .. " --target private-window"
	if features.bloat and apps.vivaldi then
		browser = apps.vivaldi
		privateBrowser = apps.vivaldi .. " --incognito"
	end

	ctx.features = features
	ctx.commands = {
		app = app,
		browser = app(browser),
		privateBrowser = app(privateBrowser),
		terminal = {
			main = app(apps.terminal .. " --title terminal"),
			dropdown = app(apps.terminal .. " --class dropdown --title dropdown"),
			pinned = app(apps.terminal .. " --class pinned --title pinned"),
		},
		files = app(apps.terminal .. " --class floating-editor --title yazi -e " .. apps.yazi),
		walker = {
			launcher = app(apps.walker .. " --set launcher"),
			commands = app(apps.walker .. " --set commands"),
			clipboard = app(apps.walker .. " --set clipboard"),
			bitwarden = app(apps.walker .. " --set bitwarden"),
			windows = app(apps.walker .. " --set windows"),
			service = app(apps.walker .. " --gapplication-service"),
		},
		autostart = {
			elephant = app(apps.elephant),
			noctalia = app(apps.noctalia),
			submapCheatsheet = app(cfg.scripts.submapCheatsheet),
			wayscriber = app(apps.wayscriber .. " -d --no-tray"),
			jellyfinMpvShim = app(apps.jellyfinMpvShim),
		},
		screenshot = cfg.screenshot,
		locker = app(apps.hyprlock),
		volumeMixer = app(apps.pwvucontrol),
		hyprpicker = app(apps.hyprpicker),
		noctaliaLauncher = apps.noctalia .. " msg panel-toggle launcher",
		noctalia = apps.noctalia,
		submapCheatsheetCall = cfg.scripts.submapCheatsheetCall,
	}
end

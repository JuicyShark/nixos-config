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
		walker = {
			launcher = app(apps.walker .. " --set launcher"),
			files = app(apps.walker .. " --set files"),
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
		},
		screenshot = cfg.screenshot,
		locker = app(apps.hyprlock),
		volumeMixer = app(apps.pwvucontrol),
		hyprpicker = app(apps.hyprpicker),
		noctalia = apps.noctalia,
		submapCheatsheetCall = cfg.scripts.submapCheatsheetCall,
	}
end

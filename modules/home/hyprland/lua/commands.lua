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

	local function noctalia_msg(cmd)
		return apps.noctalia .. " msg " .. cmd
	end

	local function emacs(cmd)
		return app(apps.emacsclient .. " " .. cmd)
	end

	local function emacs_eval(expr)
		return emacs("-c --eval " .. string.format("%q", expr))
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
		files = {
			emacs = emacs_eval('(if (fboundp \'my/open-file-manager) (my/open-file-manager "~") (dired "~"))'),
			thunar = app(apps.thunar),
			yazi = app(apps.terminal .. " --class floating-editor --title yazi -e " .. apps.yazi),
		},
		emacs = {
			raise = emacs("-r"),
			focusOrRaise = emacs("-r"),
			newFrame = emacs("-c"),
			cwd = emacs("-r ."),
			capture = emacs_eval("(org-capture)"),
			today = emacs_eval("(org-roam-dailies-goto-today)"),
			agenda = emacs_eval('(org-agenda nil "d")'),
			projects = emacs_eval('(org-agenda nil "p")'),
			weeklyReview = emacs_eval('(org-agenda nil "R")'),
			roamFind = emacs_eval("(org-roam-node-find)"),
			roamCapture = emacs_eval("(org-roam-capture)"),
			roamSearch = emacs_eval("(consult-org-roam-search)"),
		},
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
		volumeMixer = app(apps.pwvucontrol),
		hyprpicker = app(apps.hyprpicker),
		notifications = {
			clearActive = noctalia_msg("notification-clear-active"),
		},
		media = {
			toggle = noctalia_msg("media toggle"),
			previous = noctalia_msg("media previous"),
			next = noctalia_msg("media next"),
			stop = noctalia_msg("media stop"),
		},
		session = {
			lock = noctalia_msg("session lock"),
			logout = noctalia_msg("session logout"),
			reboot = noctalia_msg("session reboot"),
			shutdown = noctalia_msg("session shutdown"),
		},
		volume = {
			up = noctalia_msg("volume-up"),
			down = noctalia_msg("volume-down"),
			mute = noctalia_msg("volume-mute"),
		},
		noctaliaLauncher = noctalia_msg("panel-toggle launcher"),
		noctalia = apps.noctalia,
		submapCheatsheetCall = cfg.scripts.submapCheatsheetCall,
	}
	end

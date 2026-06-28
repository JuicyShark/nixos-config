-- ============================================================
-- AUTOSTART
-- ============================================================
return function(ctx)
	local hl = ctx.hl
	local commands = ctx.commands
	local features = ctx.features

	hl.on("hyprland.start", function()
		local autostart = {
			{ cmd = commands.autostart.hyprpolkitagent },
			{ cmd = commands.autostart.elephant },
			{ cmd = commands.walker.service },
			{ cmd = commands.autostart.noctalia },
			{ cmd = commands.autostart.submapCheatsheet },
			{ cmd = commands.autostart.wayscriber },
			{ cmd = commands.autostart.jellyfinMpvShim },
			{ cmd = commands.browser, workspace = "2 silent" },
			{ cmd = commands.app("qutebrowser"), workspace = "1 silent", when = features.bloat },
			{ cmd = commands.terminal.main, workspace = "1 silent" },
			{ cmd = commands.terminal.dropdown, workspace = "special:dropdown silent" },
			{ cmd = commands.app("steam"), workspace = "special:steam silent", when = features.gaming },
			{ cmd = commands.app("discord"), workspace = "special:discord silent", when = features.bloat },
			{ cmd = commands.app("tidal-hifi"), workspace = "8 silent", when = features.bloat },
			{ cmd = commands.app("keymapp"), workspace = "9 silent", when = features.zsa },
		}

		for _, e in ipairs(autostart) do
			if e.cmd and e.when ~= false then
				if e.workspace then
					hl.exec_cmd(e.cmd, { workspace = e.workspace })
				else
					hl.exec_cmd(e.cmd)
				end
			end
		end
	end)
end

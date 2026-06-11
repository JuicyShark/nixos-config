-- ============================================================
-- AUTOSTART
-- ============================================================
return function(ctx)
	local hl = ctx.hl
	local cfg = ctx.cfg
	local appCmd = ctx.appCmd

	hl.on("hyprland.start", function()
		local commands = cfg.autostartCommands or {}
		local autostart = {
			{ cmd = "ha-presence-discover", when = cfg.flags.haPresence },
			{ cmd = "ha-presence-update active", when = cfg.flags.haPresence },
			{ cmd = "systemctl --user start hyprpolkitagent.service" },
			{ cmd = commands.elephant },
			{ cmd = commands.walkerService },
			{ cmd = commands.noctalia },
			{ cmd = commands.submapCheatsheet },
			{ cmd = commands.wayscriber },
			{ cmd = cfg.browser, workspace = "2 silent" },
			{ cmd = appCmd("qutebrowser"), workspace = "1 silent", when = cfg.flags.bloat },
			{ cmd = commands.terminal, workspace = "1 silent" },
			{ cmd = commands.dropdown, workspace = "special:dropdown silent" },
			{ cmd = appCmd("steam"), workspace = "special:steam silent", when = cfg.flags.gaming },
			{ cmd = appCmd("discord"), workspace = "special:discord silent", when = cfg.flags.bloat },
			{ cmd = appCmd("tidal-hifi"), workspace = "8 silent", when = cfg.flags.bloat },
			{ cmd = appCmd("keymapp"), workspace = "9 silent", when = cfg.flags.zsa },
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

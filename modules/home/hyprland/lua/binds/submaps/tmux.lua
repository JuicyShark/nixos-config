-- ============================================================
-- TMUX SUBMAP
-- ============================================================
return function(ctx)
	local hl = ctx.hl
	local cfg = ctx.cfg
	local bind = ctx.bind
	local submap = ctx.submap

	local function tmux_terminal(args)
		return cfg.terminalCommands.main .. " -- tmux " .. args
	end

	submap("tmux", function()
		bind("S", hl.dsp.exec_cmd(tmux_terminal("new-session")), "Tmux new session")
		bind("L", hl.dsp.exec_cmd(tmux_terminal("list-sessions")), "Tmux list sessions")
		bind("A", hl.dsp.exec_cmd(tmux_terminal("attach-session")), "Tmux attach")
		bind("D", hl.dsp.exec_cmd("tmux detach-client"), "Tmux detach")
		bind("R", hl.dsp.exec_cmd("tmux source-file ~/.tmux.conf"), "Tmux reload")
	end)
end

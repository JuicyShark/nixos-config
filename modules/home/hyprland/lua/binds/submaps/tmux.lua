-- ============================================================
-- TMUX SUBMAP
-- ============================================================
return function(ctx)
	local hl = ctx.hl
	local commands = ctx.commands
	local bind = ctx.bindHelpers.bind
	local defineSubmap = ctx.bindHelpers.defineSubmap

	local function tmux_terminal(args)
		return commands.terminal.main .. " -- tmux " .. args
	end

	defineSubmap("tmux", function()
		bind("S", hl.dsp.exec_cmd(tmux_terminal("new-session")), "Tmux new session")
		bind("L", hl.dsp.exec_cmd(tmux_terminal("list-sessions")), "Tmux list sessions")
		bind("A", hl.dsp.exec_cmd(tmux_terminal("attach-session")), "Tmux attach")
		bind("D", hl.dsp.exec_cmd("tmux detach-client"), "Tmux detach")
		bind("R", hl.dsp.exec_cmd("tmux source-file ~/.tmux.conf"), "Tmux reload")
	end)
end

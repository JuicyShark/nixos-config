-- ============================================================
-- TMUX SUBMAP
-- ============================================================
return function(ctx)
	local hl = ctx.hl
	local commands = ctx.commands
	local bind = ctx.bindHelpers.bind
	local defineSubmap = ctx.bindHelpers.defineSubmap

	local function tmux_terminal(args)
		return commands.terminal.main .. " -- " .. args
	end

	defineSubmap("tmux", function()
		bind("S", hl.dsp.exec_cmd(tmux_terminal(commands.tmux.newSession)), "Tmux new session")
		bind("L", hl.dsp.exec_cmd(tmux_terminal(commands.tmux.listSessions)), "Tmux list sessions")
		bind("A", hl.dsp.exec_cmd(tmux_terminal(commands.tmux.attachSession)), "Tmux attach")
		bind("D", hl.dsp.exec_cmd(commands.tmux.detach), "Tmux detach")
		bind("R", hl.dsp.exec_cmd(commands.tmux.reload), "Tmux reload")
	end)
end

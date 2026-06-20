-- ============================================================
-- EMACS SUBMAP
-- ============================================================
return function(ctx)
	local hl = ctx.hl
	local commands = ctx.commands
	local bind = ctx.bindHelpers.bind
	local defineSubmap = ctx.bindHelpers.defineSubmap

	defineSubmap("emacs", function()
		bind("E", hl.dsp.exec_cmd(commands.emacs.raise), "Emacs raise")
		bind("F", function()
			local w = hl.get_windows({ class = "^(emacs|org.gnu.Emacs)$" })[1]
			if w then
				hl.dispatch(hl.dsp.focus({ window = w }))
			end
		end, "Emacs focus")
		bind("N", hl.dsp.exec_cmd(commands.emacs.newFrame), "Emacs new frame")
		bind("C", hl.dsp.exec_cmd(commands.emacs.cwd), "Emacs cwd")

		bind("D", hl.dsp.exec_cmd(commands.files.emacs), "Dired / Dirvish")
		bind("CONTROL + D", hl.dsp.exec_cmd(commands.files.thunar), "Files (Thunar)")
		bind("SHIFT + D", hl.dsp.exec_cmd(commands.files.thunar), "Files (Thunar)", { cheatsheet = false })
		bind("Y", hl.dsp.exec_cmd(commands.files.yazi), "Files (Yazi)")

		bind("I", hl.dsp.exec_cmd(commands.emacs.capture), "Org capture")
		bind("T", hl.dsp.exec_cmd(commands.emacs.today), "Org today")
		bind("A", hl.dsp.exec_cmd(commands.emacs.agenda), "Org agenda")
		bind("P", hl.dsp.exec_cmd(commands.emacs.projects), "Org projects")
		bind("W", hl.dsp.exec_cmd(commands.emacs.weeklyReview), "Org weekly review")
		bind("R", hl.dsp.exec_cmd(commands.emacs.roamFind), "Roam find")
		bind("CONTROL + R", hl.dsp.exec_cmd(commands.emacs.roamCapture), "Roam capture")
		bind("SHIFT + R", hl.dsp.exec_cmd(commands.emacs.roamCapture), "Roam capture", { cheatsheet = false })
		bind("S", hl.dsp.exec_cmd(commands.emacs.roamSearch), "Roam search")
	end)
end

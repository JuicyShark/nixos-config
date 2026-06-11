-- ============================================================
-- EMACS SUBMAP
-- ============================================================
return function(ctx)
	local hl = ctx.hl
	local bind = ctx.bind
	local submap = ctx.submap

	submap("emacs", function()
		bind("E", hl.dsp.exec_cmd("emacsclient -r"), "Emacs raise")
		bind("F", function()
			local w = hl.get_windows({ class = "emacs" })[1]
			if w then
				hl.dispatch(hl.dsp.focus({ window = w }))
			end
		end, "Emacs focus")
		bind("N", hl.dsp.exec_cmd("emacsclient -c"), "Emacs new frame")
		bind("C", hl.dsp.exec_cmd("emacsclient -r ."), "Emacs cwd")
		bind(
			"D",
			hl.dsp.exec_cmd('emacsclient -c --eval "(call-interactively org-dailies-goto-today)"'),
			"Emacs org today"
		)
	end)
end

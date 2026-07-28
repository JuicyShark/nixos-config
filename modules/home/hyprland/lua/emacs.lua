return function(ctx, opts)
	local hl = ctx.hl
	opts = opts or {}

	local api = {}

	function api.focus()
		local windows = hl.get_windows({ class = "^(emacs|org.gnu.Emacs)$" }) or {}
		local window = windows[1]
		if window then
			hl.dispatch(hl.dsp.focus({ window = window }))
		elseif opts.raise then
			hl.exec_cmd(opts.raise)
		end
	end

	_G.Juicy = _G.Juicy or {}
	_G.Juicy.emacs = api
end

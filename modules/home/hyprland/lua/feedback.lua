return function(ctx)
	local hl = ctx.hl

	local api = {}
	local last, lastText

	function api.notify(summary, body, urgency)
		local text = body and body ~= "" and (summary .. ": " .. body) or summary
		if last and lastText == text and last:is_alive() then
			return
		end
		local colors = {
			critical = "rgb(ff5555)",
			normal = "rgb(8be9fd)",
		}
		last = hl.notification.create({
			text = text,
			timeout = 2500,
			color = colors[urgency or "normal"],
		})
		lastText = text
	end

	ctx.feedback = api
end

-- ============================================================
-- WINDOW POLICY
-- ============================================================
return function(ctx)
	local gameClass =
		"^(steam_app_[0-9]+|gamescope|FTL%.amd64|Slay( the)? Spire|SlayTheSpire|Slay the Spire 2|Balatro)$"
	local gameTitle = "^(World of Warcraft|Slay the Spire|Slay the Spire 2|Balatro)$"

	local function matches(value, pattern)
		return type(value) == "string" and value:match(pattern) ~= nil
	end

	ctx.windowPolicy = {
		gameClass = gameClass,
		gameTitle = gameTitle,
		isGame = function(window)
			if not window then
				return false
			end
			return matches(window.class, gameClass)
				or matches(window.title, gameTitle)
				or matches(window.initial_title, gameTitle)
		end,
	}
end

local M = {}

local function string_target(target)
	if type(target) == "table" then
		return target.path or target.uri or target.url
	end
	return target
end

function M.is_link(target)
	target = string_target(target)
	return type(target) == "string" and (target:match("^%a[%w+.-]*:") or target:match("^www%."))
end

function M.normalize(target)
	target = string_target(target)
	if type(target) ~= "string" or target == "" then
		return nil
	end

	if target:match("^www%.") then
		target = "https://" .. target
	end
	if M.is_link(target) then
		return target
	end
	return nil
end

function M.markdown_link_at(line, col)
	if type(line) ~= "string" then
		return nil
	end

	for start, label, wrapped in line:gmatch("()%[([^%]]+)%](%b())") do
		local link = wrapped:sub(2, -2)
		local finish = start + #label + #wrapped + 1
		if start <= col and col <= finish then
			return M.normalize(link)
		end
	end
	return nil
end

function M.target_under_cursor()
	local line = vim.api.nvim_get_current_line()
	local col = vim.api.nvim_win_get_cursor(0)[2] + 1
	return M.markdown_link_at(line, col) or M.normalize(vim.fn.expand("<cfile>"))
end

function M.setup(opener)
	vim.g.netrw_browsex_viewer = opener

	_G.open_hyperlink_under_cursor = function()
		local target = M.target_under_cursor()
		if not target then
			vim.notify("No link under cursor", vim.log.levels.WARN)
			return
		end
		vim.system({ opener, target }, { detach = true }, function(result)
			if result.code ~= 0 then
				vim.schedule(function()
					vim.notify("Could not open link: " .. target, vim.log.levels.ERROR)
				end)
			end
		end)
	end
end

return M

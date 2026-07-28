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

  target = target:gsub("[%)%]>.,;:]+$", "")
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

  for start, label, link in line:gmatch("()%[([^%]]+)%]%(([^%)]+)%)") do
    local finish = start + #label + #link + 3
    if start <= col and col <= finish then
      return M.normalize(link)
    end
  end
  return nil
end

function M.target_under_cursor()
  local target = M.normalize(vim.fn.expand("<cfile>"))
  if target then
    return target
  end

  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  return M.markdown_link_at(line, col)
end

function M.setup(opener)
  local original_ui_open = vim.ui.open

  local function open_with_qutebrowser(target)
    target = M.normalize(target)
    if not target then
      return false
    end

    if vim.system then
      vim.system({ opener, target }, { detach = true })
    else
      vim.fn.jobstart({ opener, target }, { detach = true })
    end
    return true
  end

  vim.g.netrw_browsex_viewer = opener
  vim.ui.open = function(path, opts)
    if open_with_qutebrowser(path) then
      return
    end

    if original_ui_open then
      return original_ui_open(path, opts)
    end
  end

  _G.open_hyperlink_under_cursor = function()
    local target = M.target_under_cursor()
    if not target then
      vim.notify("No link under cursor", vim.log.levels.WARN)
      return
    end
    vim.ui.open(target)
  end
end

return M

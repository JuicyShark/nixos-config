local failures = {}

local function expect(name, condition)
	if not condition then
		table.insert(failures, name)
	end
end

local source = vim.fn.tempname() .. ".norg"
vim.fn.writefile({ "* Neorg Setup" }, source)
vim.cmd.edit(vim.fn.fnameescape(source))
expect("norg filetype", vim.bo.filetype == "norg")
expect("norg buffer parser", pcall(vim.treesitter.get_parser, 0, "norg"))

vim.wait(2000, function()
	return #vim.lsp.get_clients({ bufnr = 0, name = "neorg-interim-ls" }) == 1
end, 20)
expect("Neorg completion LSP attached", #vim.lsp.get_clients({ bufnr = 0, name = "neorg-interim-ls" }) == 1)

if #failures > 0 then
	vim.api.nvim_err_writeln("NixVim Neorg setup contract failed:\n- " .. table.concat(failures, "\n- "))
	vim.cmd.cquit(1)
end

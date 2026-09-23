local M = {}

function M.root(bufnr)
	local name = vim.api.nvim_buf_get_name(bufnr or 0)
	local start = name ~= "" and vim.fs.dirname(name) or vim.fn.getcwd()
	return vim.fs.root(start, { ".git", "flake.nix", "Cargo.toml", "pyproject.toml", "package.json" })
		or vim.fn.getcwd()
end

function M.pick(source, opts)
	local cwd = M.root()
	Snacks.picker[source](vim.tbl_deep_extend("force", {
		cwd = cwd,
		title = "Project " .. source .. ": " .. vim.fn.fnamemodify(cwd, ":t"),
	}, opts or {}))
end

function M.terminal()
	local cwd = vim.b.juicy_terminal_root or M.root()
	local terminal = Snacks.terminal.toggle(nil, {
		cwd = cwd,
		win = { position = "bottom", height = 0.3 },
	})
	if terminal and terminal.buf and vim.api.nvim_buf_is_valid(terminal.buf) then
		vim.b[terminal.buf].juicy_terminal_root = cwd
	end
end

function M.configure_nixd(client)
	local root = client.config.root_dir
	local flake = vim.env.FLAKE or vim.fn.expand("~/nixos-config")
	local uv = vim.uv
	if not root or not uv.fs_realpath(root) or uv.fs_realpath(root) ~= uv.fs_realpath(flake) then
		return
	end
	-- Only this flake has these host names. Unrelated Nix projects retain the
	-- packaged nixpkgs completion expression and no machine-specific options.
	local expr = "(builtins.getFlake " .. vim.json.encode(uv.fs_realpath(root)) .. ")"
	client.config.settings.nixd = vim.tbl_deep_extend("force", client.config.settings.nixd or {}, {
		nixpkgs = { expr = "import " .. expr .. ".inputs.nixpkgs { }" },
		options = {
			darwin = { expr = expr .. ".darwinConfigurations.mac.options" },
			["home-manager"] = {
				expr = expr .. ".nixosConfigurations.leo.options.home-manager.users.type.getSubOptions []",
			},
			leo = { expr = expr .. ".nixosConfigurations.leo.options" },
			zues = { expr = expr .. ".nixosConfigurations.zues.options" },
		},
	})
	client:notify("workspace/didChangeConfiguration", { settings = client.config.settings })
end

return M

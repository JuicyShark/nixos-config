{
  lib,
  pkgs,
  ...
}: let
  fullDev = pkgs.stdenv.hostPlatform.isLinux;
in {
  programs.nixvim.keymaps = [
    {
      mode = ["n" "x"];
      key = "<leader>cf";
      action.__raw = ''function() require("conform").format() end'';
      options.desc = "Format buffer or selection";
    }
    {
      mode = "n";
      key = "<leader>cF";
      action = "<cmd>ConformInfo<CR>";
      options.desc = "Formatter status";
    }
  ];

  programs.nixvim.plugins = {
    conform-nvim = {
      enable = true;
      settings = {
        default_format_opts = {
          lsp_format = "fallback";
          timeout_ms = 2000;
        };
        format_on_save.__raw = ''
          function(bufnr)
            if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
              return
            end
            return { lsp_format = "fallback", timeout_ms = 2000 }
          end
        '';
        formatters_by_ft = {
          lua = ["stylua"];
          nix = ["alejandra"];
          c = lib.optionals fullDev ["clang_format"];
          cpp = lib.optionals fullDev ["clang_format"];
          css = lib.optionals fullDev ["prettierd"];
          gdscript = lib.optionals fullDev ["gdformat"];
          go = lib.optionals fullDev ["gofmt" "goimports"];
          html = lib.optionals fullDev ["prettierd"];
          javascript = lib.optionals fullDev ["prettierd"];
          javascriptreact = lib.optionals fullDev ["prettierd"];
          json = lib.optionals fullDev ["prettierd"];
          jsonc = lib.optionals fullDev ["prettierd"];
          markdown = lib.optionals fullDev ["prettierd"];
          python = lib.optionals fullDev ["ruff_format" "ruff_organize_imports"];
          rust = lib.optionals fullDev ["rustfmt"];
          sh = ["shfmt"];
          bash = ["shfmt"];
          toml = ["taplo"];
          typescript = lib.optionals fullDev ["prettierd"];
          typescriptreact = lib.optionals fullDev ["prettierd"];
          yaml = lib.optionals fullDev ["prettierd"];
        };
        formatters = {
          alejandra = {
            command = "alejandra";
          };
          stylua = {
            command = "stylua";
          };
        };
      };
    };
  };
}

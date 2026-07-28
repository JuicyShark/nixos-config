# Extra Lua configuration blocks
{
  lib,
  pkgs,
  ...
}: let
  qutebrowser = lib.getExe pkgs.qutebrowser;
  linksModule = ./lua/juicy/links.lua;
  notesModule = ./lua/juicy/notes.lua;
  smartFocusModule = ./lua/juicy/smart_focus.lua;
in {
  programs.nixvim.extraConfigLuaPre = ''
    -- Some bundled treesitter queries still use this nvim-treesitter predicate
    -- name, while Neovim 0.12 no longer registers it by default.
    do
      local ts_query = require("vim.treesitter.query")
      local predicates = ts_query.list_predicates and ts_query.list_predicates() or {}
      local has_is_not = false
      for _, predicate in ipairs(predicates) do
        if predicate == "is-not?" then
          has_is_not = true
          break
        end
      end

      if not has_is_not then
        vim.treesitter.query.add_predicate("is-not?", function(match, _pattern, _bufnr, pred)
          local capture_id = pred[2]
          local node = match[capture_id]
          if not node then
            return true
          end

          local node_type = node:type()
          for i = 3, #pred do
            if node_type == pred[i] then
              return false
            end
          end
          return true
        end, { force = true })
      end
    end
  '';

  programs.nixvim.extraConfigLua = ''
    do
      package.preload["juicy.links"] = assert(loadfile("${linksModule}"))
      package.preload["juicy.notes"] = assert(loadfile("${notesModule}"))
      package.preload["juicy.smart_focus"] = assert(loadfile("${smartFocusModule}"))

      require("juicy.links").setup("${qutebrowser}")
      require("juicy.notes").setup()
      require("juicy.smart_focus").start()
    end
  '';
}

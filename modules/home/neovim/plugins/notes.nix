{pkgs, ...}: {
  home.file."documents/notes/journal/template.norg".text = ''
    @document.meta
    title: Daily Journal
    categories: [journal]
    @end

    * Daily Journal

    ** Tasks

    ** Notes
  '';

  imports = [../keymaps/notes.nix];

  programs.nixvim = {
    # Adds workspace-aware completion, references, and link-safe heading/file
    # renames through Neovim's LSP client and the existing Blink UI.
    extraPlugins = [pkgs.vimPlugins.neorg-interim-ls];

    # Task-state bindings only make sense in Neorg buffers. Keeping them in an
    # ftplugin avoids a global forest of inactive <Plug> mappings.
    extraFiles."after/ftplugin/norg.lua".text = ''
      local map = function(key, action, desc)
        vim.keymap.set("n", key, action, {
          buffer = true,
          desc = desc,
          remap = true,
          silent = true,
        })
      end

      map("<leader>nt", function()
        require("which-key").show({ keys = "<leader>nt" })
      end, "Task")
      map("<leader>ntt", "<Plug>(neorg.qol.todo-items.todo.task-cycle)", "Cycle task")
      map("<leader>ntd", "<Plug>(neorg.qol.todo-items.todo.task-done)", "Done")
      map("<leader>ntu", "<Plug>(neorg.qol.todo-items.todo.task-undone)", "Undone")
      map("<leader>ntp", "<Plug>(neorg.qol.todo-items.todo.task-pending)", "Pending")
      map("<leader>nth", "<Plug>(neorg.qol.todo-items.todo.task-on-hold)", "On hold")
      map("<leader>nti", "<Plug>(neorg.qol.todo-items.todo.task-important)", "Important")
      map("<leader>ntr", "<Plug>(neorg.qol.todo-items.todo.task-recurring)", "Recurring")
      map("<leader>ntc", "<Plug>(neorg.qol.todo-items.todo.task-cancelled)", "Cancelled")
      map("<leader>nt?", "<Plug>(neorg.qol.todo-items.todo.task-ambiguous)", "Ambiguous")
    '';

    plugins = {
      neorg = {
        enable = true;
        settings.load = {
          "core.defaults".config.disable = [
            "core.integrations.image"
          ];
          "core.clipboard.code-blocks".__empty = null;
          "core.completion".config.engine.module_name = "external.lsp-completion";
          "core.concealer".config = {
            icon_preset = "varied";
            folds = true;
          };
          "core.dirman".config = {
            default_workspace = "notes";
            workspaces.notes = "~/documents/notes";
          };
          "core.export".__empty = null;
          "core.export.markdown".__empty = null;
          "core.journal".config = {
            workspace = "notes";
            journal_folder = "journal";
            strategy = "nested";
          };
          "core.looking-glass".__empty = null;
          "core.qol.toc".__empty = null;
          "core.qol.todo_items".config = {
            create_todo_items = true;
            create_todo_parents = true;
            update_todo_parents = true;
          };
          "core.summary".__empty = null;
          "core.tangle".config.tangle_on_write = false;
          "core.tempus".__empty = null;
          "core.text-objects".__empty = null;
          "core.keybinds".config.default_keybinds = false;
          "core.todo-introspector".__empty = null;
          "core.ui.calendar".__empty = null;
          "external.interim-ls".config.completion_provider = {
            enable = true;
            documentation = true;
            categories = false;
            people.enable = false;
          };
        };
      };

      headlines = {
        enable = true;
        settings.norg = {
          headline_highlights = ["Headline"];
          bullet_highlights = [
            "@neorg.headings.1.prefix"
            "@neorg.headings.2.prefix"
            "@neorg.headings.3.prefix"
            "@neorg.headings.4.prefix"
            "@neorg.headings.5.prefix"
            "@neorg.headings.6.prefix"
          ];
          bullets = [
            "◉"
            "○"
            "✸"
            "✿"
          ];
          codeblock_highlight = "CodeBlock";
          dash_highlight = "Dash";
          dash_string = "-";
          doubledash_highlight = "DoubleDash";
          doubledash_string = "=";
          quote_highlight = "Quote";
          quote_string = "┃";
          fat_headlines = true;
          fat_headline_upper_string = "▃";
          fat_headline_lower_string = "🬂";
        };
      };
    };
  };
}

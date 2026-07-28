_: {
  programs.nixvim.keymaps = [
    # Lowercase keys follow Doom's org-roam workflow.
    {
      mode = "n";
      key = "<leader>nn";
      action = "<cmd>NotesFind<CR>";
      options.desc = "Find note";
    }
    {
      mode = "n";
      key = "<leader>nc";
      action = "<cmd>NotesNew<CR>";
      options.desc = "Capture note";
    }
    {
      mode = "n";
      key = "<leader>nI";
      action = "<cmd>NotesInbox<CR>";
      options.desc = "Capture inbox task";
    }
    {
      mode = "n";
      key = "<leader>nd";
      action = "<cmd>NotesToday<CR>";
      options.desc = "Daily note";
    }
    {
      mode = "n";
      key = "<leader>nj";
      action = "<cmd>NotesToday<CR>";
      options.desc = "Journal today";
    }
    {
      mode = "n";
      key = "<leader>n[";
      action = "<cmd>NotesYesterday<CR>";
      options.desc = "Journal yesterday";
    }
    {
      mode = "n";
      key = "<leader>n]";
      action = "<cmd>NotesTomorrow<CR>";
      options.desc = "Journal tomorrow";
    }
    {
      mode = "n";
      key = "<leader>ns";
      action = "<cmd>NotesGrep<CR>";
      options.desc = "Search notes";
    }
    {
      mode = "n";
      key = "<leader>nb";
      action = "<cmd>NotesBacklinks<CR>";
      options.desc = "Backlinks";
    }
    {
      mode = "n";
      key = "<leader>nl";
      action = "<cmd>NotesBacklinks<CR>";
      options.desc = "Links and backlinks";
    }
    {
      mode = "n";
      key = "<leader>ni";
      action = "<cmd>NotesInsertLink<CR>";
      options.desc = "Insert note link";
    }
    {
      mode = "n";
      key = "<leader>na";
      action = "<cmd>NotesAgenda<CR>";
      options.desc = "Agenda scan";
    }
    {
      mode = "n";
      key = "<leader>no";
      action = "<cmd>NotesOpenIndex<CR>";
      options.desc = "Open notes index";
    }

    # Neovim/Neorg-specific utilities stay on uppercase keys.
    {
      mode = "n";
      key = "<leader>nT";
      action = "<cmd>NotesTags<CR>";
      options.desc = "Search tags";
    }
    {
      mode = "n";
      key = "<leader>nO";
      action = "<cmd>Neorg index<CR>";
      options.desc = "Neorg index";
    }
    {
      mode = "n";
      key = "<leader>nC";
      action = "<cmd>NotesCalendar<CR>";
      options.desc = "Calendar";
    }
    {
      mode = "n";
      key = "<leader>nJ";
      action = "<cmd>Neorg journal toc<CR>";
      options.desc = "Journal toc";
    }
    {
      mode = "n";
      key = "<leader>nX";
      action = "<cmd>Neorg tangle current-file<CR>";
      options.desc = "Tangle file";
    }
    {
      mode = "n";
      key = "<leader>nE";
      action = "<cmd>Neorg export to-file<CR>";
      options.desc = "Export file";
    }
    {
      mode = "n";
      key = "<leader>nL";
      action = "<cmd>Neorg looking-glass magnify-code-block<CR>";
      options.desc = "Focus code block";
    }
    {
      mode = "n";
      key = "<leader>nS";
      action = "<cmd>Neorg generate-workspace-summary notes<CR>";
      options.desc = "Workspace summary";
    }
    {
      mode = "n";
      key = "<leader>nR";
      action = "<cmd>NeovimIdeReference<CR>";
      options.desc = "IDE reference";
    }
  ];
}

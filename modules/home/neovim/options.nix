# Vim editor options (scrolloff, tabstop, etc.)
_: {
  programs.nixvim.opts = {
    # Code folding settings (prevent auto-folding on file open)
    foldmethod = "expr";
    foldexpr = "nvim_treesitter#foldexpr()";
    foldenable = false; # Don't fold by default when opening files
    foldlevel = 99; # Open all folds by default
    foldlevelstart = 99; # Start with all folds open

    # Whitespace
    tabstop = 2;
    shiftwidth = 2;
    expandtab = true;
    autoindent = true;
    copyindent = true;

    linebreak = true;
    clipboard = "unnamedplus";
    cursorline = true;
    number = true;
    relativenumber = true;
    signcolumn = "yes";
    updatetime = 250;

    termguicolors = true;
    mouse = "a";
    hidden = true;
    autoread = true;

    scrolloff = 8;
    smoothscroll = true;
    splitright = true;
    splitbelow = true;
    ignorecase = true;
    smartcase = true;
    inccommand = "split";
    undofile = true;

    # Misc
    swapfile = false;

    completeopt = [
      "menu"
      "menuone"
      "noselect"
    ];
  };
}

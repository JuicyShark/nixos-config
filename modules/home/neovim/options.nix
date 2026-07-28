# Vim editor options (scrolloff, tabstop, etc.)
_: {
  programs.nixvim.opts = {
    # Code folding settings (prevent auto-folding on file open)
    foldenable = false; # Don't fold by default when opening files
    foldlevel = 99; # Open all folds by default
    foldlevelstart = 99; # Start with all folds open

    # Whitespace
    tabstop = 4;
    shiftwidth = 4;
    expandtab = true;
    smartindent = true;
    copyindent = true;

    linebreak = true;
    clipboard = "unnamedplus";
    cursorline = true;
    number = true;
    relativenumber = true;
    numberwidth = 2;
    foldcolumn = "0";
    signcolumn = "yes:1";
    showtabline = 0;
    updatetime = 250;

    termguicolors = true;
    mouse = "a";

    scrolloff = 8;
    smoothscroll = true;
    splitright = true;
    splitbelow = true;
    ignorecase = true;
    smartcase = true;
    inccommand = "split";
    diffopt = [
      "internal"
      "filler"
      "closeoff"
      "indent-heuristic"
      "algorithm:histogram"
      "inline:word"
    ];
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

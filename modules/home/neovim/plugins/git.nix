{pkgs, ...}: {
  imports = [../keymaps/git.nix];

  programs.nixvim = {
    extraPlugins = [
      pkgs.vimPlugins.diffview-nvim
    ];

    plugins = {
      lazygit.enable = true;
      gitsigns.enable = true;
    };
  };
}

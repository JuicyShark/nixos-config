{inputs, ...}: {
  flake = {
    nixosModules = {
      acme = import ../modules/nixos/acme.nix;
      desktop = import ../modules/nixos/desktop;
      emacs = import ../modules/common/emacs.nix;
      filebrowser = import ../modules/nixos/filebrowser.nix;
      fonts = import ../modules/nixos/fonts.nix;
      glance = import ../modules/nixos/glance.nix;
      ha-presence = import ../modules/nixos/ha-presence.nix;
      homelab = import ../modules/nixos/homelab;
      htb = import ../modules/nixos/htb.nix;
      impermanence = import ../modules/nixos/impermanence.nix;
      ios = import ../modules/nixos/ios.nix;
      monitoring = import ../modules/nixos/monitoring;
      nfs = import ../modules/nixos/nfs.nix;
      pipewire = import ../modules/nixos/pipewire.nix;
      ports = import ../modules/nixos/ports.nix;
      recomp = import ../modules/nixos/recomp.nix;
      shairport = import ../modules/nixos/shairport.nix;
      shell = import ../modules/common/shell.nix;
      stylix = import ../modules/common/stylix.nix;
      sunshine = import ../modules/nixos/sunshine.nix;
      system = import ../modules/nixos/system.nix;
      unbound = import ../modules/nixos/unbound.nix;
    };

    darwinModules = {
      emacs = import ../modules/common/emacs.nix;
      shell = import ../modules/common/shell.nix;
      stylix = import ../modules/common/stylix.nix;
      system = import ../modules/darwin/system.nix;
    };

    homeModules = {
      atuin = import ../modules/home/atuin.nix;
      barrier = import ../modules/home/barrier.nix;
      bat = import ../modules/home/bat.nix;
      btop = import ../modules/home/btop.nix;
      chromium = import ../modules/home/chromium.nix;
      editorconfig = import ../modules/home/editorconfig.nix;
      emacs = import ../modules/home/emacs.nix;
      eza = import ../modules/home/eza.nix;
      fastfetch = import ../modules/home/fastfetch.nix;
      fzf = import ../modules/home/fzf.nix;
      git = import ../modules/home/git.nix;
      gtk = import ../modules/home/gtk.nix;
      ha-presence = import ../modules/home/ha-presence.nix;
      hyprland = import ../modules/home/hyprland.nix;
      kitty = import ../modules/home/kitty.nix;
      lazygit = import ../modules/home/lazygit.nix;
      mime-apps = import ../modules/home/mime-apps.nix;
      mpv = import ../modules/home/mpv.nix;
      neovim = import ../modules/home/neovim;
      noctalia-shell = import ../modules/home/noctalia-shell.nix;
      obs = import ../modules/home/obs.nix;
      qutebrowser = import ../modules/home/qutebrowser.nix;
      ripgrep = import ../modules/home/ripgrep.nix;
      shairport = import ../modules/home/shairport.nix;
      ssh = import ../modules/home/ssh.nix;
      starship = import ../modules/home/starship.nix;
      tmux = import ../modules/home/tmux.nix;
      xdg-desktop-entries = import ../modules/home/xdg-desktop-entries.nix;
      xdg-user-dirs = import ../modules/home/xdg-user-dirs.nix;
      xresources = import ../modules/home/xresources.nix;
      yazi = import ../modules/home/yazi.nix;
      zoxide = import ../modules/home/zoxide.nix;
      zsh = import ../modules/home/zsh.nix;
    };

    lib =
      inputs.nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ] (
        _system:
          import ../lib {
            inherit (inputs.nixpkgs) lib;
          }
      );
  };
}

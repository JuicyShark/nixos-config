# NixOS live ISO — disk setup and system maintenance.
# Uses nixpkgs-native installation-cd module (no external tools needed).
#
# Build:  nix build .#iso
# Write:  dd if=result/iso/*.iso of=/dev/sdX bs=4M status=progress
{
  modulesPath,
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  # ── Image settings ─────────────────────────────────────────────────────────
  isoImage.squashfsCompression = "zstd -Xcompression-level 6";
  image.fileName = lib.mkForce "nixos-juicy-${pkgs.stdenv.hostPlatform.system}.iso";

  # ── Locale / timezone ──────────────────────────────────────────────────────
  time.timeZone = "Australia/Brisbane";
  i18n.defaultLocale = "en_AU.UTF-8";

  # ── Networking ─────────────────────────────────────────────────────────────
  networking = {
    hostName = "nixos-iso";
    networkmanager.enable = true;
    wireless.enable = lib.mkForce false;
  };

  # ── SSH ────────────────────────────────────────────────────────────────────
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # ── User ───────────────────────────────────────────────────────────────────
  users.users.juicy = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = ["wheel" "networkmanager" "disk" "video" "audio"];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILUlQ0gc5NIpsO3qPU7NR9NF8DobGXlhlmVzP944USPC juicy@leo"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  programs = {
    # ── Shell ──────────────────────────────────────────────────────────────────
    zsh = {
      enable = true;
      promptInit = ''eval "$(${pkgs.starship}/bin/starship init zsh)"'';
      shellAliases = {
        ls = "eza --icons";
        ll = "eza -lah --icons --git";
        cat = "bat --plain";
        vim = "nvim";
      };
    };

    # ── Neovim ─────────────────────────────────────────────────────────────────
    neovim = {
      enable = true;
      defaultEditor = true;
      configure.customRC = ''
        set number relativenumber
        set expandtab shiftwidth=2 tabstop=2
        set clipboard=unnamedplus
        set ignorecase smartcase
        colorscheme habamax
      '';
    };

    # ── Git ────────────────────────────────────────────────────────────────────
    git = {
      enable = true;
      config = {
        init.defaultBranch = "master";
        pull.rebase = true;
        core.editor = "nvim";
      };
    };

    # ── Tmux ───────────────────────────────────────────────────────────────────
    tmux = {
      enable = true;
      terminal = "tmux-256color";
      shortcut = "a";
      escapeTime = 0;
      extraConfig = ''
        set -g mouse on
        set -g history-limit 50000
        set -g status-style 'bg=#1e1e2e fg=#cdd6f4'
        set -g pane-border-style 'fg=#313244'
        set -g pane-active-border-style 'fg=#89b4fa'
      '';
    };
  };

  environment = {
    etc."starship.toml".text = ''
      [character]
      success_symbol = "[λ](bold green)"
      error_symbol   = "[λ](bold red)"
      [directory]
      truncation_length = 4
      truncate_to_repo  = false
      [nix_shell]
      symbol = " "
    '';

    variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      STARSHIP_CONFIG = "/etc/starship.toml";
    };

    # ── Packages ─────────────────────────────────────────────────────────────
    systemPackages = with pkgs; [
      # Disk / filesystem
      btrfs-progs
      parted
      gptfdisk
      cryptsetup
      e2fsprogs
      dosfstools
      nvme-cli
      smartmontools
      ddrescue
      hdparm

      # System inspection
      pciutils
      usbutils
      lsof
      htop
      btop

      # Preferred CLI
      neovim
      git
      tmux
      ripgrep
      fd
      bat
      eza
      fzf
      jq
      curl
      wget
      rsync
      unzip

      # Nix tooling
      nixos-install-tools
      nix-info

      # Secrets
      inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.agenix
    ];
  };

  # ── Trim docs to keep ISO smaller ─────────────────────────────────────────
  documentation.enable = false;
  documentation.nixos.enable = false;

  boot.zfs.forceImportRoot = false;

  system.stateVersion = "25.11";
}

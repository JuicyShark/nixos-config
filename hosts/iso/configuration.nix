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
  homeProfiles,
  ...
}: {
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    inputs.home-manager.nixosModules.home-manager
    ../../modules/common/options.nix
    ../../modules/common/shell.nix
  ];

  # ── Image settings ─────────────────────────────────────────────────────────
  isoImage.squashfsCompression = "zstd -Xcompression-level 6";
  image.baseName = lib.mkForce "nixos-juicy-${pkgs.stdenv.hostPlatform.system}";

  # ── Locale / timezone ──────────────────────────────────────────────────────
  time.timeZone = "Australia/Brisbane";
  i18n.defaultLocale = "en_AU.UTF-8";

  # ── Networking ─────────────────────────────────────────────────────────────
  networking = {
    hostName = "nixos-recovery";
    networkmanager.enable = true;
    wireless.enable = lib.mkForce false;
  };

  # ── Graphical recovery session ─────────────────────────────────────────────
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
  };

  services = {
    greetd = {
      enable = true;
      settings.default_session = {
        user = "juicy";
        command = "${lib.getExe pkgs.uwsm} start -e -D Hyprland hyprland.desktop";
      };
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };
    udisks2.enable = true;

    # ── SSH ──────────────────────────────────────────────────────────────────
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };
  };

  security = {
    polkit.enable = true;
    rtkit.enable = true;
    sudo.wheelNeedsPassword = false;
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

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs;
      system = pkgs.stdenv.hostPlatform.system;
    };
    sharedModules =
      homeProfiles.recovery
      ++ [
        {
          home = {
            stateVersion = "25.11";
            username = "juicy";
            homeDirectory = "/home/juicy";
          };
        }
      ];
    users.juicy = {};
  };

  programs = {
    hyprland = {
      enable = true;
      withUWSM = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    };
    # ── Shell ──────────────────────────────────────────────────────────────────
    zsh.enable = true;
  };

  environment = {
    variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
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
      efibootmgr
      testdisk
      ntfs3g
      exfatprogs
      lvm2
      mdadm

      # System inspection
      pciutils
      usbutils
      dmidecode
      lsof
      htop
      btop

      # Preferred CLI
      neovim
      git
      zellij
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
      bind
      iproute2
      networkmanager
      wl-clipboard-rs

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

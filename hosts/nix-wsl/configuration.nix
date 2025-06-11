# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{
  config,
  lib,
  pkgs,
  nix-config,
  ...
}:

{
  imports = [
    # include NixOS-WSL modules
    <nixos-wsl/modules>
  ] ++ (builtins.attrValues nix-config.nixosModules);

  home-manager.sharedModules = builtins.attrValues nix-config.homeModules;
  environment.systemPackages = builtins.attrValues nix-config.packages.${pkgs.system};
  environment.sessionVariables = {
    FLAKE = "/mnt/chonk/nixos-config";
    #GDK_BACKEND = "wayland";
    #   XDG_SESSION_TYPE = "wayland";
    WAYLAND_DISPLAY = "wayland-0";
  };

  modules = {
    desktop.enable = true;
    desktop.apps.llm = false;
    desktop.apps.emacs = true;
    hardware.nvidia.enable = true;
  };
  networking = {
    defaultGateway = lib.mkForce "192.168.1.1";
    nameservers = lib.mkForce [
      "1.1.1.1"
      "8.8.8.8"
    ];

    interfaces.enp5s0.ipv4.addresses = [
      {
        address = "192.168.1.49";
        prefixLength = 24;
      }
    ];
  };
  wsl = {
    enable = true;
    defaultUser = "juicy";
    useWindowsDriver = true;
    wslConf = {
      "wsl2" = {
        networkingMode = "mirrored";
      };
    };
  };
  #TODO need to limit to more CLI tools
  boot.isContainer = true;
  boot.kernelModules = [ "nfs" ];
  boot.supportedFilesystems = [
    "btrfs"
    "nfs"
  ];
  services.jellyfin = {
    enable = true;
    group = "media";
    openFirewall = true;
  };
}

{
  config,
  lib,
  modulesPath,
  inputs,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.disko.nixosModules.default
    ./disko.nix
  ];

  boot.kernelModules = [
    "kvm-intel"
    "ip6table_filter"
    "ip_set"
  ];
  boot.extraModulePackages = [ ];
  boot.loader = {
    efi.canTouchEfiVariables = true;
  };
  boot.initrd = {
    availableKernelModules = [
      "xhci_pci"
      "ehci_pci"
      "ata_piix"
      "usb_storage"
      "usbhid"
      "sd_mod"
    ];
    kernelModules = [ ];

    fileSystems."/export/chonk" = {
      device = "/srv/chonk";
      options = [ "bind" ];
    };

    networking = {
      useDHCP = lib.mkDefault false;
      defaultGateway = "192.168.54.99";
      nameservers = [ "192.168.54.99" ];
      hostName = "dante";
      interfaces.enp3s0.ipv4.addresses = [
        {
          address = "192.168.54.60";
          prefixLength = 24;
        }
      ];
    };

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}

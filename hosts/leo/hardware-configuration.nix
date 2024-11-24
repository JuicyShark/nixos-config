{
  config,
  lib,
  modulesPath,
  pkgs,
  nix-config,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    nix-config.inputs.disko.nixosModules.default
  ];
  hardware.keyboard.zsa.enable = true;
  hardware.logitech.wireless.enable = true;

  boot = {
    initrd = {
      availableKernelModules = ["nvme" "xhci_pci" "usb_storage" "sd_mod"];

      kernelModules = [];
    };

    kernelModules = ["kvm-intel" "nfs"];
    kernelParams = [
      "intel_pstate=active"
      "module_blacklist=i915"
      "intel_iommu=on"
      "nouveau.modeset=0"
      "processor.max_cstate=1"
    ];
    supportedFilesystems = ["ntfs" "btrfs" "nfs"];
    extraModulePackages = [];
  };

  swapDevices = [];

  networking.hostName = "leo";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
}

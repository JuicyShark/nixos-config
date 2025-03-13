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

    kernelModules = [
      "kvm-intel"
      "nfs"
    ];
    kernelParams = [
      "intel_pstate=active"
      "acpi_enforce_resources=lax" # Fix ACPI BIOS errors
      "processor.max_cstate=1" # Already present, keep for stability
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1" # Keep NVIDIA memory
      "module_blacklist=i915"
      "intel_iommu=on"
      "nouveau.modeset=0"
    ];
    supportedFilesystems = ["ntfs" "btrfs" "nfs"];
    extraModulePackages = [];
  };

  swapDevices = [];

  networking.hostName = "leo";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
}

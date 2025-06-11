{
  config,
  lib,
  modulesPath,
  pkgs,
  nix-config,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
 #   nix-config.inputs.disko.nixosModules.default
  ];
  hardware.keyboard.zsa.enable = true;
  hardware.logitech.wireless.enable = true;

  boot = {
    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "usb_storage"
        "sd_mod"
      ];

      kernelModules = [ ];
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
    supportedFilesystems = [
      "ntfs"
      "btrfs"
      "nfs"
    ];
    extraModulePackages = [ ];
  };

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/abe7aa06-2f9e-431c-a9f1-5029ff0c3c65";
      fsType = "btrfs";
      options = [ "subvol=@" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/C412-43B2";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };
  swapDevices = [ ];

  networking.hostName = "leo";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}

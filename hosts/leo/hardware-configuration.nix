{
  config,
  lib,
  modulesPath,
  pkgs,
  nix-config,
  ...
}: let
in {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];
  hardware.keyboard.zsa.enable = true;
  hardware.logitech.wireless.enable = true;
  hardware.amdgpu.initrd.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      mesa
      vulkan-loader
      vulkan-tools
    ];
  };

  services.xserver.videoDrivers = lib.mkDefault ["amdgpu"];

  boot = {
    kernel.sysctl = {
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 50;
      "vm.max_map_count" = 2147483642;
      "fs.inotify.max_user_watches" = 524288;
      "fs.file-max" = 2097152;
    };
    initrd = {
      includeDefaultModules = true;
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "usb_storage"
        "sd_mod"
        "vfio-pci"
      ];

      kernelModules = [];
    };

    kernelModules = [
      "vfat"
      "btrfs"
    ];
    blacklistedKernelModules = [
      # Rarely used devices
      "vhba"
      "sr_mod"
      "cdrom"
    ];
    kernelParams = [
      "loglevel=3"
      #AMD adv power tables
      #"amdgpu.ppfeaturemask=0xffffffff"
      # Scheduler tweaks
      "intel_pstate=active"
      "acpi_enforce_resources=lax" # Fix ACPI BIOS errors

      "intel_iommu=on"
      "iommu=pt"
      "mitigations=off"
    ];
    extraModulePackages = [];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/abe7aa06-2f9e-431c-a9f1-5029ff0c3c65";
    fsType = "btrfs";
    options = [
      # "subvol=@"
      "compress=zstd:1"
      "noatime"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/C412-43B2";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [];

  powerManagement.cpuFreqGovernor = "performance";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}

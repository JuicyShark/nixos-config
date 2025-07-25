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

  /*
    environment.systemPackages = with pkgs; [
      ntfs-3g
    ];
  */
  boot = {
    initrd = {
      includeDefaultModules = true;
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "usb_storage"
        "sd_mod"
      ];

      kernelModules = [ ];
    };

    kernelModules = [
      "vfat"
      "btrfs"
      "nvidia"
      "nfs"
    ];
    blacklistedKernelModules = [
      "thunderbolt"
      # Audio stack (if using USB or HDMI only)
      "snd_sof_pci_intel_tgl"
      "snd_sof_pci_intel_cnl"
      "snd_sof_intel_hda_generic"
      "snd_sof_intel_hda_sdw_bpt"
      "snd_sof_intel_hda_common"
      "snd_sof_intel_hda_mlink"
      "snd_sof_intel_hda"
      "snd_sof_pci"
      "snd_sof_xtensa_dsp"
      "snd_sof"
      "soundwire_intel"
      "soundwire_cadence"
      "soundwire_generic_allocation"
      "soundwire_bus"
      "snd_soc_acpi"
      "snd_soc_acpi_intel_match"

      # Rarely used devices
      "vhba"
      "sr_mod"
      "cdrom"
      "loop"
    ];
    kernelParams = [
      "loglevel=3"
      "intel_pstate=active"
      "acpi_enforce_resources=lax" # Fix ACPI BIOS errors
      "processor.max_cstate=1" # Already present, keep for stability

      "nvidia.NVreg_PreserveVideoMemoryAllocations=1" # Keep NVIDIA memory
      "nvidia-drm.fbdev=1"
      "nvidia-drm.modeset=1"

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

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/abe7aa06-2f9e-431c-a9f1-5029ff0c3c65";
    fsType = "btrfs";
    options = [ "subvol=@" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/C412-43B2";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  fileSystems."/mnt/games" = {
    device = "/dev/disk/by-uuid/100E4A9B7EF0C278";
    fsType = "ntfs";
    options = [
      "uid=1000"
      "gid=100"
      "umask=022"
      #    "noatime"
    ];
  };
  swapDevices = [ ];

  networking.hostName = "leo";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}

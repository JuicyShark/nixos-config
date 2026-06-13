{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  hardware = {
    keyboard.zsa.enable = true;
    logitech.wireless.enable = true;
    xone.enable = true;
    amdgpu.initrd.enable = true;
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        mesa
        vulkan-loader
        vulkan-tools
        # VA-API for hardware video decode in browsers and media players
        libva
        libvdpau-va-gl
        # OpenCL via amdgpu (useful for Blender, darktable, etc.)
        rocmPackages.clr.icd
      ];
    };
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };

  services = {
    xserver.videoDrivers = lib.mkDefault ["amdgpu"];
    udev.extraRules = ''
      ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="none"
      ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
    '';
    thermald.enable = true;
  };

  boot = {
    kernel.sysctl = {
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 50;
      "vm.max_map_count" = 1048576;
      "vm.dirty_ratio" = 10;
      "vm.dirty_background_ratio" = 5;
      "vm.compaction_proactiveness" = 0;
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
      # PC speaker beeper noise
      "pcspkr"
      "snd_pcsp"
    ];
    kernelParams = [
      #AMD adv power tables
      #"amdgpu.ppfeaturemask=0xffffffff"
      # Scheduler tweaks
      "intel_pstate=active"
      "acpi_enforce_resources=lax" # Fix ACPI BIOS errors

      "intel_iommu=on"
      "iommu=pt"
      "mitigations=off"

      # Reduce split-lock stalls (affects some Proton/EAC titles on Intel)
      "split_lock_mitigate=0"
      # THP: let apps opt-in (madvise) rather than forcing on/off
      "transparent_hugepage=madvise"
    ];
    extraModulePackages = [];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/abe7aa06-2f9e-431c-a9f1-5029ff0c3c65";
    fsType = "btrfs";
    options = [
      # "subvol=@"
      "compress=zstd:3"
      "noatime"
    ];
  };

  # Persistent subvolume — uncomment after creating @persist on disk
  # and after adding "subvol=@" to the / mount above.
  # fileSystems."/persist" = {
  #   device = "/dev/disk/by-uuid/abe7aa06-2f9e-431c-a9f1-5029ff0c3c65";
  #   fsType = "btrfs";
  #   options = [
  #     "subvol=@persist"
  #     "compress=zstd:1"
  #     "noatime"
  #   ];
  #   neededForBoot = true;
  # };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/C412-43B2";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [
    {
      device = "/dev/disk/by-uuid/02563ce5-9c5b-43a2-9d19-ff61fbf4123c";
    }
  ];

  # NVMe: use none (passthrough to hardware queuing) for best latency
  powerManagement.cpuFreqGovernor = "schedutil";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}

{
  config,
  lib,
  modulesPath,
  pkgs,
  nix-config,
  ...
}:
let

  cpuList = cpus: builtins.concatStringsSep "," (map toString cpus);
  cpuListSpace = cpus: builtins.concatStringsSep " " (map toString cpus);

  irqCores = [
    0
    1
    2
    3
    4
    5
    6
    7
  ];

  irqCoreList = cpuListSpace irqCores;

  eCores = [
    16
    17
    18
    19
  ];

  eCoreMask = cpuList eCores;
  eSlice = {
    CPUAffinity = eCores;
    AllowedCPUs = eCores;
  };

  backgroundServices = [
    "sonarr"
    "radarr"
    "lidarr"
    "prowlarr"
    "deluged"
    "delugeweb"
    "uptime-kuma"
    "prometheus-node-exporter"
    "prometheus-smartctl-exporter"
    "prometheus-deluge-exporter"
    "prometheus-exportarr-lidarr-exporter"
    "prometheus-exportarr-sonarr-exporter"
    "prometheus-exportarr-radarr-exporter"
    "prometheus-exportarr-prowlarr-exporter"
  ];

  backgroundSliceServices = lib.genAttrs backgroundServices (name: {
    serviceConfig.Slice = "background-services.slice";
  });
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];
  hardware.keyboard.zsa.enable = true;
  hardware.logitech.wireless.enable = true;
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "performance";
  };
  boot = {
    # IRQ affinity: restrict IRQs to IRQ cores
    postBootCommands = ''
      mask=0
      for c in ${irqCoreList}; do
        mask=$((mask | (1<<c)))
      done
      printf '%x\n' "$mask" > /proc/irq/default_smp_affinity
    '';

    kernel.sysctl = {
      "net.core.default_qdisc" = "cake";
      "net.ipv4.tcp_congestion_control" = "bbr";
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 50;
      "fs.inotify.max_user_watches" = 524288;
      "fs.file-max" = 2097152;
      "kernel.sched_migration_cost_ns" = 500000;
      "kernel.sched_isolated" = eCoreMask;

    };
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
      # Isolate E-cores
      "isolcpus=${eCoreMask}"
      "nohz_full=${eCoreMask}"
      "rcu_nocbs=${eCoreMask}"
      # Scheduler tweaks
      "intel_pstate=active"
      "sched_idle_cpu"
      "intel_idle.max_cstate=4"
      "processor.max_cstate=4"

      "acpi_enforce_resources=lax" # Fix ACPI BIOS errors

      "nvidia.NVreg_PreserveVideoMemoryAllocations=1" # Keep NVIDIA memory
      "nvidia-drm.fbdev=1"
      "nvidia-drm.modeset=1"

      "module_blacklist=i915"
      "intel_iommu=on"
      "nouveau.modeset=0"
      "nvme.noacpi=1"
      "nvme_core.default_ps_max_latency_us=0"
    ];
    supportedFilesystems = [
      "ntfs"
      "btrfs"
      "nfs"
    ];
    extraModulePackages = [ ];
  };

  # Background services to E-cores
  systemd.slices.background-services = {
    enable = true;
    sliceConfig = eSlice;
  };

  systemd.services = backgroundSliceServices;

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/abe7aa06-2f9e-431c-a9f1-5029ff0c3c65";
    fsType = "btrfs";
    options = [
      "subvol=@"
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

  fileSystems."/mnt/games" = {
    device = "/dev/disk/by-uuid/100E4A9B7EF0C278";
    fsType = "ntfs";
    options = [
      "uid=1000"
      "gid=100"
      "umask=022"
      "windows_names"
      "big_writes"
      "nofail"
      "x-systemd.automount"
      "x-systemd.device-timeout=5s"
    ];
  };

  fileSystems."/srv" = {
    device = "/dev/storage_vg/root";
    fsType = "btrfs";

    options = [
      "noatime"
      "nofail"
      "x-systemd.automount"
      "x-systemd.device-timeout=15s"
    ];
  };

  networking.hostName = "leo";
  networking.networkmanager.ensureProfiles.profiles = {

    static-eth = {
      connection = {
        autoconnect = "true";
        id = "static-eth";
        interface-name = "enp5s0";
        timestamp = "1754152571";
        type = "ethernet";
        uuid = "5686684b-8145-404b-87ba-3ec85eac3991";
      };
      ethernet = {
        mac-address = "74:86:E2:17:7A:24";
      };
      ipv4 = {
        address1 = "192.168.1.54/24";
        dns = "192.168.1.99;";
        gateway = "192.168.1.1";
        ignore-auto-dns = "true";
        method = "manual";
      };
      ipv6 = {
        addr-gen-mode = "default";
        method = "auto";
      };
      proxy = { };
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}

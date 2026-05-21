{
  config,
  lib,
  modulesPath,
  ...
}: {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  boot = {
    initrd.availableKernelModules = [
      "xhci_pci"
      "ahci"
      "nvme"
      "usb_storage"
      "usbhid"
      "sd_mod"
    ];
    initrd.kernelModules = [];
    kernelModules = ["kvm-intel"];
    extraModulePackages = [];
    supportedFilesystems = ["nfs"];
    # Bootloader
    loader.systemd-boot.enable = true;
    kernel = {
      sysctl = {
        "net.ipv4.conf.all.forwarding" = true;
        "net.ipv6.conf.all.forwarding" = true;
      };
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/6dba17bd-db95-4818-ae40-12b0378bfe2e";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/6532-9B98";
      fsType = "vfat";
      options = [
        "fmask=0022"
        "dmask=0022"
      ];
    };

    "/mnt/smol" = {
      device = "192.168.1.54:/srv/smol";
      fsType = "nfs";
      options = [
        "nfsvers=4"
        "x-systemd.automount"
        "x-systemd.idle-timeout=600"
        "noauto"
        "nofail"
        "_netdev"
        "soft"
        "timeo=30"
        "retrans=3"
      ];
    };

    "/srv" = {
      device = "/dev/storage_vg/root";
      fsType = "btrfs";

      options = [
        "noatime"
        "nofail"
        "x-systemd.automount"
        "x-systemd.device-timeout=30s"
      ];
    };

    "/mnt/chonk" = {
      device = "/srv/chonk";
      fsType = "none";
      options = [
        "bind"
        "nofail"
        "x-systemd.requires-mounts-for=/srv"
      ];
    };
  };
  swapDevices = [];

  powerManagement.cpuFreqGovernor = "powersave";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  services.resolved.enable = lib.mkForce false;
  networking.nftables.enable = true;
  networking = {
    useNetworkd = false;
    useDHCP = false;
    wireless.enable = false;
    resolvconf.enable = false;

    firewall = {
      trustedInterfaces = [
        "br0"
        "tailscale0"
      ];

      # Tailscale subnet routing sends packets in on tailscale0 but returns them
      # via br0/enp1s0 — strict reverse path check would drop these.
      checkReversePath = "loose";

      allowedTCPPorts = [
        53
      ];
      allowedUDPPorts = [
        53
        41641
      ];
    };

    nameservers = [
      config.modules.network.hosts.zues
    ];

    nat = {
      enable = true;
      externalInterface = "enp1s0"; # WAN (wired)
      internalInterfaces = ["br0"]; # LAN bridge
    };
    bridges.br0.interfaces = [
      "enp3s0"
      "enp4s0"
    ];
    interfaces.enp1s0.useDHCP = true;

    interfaces.br0.ipv4.addresses = [
      {
        address = "192.168.1.99";
        prefixLength = 24;
      }
    ];
  };
}

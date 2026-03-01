{
  config,
  lib,
  modulesPath,
  ...
}: {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  age.secrets = {
    "cloudflare-token.env" = {
      file = ../../secrets/cloudflare-token.env.age;
      group = config.services.traefik.group;
    };
  };

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

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/6dba17bd-db95-4818-ae40-12b0378bfe2e";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/6532-9B98";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  fileSystems."/mnt/smol" = {
    device = "192.168.1.54:/srv/smol";
    fsType = "nfs";
    options = [
      "nfsvers=4"
      "x-systemd.automount"
      "noauto"
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
  fileSystems."/mnt/chonk" = {
    device = "/srv/chonk";
    fsType = "none";
    options = ["bind"];
  };
  swapDevices = [];

  powerManagement.cpuFreqGovernor = "ondemand";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  services.resolved.enable = lib.mkForce false;
  networking = {
    useNetworkd = false;
    useDHCP = false;
    wireless.enable = false;
    resolvconf.enable = false;

    firewall.trustedInterfaces = [
      "br0"
      "tailscale0"
    ];

    firewall.allowedTCPPorts = [
      22
      53
      80
      443
      20241
    ];
    firewall.allowedUDPPorts = [
      53
      41641
    ];

    nameservers = [
      "192.168.1.99"
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

{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    initrd.availableKernelModules = [
      "xhci_pci"
      "ahci"
      "nvme"
      "usb_storage"
      "usbhid"
      "sd_mod"
    ];
    initrd.kernelModules = [ ];
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
    supportedFilesystems = [ "nfs" ];
    # Bootloader.
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
  fileSystems."/mnt" = {
    device = "192.168.1.54:/srv/chonk";
    fsType = "nfs";
    options = [
      "nfsvers=4"
      "x-systemd.automount"
      "noauto"
    ];
  };
  swapDevices = [ ];

  powerManagement.cpuFreqGovernor = "ondemand";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  services.resolved.enable = false;
  services.dnsmasq.enable = false;
  networking = {
    useNetworkd = true;
    useDHCP = false;
    wireless.enable = false;
    resolvconf.enable = false;

    firewall.trustedInterfaces = [ "br0" ];

    defaultGateway.interface = "br0";
  };
  #services.resolved.enable = true;
  #environment.etc."resolv.conf".source = "/run/systemd/resolve/stub-resolv.conf";

  # Netdev: define the bridge device
  systemd.network.netdevs."10-br0" = {
    netdevConfig = {
      Name = "br0";
      Kind = "bridge";
    };
  };

  # Network: assign IP, gateway, and DNS to br0
  systemd.network.networks."10-br0" = {
    matchConfig.Name = "br0";
    address = [ "192.168.1.99/24" ];
    gateway = [ "192.168.1.1" ];
    dns = [
      "127.0.0.1"
      #"8.8.8.8"
    ];
    networkConfig = {
      DHCP = "no";
      IPv6AcceptRA = false;
      LinkLocalAddressing = "no";
    };
  };
  systemd.network.networks."10-enp1s0" = {
    matchConfig.Name = "enp1s0";
    networkConfig.Bridge = "br0";
  };

  systemd.network.networks."10-enp2s0" = {
    matchConfig.Name = "enp2s0";
    networkConfig.Bridge = "br0";
  };

  systemd.network.networks."10-enp3s0" = {
    matchConfig.Name = "enp3s0";
    networkConfig.Bridge = "br0";
  };

  systemd.network.networks."10-enp4s0" = {
    matchConfig.Name = "enp4s0";
    networkConfig.Bridge = "br0";
  };

  /*
    networking = {

      #   defaultGateway.interface = "br0";

      resolvconf.enable = lib.mkForce true;
      useDHCP = lib.mkForce false;
      wireless.enable = false;

      firewall.trustedInterfaces = [ "br0" ];

      bridges = {
        br0 = {
          interfaces = [
            "enp1s0"
            "enp2s0"
            "enp3s0"
            "enp4s0"
          ];
        };
      };

      interfaces.br0.useDHCP = true;
      interfaces.br0.ipv4.addresses = [
        {
          address = "192.168.1.99";
          prefixLength = 24;
        }
      ];
    };
  */
}

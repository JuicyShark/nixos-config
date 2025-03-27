{...}: {
  disko.devices = {
    # Boot Drive
    disk.main = {
      device = "/dev/sdb";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          swap = {
            size = "4G";
            content = {
              type = "swap";
              resumeDevice = true;
            };
          };
          boot = {
            name = "boot";
            size = "1M";
            type = "EF02";
          };
          esp = {
            name = "ESP";
            size = "500M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          root = {
            name = "root";
            size = "100%";
            content = {
              type = "lvm_pv";
              vg = "root_vg";
            };
          };
        };
      };
    };
    #Tmp Disk
    disk.tmp = {
      device = "/dev/sda";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          root = {
            name = "root";
            size = "100%";
            content = {
              type = "lvm_pv";
              vg = "storage_vg";
            };
          };
        };
      };
    };
    #Storage Disk
    disk.storage = {
      device = "/dev/sdc";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          root = {
            name = "root";
            size = "100%";
            content = {
              type = "lvm_pv";
              vg = "storage_vg";
            };
          };
        };
      };
    };

    lvm_vg = {
      # boot group
      root_vg = {
        type = "lvm_vg";
        lvs = {
          root = {
            size = "100%FREE";
            content = {
              type = "btrfs";
              extraArgs = ["-f"];

              subvolumes = {
                "/root" = {
                  mountpoint = "/";
                };

                "/nix" = {
                  mountOptions = ["subvol=nix" "noatime"];
                  mountpoint = "/nix";
                };
              };
            };
          };
        };
      };
      # Storage group
      storage_vg = {
        type = "lvm_vg";
        lvs = {
          root = {
            size = "100%FREE";
            content = {
              type = "btrfs";
              extraArgs = ["-f"];

              subvolumes = {
                "/chonk" = {
                  mountpoint = "/srv/chonk";
                  mountOptions = ["subvol=storage" "noatime"];
                };
              };
            };
          };
        };
      };
    };
  };
}

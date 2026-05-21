# Impermanence — ephemeral root with declarative opt-in persistence.
#
# The root subvolume (@) is wiped on every boot; only paths listed here
# survive reboots via bind-mounts from /persist (@persist subvolume).
#
# ── One-time btrfs disk preparation ────────────────────────────────────────
# Run from a live USB with the NVMe unmounted:
#
#   ROOT_DEV=/dev/disk/by-uuid/abe7aa06-2f9e-431c-a9f1-5029ff0c3c65
#   mount $ROOT_DEV /mnt/btrfs
#
#   # Wrap the existing root contents in a proper @ subvolume
#   btrfs subvolume snapshot /mnt/btrfs /mnt/btrfs/@
#
#   # Create the persistent subvolume
#   btrfs subvolume create /mnt/btrfs/@persist
#
#   # Seed /persist with what will be needed on first boot
#   mkdir -p /mnt/btrfs/@persist/etc/ssh
#   cp -a /mnt/btrfs/etc/ssh/ssh_host_* /mnt/btrfs/@persist/etc/ssh/
#   cp /mnt/btrfs/etc/machine-id /mnt/btrfs/@persist/etc/machine-id
#   mkdir -p /mnt/btrfs/@persist/var/lib
#   cp -a /mnt/btrfs/var/lib/bluetooth  /mnt/btrfs/@persist/var/lib/ 2>/dev/null || true
#   cp -a /mnt/btrfs/var/lib/NetworkManager /mnt/btrfs/@persist/var/lib/ 2>/dev/null || true
#   mkdir -p "/mnt/btrfs/@persist/home/juicy"
#   # copy ~/.ssh, ~/.gnupg, ~/Documents, etc. as needed
#
#   umount /mnt/btrfs
#
# Then in hardware-configuration.nix:
#   • Add  "subvol=@"  to the options for fileSystems."/"
#   • Uncomment the /persist entry below
#
# Enable the wipe only after the subvolumes are confirmed to exist:
#   modules.impermanence.btrfsWipe = true;
# ───────────────────────────────────────────────────────────────────────────
{
  inputs,
  config,
  lib,
  ...
}: let
  cfg = config.modules.impermanence;
  inherit (config.modules.system) username;
  persist = cfg.persistBase;
in {
  imports = [inputs.impermanence.nixosModules.impermanence];

  options.modules.impermanence = {
    enable = lib.mkEnableOption "ephemeral root with opt-in persistence";

    persistBase = lib.mkOption {
      type = lib.types.str;
      default = "/persist";
      description = "Mount point for the persistent btrfs subvolume (@persist).";
    };

    btrfsWipe = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Recreate the btrfs @ subvolume from scratch on each boot, wiping all
        ephemeral state.  Requires @ and @persist to exist on disk and / to
        be mounted with subvol=@ in hardware-configuration.nix.
        Enable only after the one-time disk preparation above is complete.
      '';
    };

    rootUuid = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "UUID of the btrfs root device. Required when btrfsWipe = true.";
    };
  };

  config = lib.mkIf cfg.enable {
    # ── btrfs rollback ──────────────────────────────────────────────────────
    # Runs in initrd: stash the old @ with a timestamp, delete roots older
    # than 30 days, then create a fresh empty @ for this boot.
    boot.initrd.supportedFilesystems = ["btrfs"];

    boot.initrd.postDeviceCommands = lib.mkIf cfg.btrfsWipe (lib.mkAfter ''
      mkdir /btrfs_tmp
      mount /dev/disk/by-uuid/${cfg.rootUuid} /btrfs_tmp
      if [[ -e /btrfs_tmp/@ ]]; then
        mkdir -p /btrfs_tmp/old_roots
        timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/@)" "+%Y-%m-%-d_%H:%M:%S")
        mv /btrfs_tmp/@ "/btrfs_tmp/old_roots/$timestamp"
      fi
      delete_subvolume_recursively() {
        IFS=$'\n'
        for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
          delete_subvolume_recursively "/btrfs_tmp/$i"
        done
        btrfs subvolume delete "$1"
      }
      for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
        delete_subvolume_recursively "$i"
      done
      btrfs subvolume create /btrfs_tmp/@
      umount /btrfs_tmp
    '');

    # allow_other lets root access user bind-mounts (needed for agenix)
    programs.fuse.userAllowOther = true;

    # ── System-level persistence ────────────────────────────────────────────
    environment.persistence.${persist} = {
      hideMounts = true;
      directories =
        [
          "/etc/ssh" # SSH host keys — also used as agenix identity
          "/var/lib/bluetooth" # Bluetooth device pairings
          "/var/lib/colord" # Monitor colour calibration
          "/var/lib/systemd/coredump"
          "/var/db/sudo/lectured"
        ]
        ++ lib.optionals config.modules.desktop.enable [
          "/var/lib/NetworkManager" # Wi-Fi passwords, VPN configs
        ];
      files = [
        "/etc/machine-id" # Stable systemd/journal identity
      ];
    };

    # ── Home persistence ────────────────────────────────────────────────────
    home-manager.users.${username} = {
      home.persistence."${persist}" = {
        directories =
          [
            # ── Personal directories ────────────────────────────────────────
            "Documents"
            "Downloads"
            "Pictures"
            "Videos"
            "Music"
            "projects"
            "media"

            # ── Credentials ─────────────────────────────────────────────────
            ".ssh"
            ".gnupg"

            # ── Shell & editor state ─────────────────────────────────────────
            ".local/share/atuin" # Shell history (synced + local)
            ".local/share/nvim" # Neovim undo history, shada
            ".local/share/zoxide" # Directory jump database
            ".local/share/fish" # Fish history & functions
            ".local/share/bash" # Bash history

            # ── Browsers ────────────────────────────────────────────────────
            ".config/vivaldi" # Profile, bookmarks, extensions
            ".config/qutebrowser" # Config overrides, quickmarks, history

            # ── Steam & game saves ───────────────────────────────────────────
            # ~/.steam/steamcompat and ~/.steam/shadercache are the bind-mount
            # sources for /mnt/games/.../compatdata and .../shadercache.
            # They must persist so Wine prefixes and shader caches survive.
            ".steam"
            ".local/share/Steam" # userdata (Steam Cloud saves), screenshots

            # Game saves not covered by Steam Cloud:
            ".config/unity3d" # Unity engine saves
            ".local/share/games" # FHS-compliant native game saves

            # ── Media & entertainment ────────────────────────────────────────
            ".local/share/tidal-hifi"
            ".config/tidal-hifi"
          ]
          ++ lib.optionals config.modules.desktop.bloat.enable [
            # ── Communications ───────────────────────────────────────────────
            ".config/vesktop"
            ".config/discord"
            ".config/Signal"
          ]
          ++ lib.optionals config.modules.system.keyboard.zsa [
            ".local/share/keymapp"
          ];

        files = [
          ".local/share/recently-used.xbel"
        ];
      };
    };
  };
}

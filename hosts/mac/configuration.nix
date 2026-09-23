{
  homeProfiles,
  config,
  lib,
  pkgs,
  ...
}: let
  loginHome = config.users.users.${config.modules.profile.username}.home;
  nfsMountRoot = "/Volumes";
  leoPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILUlQ0gc5NIpsO3qPU7NR9NF8DobGXlhlmVzP944USPC juicy@leo";
  nfsAutofsBootstrap = pkgs.writeShellScript "nfs-autofs-bootstrap" ''
    set -eu

    # `install -d` chmods existing autofs triggers, which macOS rejects once
    # the NFS volumes are mounted. `mkdir -p` only creates missing triggers.
    /bin/mkdir -p ${nfsMountRoot}/chonk ${nfsMountRoot}/smol
    /usr/sbin/automount -vc

    # Exit unsuccessfully until both direct-map triggers exist. launchd then
    # retries the one-shot job until the shared volumes are available.
    /sbin/mount | /usr/bin/grep -q "map auto_nfs on ${nfsMountRoot}/chonk"
    /sbin/mount | /usr/bin/grep -q "map auto_nfs on ${nfsMountRoot}/smol"
  '';
in {
  imports = [
    ../../modules/darwin/system.nix
    ../../modules/common/shell.nix
    ../../modules/common/stylix.nix
    ../../modules/common/local-models.nix
    ../../modules/darwin/ollama.nix
    ./jellyfin.nix
  ];

  modules = {
    # smol owns the configuration source; autofs mounts it on demand.
    profile.flakePath = "${nfsMountRoot}/smol/nixos-config";
    shell = {
      dev.enable = true;
      atuin.syncUrl = "http://atuin.home.arpa";
    };
    localModels = {
      enable = true;
      endpoint = "http://192.168.1.47:11434";
    };
    ollama = {
      enable = true;
      # Bind only the trusted LAN address: Ollama's API has no authentication.
      listenAddress = "192.168.1.47";
    };
  };

  networking.hostName = "mac";
  home-manager.sharedModules = homeProfiles.darwin;

  # A native direct map lets access to either path trigger its NFS mount. The
  # map is immutable in the system generation; auto_master is reconciled below.
  environment.etc.auto_nfs.text = ''
    ${nfsMountRoot}/chonk -fstype=nfs,rw,intr,resvport,vers=4.0,hard,nolocallocks,tcp,nobrowse 192.168.1.99:/srv/chonk
    ${nfsMountRoot}/smol -fstype=nfs,rw,intr,resvport,vers=4.1,hard,tcp,nobrowse 192.168.1.54:/srv/smol
  '';

  # /Volumes is ephemeral across boots. Reconcile the direct map immediately
  # during activation; the launchd job below repeats this ordering at boot.
  system.activationScripts.etc.text = lib.mkAfter ''
    /bin/mkdir -p ${nfsMountRoot}/chonk ${nfsMountRoot}/smol
    /bin/ln -sfn ${nfsMountRoot}/chonk ${loginHome}/chonk

    auto_master=/etc/auto_master
    fstab=/etc/fstab
    auto_master_tmp=$(/usr/bin/mktemp /tmp/nix-darwin-auto-master.XXXXXX)
    fstab_tmp=$(/usr/bin/mktemp /tmp/nix-darwin-fstab.XXXXXX)

    # Normalize our master-map entry while preserving all Apple/user entries.
    /usr/bin/awk '!/^[[:space:]]*\/-[[:space:]]+auto_nfs([[:space:]]|$)/' \
      "$auto_master" > "$auto_master_tmp"
    /usr/bin/printf '%s\n' '/- auto_nfs -nosuid' >> "$auto_master_tmp"
    /usr/bin/install -o root -g wheel -m 0644 "$auto_master_tmp" "$auto_master"

    # Remove the superseded NFS fstab block while retaining the /nix APFS row
    # and every other installer/user entry.
    /usr/bin/awk '
      $0 == "# BEGIN nix-darwin network mounts" { skip = 1; next }
      $0 == "# END nix-darwin network mounts" { skip = 0; next }
      !skip { print }
    ' "$fstab" > "$fstab_tmp"
    /usr/bin/install -o root -g wheel -m 0644 "$fstab_tmp" "$fstab"
    /bin/rm -f "$auto_master_tmp" "$fstab_tmp"

    # Refresh direct-map triggers after both files are in their final state.
    /usr/sbin/automount -vc
  '';

  launchd.daemons.nfs-autofs-bootstrap.serviceConfig = {
    ProgramArguments = [
      "/bin/sh"
      "${nfsAutofsBootstrap}"
    ];
    RunAtLoad = true;
    KeepAlive.SuccessfulExit = false;
    ProcessType = "Background";
    ThrottleInterval = 10;
    StandardOutPath = "/var/log/nfs-autofs-bootstrap.log";
    StandardErrorPath = "/var/log/nfs-autofs-bootstrap.log";
  };

  # Remote Login and its authorized key are mutable macOS state. Reconcile
  # both during activation so a reboot cannot strand this headless host.
  system.activationScripts.postActivation.text = lib.mkAfter ''
    /usr/bin/install -d -o ${config.modules.profile.username} -g staff -m 0700 ${loginHome}/.ssh
    /usr/bin/grep -qxF ${lib.escapeShellArg leoPublicKey} ${loginHome}/.ssh/authorized_keys 2>/dev/null \
      || /bin/echo ${lib.escapeShellArg leoPublicKey} >> ${loginHome}/.ssh/authorized_keys
    /usr/sbin/chown ${config.modules.profile.username}:staff ${loginHome}/.ssh/authorized_keys
    /bin/chmod 0600 ${loginHome}/.ssh/authorized_keys
    /usr/sbin/systemsetup -setremotelogin on >/dev/null
  '';

  # The shared checkout is exported by Leo as uid 1000, not the Mac's local
  # uid. Trust this one canonical path rather than disabling Git's ownership
  # check globally.
  home-manager.users.${config.modules.profile.username}.programs.git.settings.safe.directory =
    config.modules.profile.flakePath;

  # Weekly GC otherwise leaves every Darwin system generation as a live root.
  nix.gc.options = "--delete-older-than 7d";

  # Keep genuinely prefixed GNU core utilities without shadowing macOS sed,
  # tar, or find with packages that do not expose the claimed g* commands.
  environment.systemPackages = [pkgs.coreutils-prefixed];

  # Tailscale is installed and enrolled outside nix-darwin on this host.
  # If moving daemon ownership into Nix later, enroll against the standard
  # Tailscale control plane with: tailscale up --accept-routes --accept-dns=false
  services.tailscale.enable = false;
}

{
  self,
  homeProfiles,
  config,
  pkgs,
  ...
}: {
  imports = with self.darwinModules; [
    system
    shell
    stylix
    emacs
    jellyfin
    minecraft
  ];

  modules = {
    emacs.enable = true;
    shell.dev.enable = true;
    jellyfin.enable = true;
    minecraft.server = {
      enable = true;
      pack = "skyfactory5";
    };
  };

  networking.hostName = "mac";
  environment.variables.FLAKE = "/Users/${config.modules.profile.username}/nixos-config";
  home-manager.sharedModules = homeProfiles.darwin;

  # GNU userland parity with Linux hosts (prefixed as g* — gsed, gtar, gfind, etc.)
  environment.systemPackages = with pkgs; [
    coreutils-prefixed
    gnused
    gnutar
    findutils
    input-leap
    mas
    switchaudio-osx
  ];

  launchd.user.agents.input-leap-client = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.input-leap}/bin/input-leapc"
        "-f"
        "-n"
        "mac"
        "leo:24800"
      ];
      KeepAlive = true;
      RunAtLoad = true;
      ProcessType = "Interactive";
      StandardOutPath = "/tmp/input-leap-client.log";
      StandardErrorPath = "/tmp/input-leap-client.log";
    };
    managedBy = "hosts.mac.input-leap";
  };

  # Tailscale is installed and enrolled outside nix-darwin on this host.
  # If moving daemon ownership into Nix later, enroll against the standard
  # Tailscale control plane with: tailscale up --accept-routes --accept-dns=false
  services.tailscale.enable = false;
}

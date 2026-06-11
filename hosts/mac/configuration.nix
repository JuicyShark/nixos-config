{
  self,
  homeProfiles,
  pkgs,
  ...
}: {
  imports = with self.darwinModules; [
    system
    shell
    stylix
    emacs
  ];

  modules = {
    emacs.enable = true;
  };

  networking.hostName = "mac";
  environment.variables.FLAKE = "/Users/juicy/nixos-config";
  home-manager.sharedModules = homeProfiles.darwin;

  # GNU userland parity with Linux hosts (prefixed as g* — gsed, gtar, gfind, etc.)
  environment.systemPackages = with pkgs; [
    coreutils-prefixed
    gnused
    gnutar
    findutils
    mas
  ];

  # nix-darwin tailscale module only manages the daemon.
  # After first login run:
  #   tailscale up --login-server=https://ts.nixlab.au --accept-routes --accept-dns=false
  services.tailscale.enable = true;
}

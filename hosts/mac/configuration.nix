{
  self,
  homeProfiles,
  pkgs,
  ...
}: {
  imports =
    (with self.darwinModules; [system])
    ++ [
      (self + "/modules/nixos/shell.nix")
      (self + "/modules/nixos/stylix.nix")
      (self + "/modules/nixos/emacs.nix")
    ];

  modules = {
    system = {
      flakePath = "/Users/juicy/nixos-config";
      hostName = "mac";
      homeModules = homeProfiles.darwin;
    };
    emacs.enable = true;
  };

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

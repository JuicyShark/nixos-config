{lib, ...}: {
  services = import ./services.nix {inherit lib;};
}

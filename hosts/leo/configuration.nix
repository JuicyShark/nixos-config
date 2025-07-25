{
  nix-config,
  config,
  pkgs,
  ...
}:
let
  inherit (builtins) attrValues;
in
{
  imports = attrValues nix-config.nixosModules;
  home-manager.sharedModules = attrValues nix-config.homeModules;
  environment.systemPackages = attrValues nix-config.packages.${pkgs.system};
  environment.sessionVariables.FLAKE = "/mnt/chonk/nixos-config";
  age.secrets.juicy-password = {
    file = ../../secrets/juicy-password.age;
  };

  modules = {
    router.enable = false;
    hardware = {
      bluetooth = true;
      nvidia.enable = true;
    };

    system = {
      mullvad = false;
      iHaveLotsOfRam = true;
      username = "juicy";
      hostName = "leo";

      #hashedPassword = config.age.secrets.juicy-password.path;
    };

    desktop = {
      enable = true;
      wallpapers = {
        "32:9".enable = false;
      };
      apps = {
        emacs = true;
        llm = false;
        bloat = true;
        gaming = true;
        streaming = true;
        virtual = false;
      };
    };
  };
}

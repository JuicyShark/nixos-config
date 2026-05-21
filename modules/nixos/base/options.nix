{lib, ...}: let
  inherit (lib.types) deferredModule listOf nullOr str;
  inherit (lib) mkOption mkEnableOption;
  mkStrOption = default:
    mkOption {
      type = str;
      inherit default;
    };
in {
  options.modules.system = {
    username = mkStrOption "juicy";
    hashedPasswordFile = mkOption {
      type = nullOr str;
      default = null;
    };
    hostName = mkStrOption "nixos";
    flakePath = mkOption {
      type = nullOr str;
      default = null;
      description = "Absolute path where this flake is checked out on the host. Sets the FLAKE env var when non-null.";
    };
    homeModules = mkOption {
      type = listOf deferredModule;
      default = [];
      description = "Home Manager modules imported for the primary user on this host.";
    };

    keyboard.zsa = mkEnableOption "ZSA keyboard firmware (keymapp + kontroll)";
    highMemory.enable = mkEnableOption "high-RAM optimizations (tmpfs for /tmp)";

    mullvad.enable = mkEnableOption "Mullvad VPN client";
    openSrb2Port = mkEnableOption "SRB2 multiplayer firewall port (UDP 5029)";
    openDevPort = mkEnableOption "development server firewall port (TCP 3000)";
  };
}

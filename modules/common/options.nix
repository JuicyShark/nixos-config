{lib, ...}: {
  options.modules = {
    profile = {
      username = lib.mkOption {
        type = lib.types.str;
        default = "juicy";
        description = "Primary user managed by this configuration.";
      };

      homeDirectory = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Primary user's home directory; defaults by platform when unset.";
      };

      homeStateVersion = lib.mkOption {
        type = lib.types.str;
        default = "25.11";
        description = "Home Manager state version for the primary user.";
      };

      hashedPasswordFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Optional age-managed hashed password file for the primary user.";
      };
    };

    system = {
      keyboard.zsa = lib.mkEnableOption "ZSA keyboard firmware (keymapp + kontroll)";
      highMemory.enable = lib.mkEnableOption "high-RAM optimizations (tmpfs for /tmp)";

      mullvad.enable = lib.mkEnableOption "Mullvad VPN client";
      openSrb2Port = lib.mkEnableOption "SRB2 multiplayer firewall port (UDP 5029)";
      openDevPort = lib.mkEnableOption "development server firewall port (TCP 3000)";
    };
  };
}

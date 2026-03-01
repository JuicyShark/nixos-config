# Security Configuration
#
# Manages SSH, sudo, PAM, and security-related settings.
# Extracted from system.nix for better modularity.

{
  nix-config,
  system,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.system;
  inherit (nix-config.lib.${system}.roles) mkHasRole;
  hasRole = mkHasRole config;
in
{
  config = {
    services.openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        PubkeyAuthentication = true;
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        X11Forwarding = false;
        UseDns = false;
      };
    };

    programs = {
      command-not-found.enable = true;
      ssh.startAgent = false;
    };

    security.sudo.extraConfig = ''
      Defaults env_keep += "EDITOR VISUAL"
    '';

    security.pam.sshAgentAuth = {
      enable = true;
      authorizedKeysFiles = [ "/etc/ssh/authorized_keys.d/%u" ];
    };

    # Hardware-specific security
    hardware.keyboard.zsa.enable = mkIf (hasRole "keyboard-zsa") true;
  };
}

{
  pkgs,
  osConfig,
  lib,
  ...
}: {
  programs.chromium = {
    enable = builtins.elem "desktop" osConfig.modules.system.roles;
    package = pkgs.chromium;

    commandLineArgs = [
      #"--extension-mime-request-handling=always-prompt-for-install"
      # "--webrtc-ip-handling-policy=default_public_interface_only"
    ];
  };
}

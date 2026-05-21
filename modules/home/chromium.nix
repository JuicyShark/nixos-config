{
  pkgs,
  osConfig,
  lib,
  ...
}:
lib.mkIf (osConfig.modules.desktop.enable or false) {
  programs.chromium = {
    enable = true;
    package = pkgs.chromium;

    commandLineArgs = [
      #"--extension-mime-request-handling=always-prompt-for-install"
      # "--webrtc-ip-handling-policy=default_public_interface_only"
    ];
  };
}

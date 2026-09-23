{
  pkgs,
  osConfig,
  lib,
  ...
}:
lib.mkIf (osConfig.modules.desktop.enable or false) {
  programs.firefox = {
    enable = true;
    package = pkgs.firefox;
    configPath = ".config/firefox";

    profiles.default = {
      id = 0;
      isDefault = true;
      settings =
        {
          "browser.fullscreen.autohide" = false;
        }
        // lib.optionalAttrs (osConfig.modules.desktop.terminalFileChooser.enable or false) {
          "widget.use-xdg-desktop-portal.file-picker" = 1;
        };
    };
  };

  stylix.targets.firefox.profileNames = ["default"];
}

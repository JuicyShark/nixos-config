{
  osConfig,
  lib,
  pkgs,
  ...
}: let
  browserDesktop = "chromium-browser.desktop";
  editorDesktop = "nvim.desktop";
  filesDesktop = "yazi.desktop";
in
  lib.mkIf (pkgs.stdenv.isLinux && (osConfig.modules.desktop.enable or false)) {
    xdg.mimeApps = {
      enable = true;

      defaultApplications = {
        "text/html" = browserDesktop;
        "x-scheme-handler/http" = browserDesktop;
        "x-scheme-handler/https" = browserDesktop;
        "text/markdown" = editorDesktop;
        "text/plain" = editorDesktop;
        "inode/directory" = filesDesktop;
        "image/png" = "imv.desktop";
        "image/jpeg" = "imv.desktop";
        "image/gif" = "imv.desktop";
      };
    };
  }

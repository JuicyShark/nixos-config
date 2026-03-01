{
  nix-config,
  system,
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  inherit (nix-config.lib.${system}.roles) mkHasRoleHome;
  hasRole = mkHasRoleHome osConfig;
  browserDesktop =
    if hasRole "desktop-bloat" then "vivaldi-stable.desktop" else "chromium-browser.desktop";
  editorDesktop = "nvim.desktop";
  filesDesktop = "yazi.desktop";
in
lib.mkIf (hasRole "desktop") {
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

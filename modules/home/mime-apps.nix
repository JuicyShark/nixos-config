{
  osConfig,
  lib,
  pkgs,
  ...
}: let
  browserDesktop = "chromium-browser.desktop";
  editorDesktop =
    if osConfig.modules.emacs.enable or false
    then "emacsclient.desktop"
    else "nvim.desktop";
  filesDesktop = "thunar.desktop";
  editorMimeTypes = [
    "application/ecmascript"
    "application/javascript"
    "application/json"
    "application/sql"
    "application/toml"
    "application/typescript"
    "application/x-cmake"
    "application/x-desktop"
    "application/x-docbook+xml"
    "application/x-shellscript"
    "application/x-yaml"
    "application/xml"
    "text/css"
    "text/csv"
    "text/html"
    "text/markdown"
    "text/plain"
    "text/rust"
    "text/x-c"
    "text/x-c++"
    "text/x-c++hdr"
    "text/x-c++src"
    "text/x-chdr"
    "text/x-cmake"
    "text/x-csrc"
    "text/x-dockerfile"
    "text/x-go"
    "text/x-java"
    "text/x-kotlin"
    "text/x-lua"
    "text/x-makefile"
    "text/x-meson"
    "text/x-nix"
    "text/x-python"
    "text/x-rust"
    "text/x-script.python"
    "text/x-shellscript"
    "text/x-toml"
    "text/x-yaml"
  ];
in
  lib.mkIf (pkgs.stdenv.isLinux && (osConfig.modules.desktop.enable or false)) {
    xdg.mimeApps = {
      enable = true;

      defaultApplications =
        lib.genAttrs editorMimeTypes (_: editorDesktop)
        // {
          "x-scheme-handler/http" = browserDesktop;
          "x-scheme-handler/https" = browserDesktop;
          "inode/directory" = filesDesktop;
          "image/png" = "imv.desktop";
          "image/jpeg" = "imv.desktop";
          "image/gif" = "imv.desktop";
        };
    };
  }

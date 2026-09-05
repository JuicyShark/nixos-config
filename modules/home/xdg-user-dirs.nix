{
  config,
  pkgs,
  osConfig,
  lib,
  ...
}: let
  inherit (config.home) homeDirectory;
in
  lib.mkIf ((osConfig.modules.desktop.enable or false) || pkgs.stdenv.hostPlatform.isDarwin) {
    xdg = {
      userDirs = {
        enable = true;
        createDirectories = true;
        setSessionVariables = false;

        templates = null;
        publicShare = null;
        desktop = homeDirectory;
        download = "${homeDirectory}/tmp";
        documents = "${homeDirectory}/documents";
        music = "${homeDirectory}/music";
        pictures = "${homeDirectory}/pictures";
        videos = "${homeDirectory}/videos";
        projects = "${homeDirectory}/projects";
      };

      configFile."user-dirs.locale".text = "en_AU";
    };
  }

{
  config,
  pkgs,
  osConfig,
  lib,
  ...
}: let
  inherit (config.home) homeDirectory;
in
  lib.mkIf ((osConfig.modules.desktop.enable or false) || pkgs.stdenv.isDarwin) {
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
        music = "${homeDirectory}/media/music";
        pictures = "${homeDirectory}/media/pictures";
        videos = "${homeDirectory}/media/videos";
        projects = "${homeDirectory}/projects";
      };

      configFile."user-dirs.locale".text = "en_AU";
    };
  }

{ config, nixosConfig, ... }:

let
  inherit (config.home) homeDirectory;

in
{

  xdg = {
    userDirs = {
      enable = true;
      createDirectories = true;

      templates = null;
      publicShare = null;
      desktop = homeDirectory;
      download = "${homeDirectory}/tmp";
      documents = "${homeDirectory}/documents";
      music = "${homeDirectory}/media/music";
      pictures = "${homeDirectory}/media/pictures";
      videos = "${homeDirectory}/media/videos";
    };

    configFile."user-dirs.locale".text = "en_AU";
  };
}

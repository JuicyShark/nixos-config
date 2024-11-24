{ config, nixosConfig, ... }:

let
  inherit (config.home) homeDirectory;

  isPhone = nixosConfig.programs.calls.enable;
in
{

  xdg = {
    userDirs = {
      enable = true;
      createDirectories = true;

      templates = null;
      publicShare = null;
      desktop = homeDirectory;
      download = if isPhone then homeDirectory else "${homeDirectory}/tmp";
      documents = if isPhone then homeDirectory else "${homeDirectory}/documents";
      music = if isPhone then homeDirectory else "${homeDirectory}/media/music";
      pictures = if isPhone then homeDirectory else "${homeDirectory}/media/pictures";
      videos = if isPhone then homeDirectory else "${homeDirectory}/media/videos";
    };

    configFile."user-dirs.locale".text = "en_AU";
  };
}

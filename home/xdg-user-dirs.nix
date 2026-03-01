{
  config,
  nixosConfig,
  osConfig,
  lib,
  ...
}: let
  inherit (config.home) homeDirectory;
  /*
  hasChonk = nixosConfig.fileSystems ? "/mnt/chonk";
  hasGames = nixosConfig.fileSystems ? "/mnt/games";
  hasTorrents = nixosConfig.fileSystems ? "/mnt/torrents";
  */
in
  lib.mkIf (builtins.elem "desktop" osConfig.modules.system.roles) {
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
    /*
    home.file = lib.mkMerge [
      (lib.optionalAttrs hasChonk {
        "documents/media".source = "/mnt/chonk/media";
        "chonk".source = "/mnt/chonk";
      })
      (lib.optionalAttrs hasGames {
        "games".source = "/mnt/games";
      })
      (lib.optionalAttrs hasTorrents {
        "torrents".source = "/mnt/torrents";
      })
    ];
    */
  }

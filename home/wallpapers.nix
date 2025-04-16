{
  config,
  osConfig,
  pkgs,
  lib,
  ...
}:
# TODO currently only fetchs Superwide backgrounds. grab 21:9 and 16:9 too
let
  xdgPictures = config.xdg.userDirs.pictures;
  wallpapersDir = "${xdgPictures}/wallpapers";

  repo = pkgs.fetchFromGitHub {
    owner = "nodesleep";
    repo = "dual-monitor-wallpapers";
    rev = "main";
    sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Run once to get real hash
  };

  imageFiles = builtins.filter (file: lib.hasSuffix ".jpg" file || lib.hasSuffix ".png" file) (
    builtins.attrNames (builtins.readDir repo)
  );
in
{
  config = lib.mkIf osConfig.modules.desktop.wallpapers."32:9".enable {
    home.activation.linkWallpapers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "${wallpapersDir}/32:9"
      ${lib.concatStringsSep "\n" (
        map (file: ''ln -sf "${repo}/${file}" "${wallpapersDir}/${file}"'') imageFiles
      )}
    '';
  };
}

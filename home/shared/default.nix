{ osConfig, lib, ... }:
let
  homeCli = lib.listFilesRecursive ./cli;
  homeDesktop = lib.listFilesRecursive ./desktop;
in
{
  import =
    lib.concatLists [
      homeCli
    ]
    ++ lib.optionals osConfig.modules.desktop.enable [ homeDesktop ];
}

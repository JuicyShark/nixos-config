{
  pkgs,
  lib,
  osConfig,
  ...
}:
{
  home.packages =
    with pkgs;
    lib.mkIf osConfig.modules.desktop.enable [
      icoextract
      thud
    ];

  xdg.configFile."xfce4/helpers.rc".text =
    # ini
    ''
      TerminalEmulator=kitty
      TerminalEmulatorDismissed=true
    '';
}

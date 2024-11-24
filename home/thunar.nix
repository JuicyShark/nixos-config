{pkgs, ...}: {
  home.packages = with pkgs; [icoextract thud];

  xdg.configFile."xfce4/helpers.rc".text =
    # ini
    ''
      TerminalEmulator=foot
      TerminalEmulatorDismissed=true
    '';
}

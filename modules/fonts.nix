{ pkgs, ... }:
{
  fonts = {
    enableDefaultPackages = false;

    packages = with pkgs; [
      roboto-serif
    ];

    fontconfig = {
      defaultFonts = {
        serif = [ "Mononoki Nerd Font" ];
        sansSerif = [ "Iosevka Nerd Font" ];
        monospace = [
          #"ShureTechMono Nerd Font"
          "IosevkaTerm Nerd Font Mono"
        ];
      };

      allowBitmaps = false;
    };
  };
}

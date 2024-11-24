{pkgs, ...}: {
  home.packages = with pkgs; [
    libsixel # display images inline
  ];
  xdg.mimeApps = {
    associations.added = {"x-scheme-handler/terminal" = "foot.desktop";};
    defaultApplications = {"x-scheme-handler/terminal" = "foot.desktop";};
  };
  programs.foot = {
    enable = true;
    server.enable = true;
    settings = {
      main = {
        app-id = "terminal";
        #title = "terminal";
        locked-title = "no";
        term = "foot-direct";
        pad = "2x0";
        shell = "zsh";

        resize-delay-ms = 25;

        selection-target = "both";
        bold-text-in-bright = "yes";

        box-drawings-uses-font-glyphs = "no";
      };

      bell = {
        urgent = "yes";
        notify = "yes";
      };

      scrollback = {
        lines = 10000;
        multiplier = "3.5";
      };

      tweak = {
        font-monospace-warn = "no"; # reduces startup time
        #allow-overflowing-double-width-glyphs = true;
        sixel = "yes";
      };

      cursor = {
        style = "block";
        unfocused-style = "hollow";
        beam-thickness = 2;
      };

      mouse = {hide-when-typing = "no";};

      url = {
        launch = "xdg-open \${url}";
        label-letters = "arstgneioqwfpluycdhz";
        osc8-underline = "url-mode";
        protocols = "http, https, ftp, ftps, file, git, irc, ircs, news, sftp, ssh";
        uri-characters = ''
          abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.,~:;/?#@!$&%*+="'()[]'';
      };
    };
  };
}

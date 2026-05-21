{
  osConfig,
  pkgs,
  lib,
  ...
}: {
  xdg.configFile =
    {
      "yazi/init.lua".text = ''
        Header:children_add(function()
         if ya.target_family() ~= "unix" then
          return ui.Line {}
         end
         return ui.Span(ya.user_name() .. "@" .. ya.host_name() .. ":"):fg("blue")
        end, 500, Header.LEFT)
      '';
    }
    // lib.optionalAttrs (pkgs.stdenv.isLinux && (osConfig.modules.desktop.enable or false)) {
      "xdg-desktop-portal-termfilechooser/config".text = ''
        [filechooser]
        cmd=yazi-wrapper.sh
        default_dir=$HOME
        env=TERMCMD=kitty --title 'termfilechooser'
        open_mode=suggested
        save_mode=suggested
      '';
    };

  home.packages = with pkgs; [poppler];

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    shellWrapperName = "y";
    plugins = lib.mkMerge [
      (lib.mkIf (!pkgs.stdenv.isDarwin) {
        inherit (pkgs.yaziPlugins) dupes;
      })
    ];
    settings = {
      mgr = {
        sort_dir_first = true;
        linemode = "mtime";

        ratio = [
          2
          3
          3
        ];
      };

      preview = {
        tab_size = 4;
        image_filter = "lanczos3";
        max_width = 5120;
        max_height = 3440;
        image_quality = 90;
      };
    };

    keymap = {
      mgr.prepend_keymap = [
        {
          run = "remove --force";
          on = ["d"];
        }
      ];
    };
  };
}

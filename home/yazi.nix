{
  config,
  pkgs,
  ...
}: {
  xdg.configFile."yazi/init.lua".text = ''
    Header:children_add(function()
     if ya.target_family() ~= "unix" then
      return ui.Line {}
     end
     return ui.Span(ya.user_name() .. "@" .. ya.host_name() .. ":"):fg("blue")
    end, 500, Header.LEFT)
  '';
  home.packages = with pkgs; [poppler];

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    shellWrapperName = "y";
    plugins = {
      dupes = pkgs.yaziPlugins.dupes;
    };
    settings = {
      mgr = {
        sort_dir_first = true;
        linemode = "mtime";

        ratio = [
          1
          2
          4
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

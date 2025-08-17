{
  config,
  pkgs,
  ...
}:
{
  xdg.configFile."yazi/init.lua".text = ''
    Header:children_add(function()
     if ya.target_family() ~= "unix" then
      return ui.Line {}
     end
     return ui.Span(ya.user_name() .. "@" .. ya.host_name() .. ":"):fg("blue")
    end, 500, Header.LEFT)
  '';
  home.packages = with pkgs; [
    p7zip
    jq
    poppler
  ];

  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    shellWrapperName = "y";

    settings = {
      mgr = {
        sort_by = "alphabetical";
        show_hidden = true;
        sort_dir_first = true;
        linemode = "mtime";

        ratio = [
          1
          3
          5
        ];
      };

      preview = {
        tab_size = 4;
        image_filter = "lanczos3";
        max_width = 1920;
        max_height = 1080;
        image_quality = 90;
      };

      /*
        opener = {
          pdf = [
            {
              run = "zathura $@";
              desc = "zathura";
              block = false;
            }
          ];
          image = [
            {
              run = "timg $0";
              desc = "timg";
              block = false;
            }
            {
              run = "gimp $@";
              desc = "gimp";
              block = false;
            }
          ];
          text = [
            {
              run = "less $0";
              desc = "less";
              block = true;
            }
            {
              run = "bat $0";
              desc = "bat";
              block = true;
            }
          ];
          edit = [
            {
              run = "edit-in-kitty $@";
              block = true;
              for = "unix";
            }
          ];
          video = [
            {
              run = "${config.programs.mpv.package}/bin/umpv $1";
              desc = "mpv";
              block = false;
            }
          ];
          audio = [
            {
              run = "${config.programs.mpv.package}/bin/umpv --force-window $1";
              desc = "mpv";
              block = false;
            }
          ];
          unzip = [
            {
              run = "7z x -y $@";
              for = "unix";
            }
          ];
          app-image = [
            {
              run = "appimage-run $0";
              for = "unix";
            }
          ];
        };

        open = {
          rules = [
            # Mime types
            {
              mime = "application/pdf";
              use = "pdf";
            }
            {
              mime = "image/*";
              use = "image";
            }
            {
              mime = "video/*";
              use = "video";
            }
            {
              mime = "audio/*";
              use = "audio";
            }
            {
              mime = "text/*";
              use = [
                "edit"
                "text"
              ];
            }

            # File extensions
            {
              name = "*.pdf";
              use = "pdf";
            }
            {
              name = "*.json";
              use = "edit";
            }
            {
              name = "*.md";
              use = "edit";
            }
            {
              name = "*.html";
              use = [
                "edit"
                "text"
              ];
            }
            {
              name = "*.sh";
              use = "edit";
            }
            {
              name = "*.txt";
              use = [
                "edit"
                "text"
              ];
            }
            {
              name = "*.csv";
              use = "edit";
            }
            {
              name = "*.dat";
              use = "edit";
            }
            {
              name = "*.toml";
              use = "edit";
            }
            {
              name = "*.yaml";
              use = "edit";
            }
            {
              name = "*.yml";
              use = "edit";
            }
            {
              name = "*.lua";
              use = [
                "edit"
                "text"
              ];
            }
            {
              name = "*.log";
              use = "text";
            }
            {
              name = "*.rs";
              use = "edit";
            }
            {
              name = "*.js";
              use = "edit";
            }
            {
              name = "*.ts";
              use = "edit";
            }
            {
              name = "*.mp3";
              use = "audio";
            }
            {
              name = "*.wav";
              use = "audio";
            }
            {
              name = "*.ogg";
              use = "audio";
            }
            {
              name = "*.zip";
              use = "unzip";
            }
            {
              name = "*.AppImage";
              use = "app-image";
            }
          ];
        };
      */
    };

    keymap = {
      mgr.prepend_keymap = [
        {
          run = "remove --force";
          on = [ "d" ];
        }
      ];
    };
  };
}

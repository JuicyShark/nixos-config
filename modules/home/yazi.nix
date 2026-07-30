{
  pkgs,
  lib,
  osConfig,
  ...
}: let
  emacsEnabled = osConfig.modules.emacs.enable or false;
  emacsclient = lib.getExe' osConfig.modules.emacs.package "emacsclient";
  mpv = lib.getExe pkgs.mpv;
  ouch = lib.getExe pkgs.ouch;
  unrar = lib.getExe pkgs.unrar;
  disableKeys = keys:
    map (key: {
      on = key;
      run = "noop";
    })
    keys;
  archiveRules = [
    {
      mime = "application/zip";
      use = "extract";
    }
    {
      mime = "application/gzip";
      use = "extract";
    }
    {
      mime = "application/x-tar";
      use = "extract";
    }
    {
      mime = "application/x-bzip2";
      use = "extract";
    }
    {
      mime = "application/x-gzip";
      use = "extract";
    }
    {
      mime = "application/x-xz";
      use = "extract";
    }
    {
      mime = "application/zstd";
      use = "extract";
    }
    {
      mime = "application/x-7z-compressed";
      use = "extract";
    }
    {
      url = "*.tar.*";
      use = "extract";
    }
  ];
  rarRules = [
    {
      mime = "application/vnd.rar";
      use = "extract-rar";
    }
    {
      mime = "application/x-rar";
      use = "extract-rar";
    }
    {
      url = "*.rar";
      use = "extract-rar";
    }
    {
      url = "*.RAR";
      use = "extract-rar";
    }
  ];
  mediaRules = [
    {
      mime = "audio/*";
      use = "play";
    }
    {
      mime = "video/*";
      use = "play";
    }
  ];
in {
  xdg.configFile."yazi/init.lua".text = ''
    Header:children_add(function()
     if ya.target_family() ~= "unix" then
      return ui.Line {}
     end
     return ui.Span(ya.user_name() .. "@" .. ya.host_name() .. ":"):fg("blue")
    end, 500, Header.LEFT)
  '';

  # Yazi does not detect Ghostty's image protocol in this runtime, so use its
  # Wayland overlay backend for reliable image previews.
  home.packages = with pkgs;
    [poppler]
    ++ lib.optionals pkgs.stdenv.isLinux [ueberzugpp];

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    shellWrapperName = "y";
    keymap = {
      mgr.prepend_keymap =
        disableKeys [
          "h"
          "j"
          "k"
          "l"
          "H"
          "J"
          "K"
          "L"
        ]
        ++ [
          {
            on = "<A-Left>";
            run = "back";
            desc = "Previous directory";
          }
          {
            on = "<A-Right>";
            run = "forward";
            desc = "Next directory";
          }
          {
            on = "<S-Up>";
            run = "seek -5";
            desc = "Preview up";
          }
          {
            on = "<S-Down>";
            run = "seek 5";
            desc = "Preview down";
          }
        ];
      tasks.prepend_keymap = disableKeys ["j" "k"];
      spot.prepend_keymap = disableKeys [
        "h"
        "j"
        "k"
        "l"
      ];
      pick.prepend_keymap = disableKeys ["j" "k"];
      input.prepend_keymap = disableKeys ["h" "l"];
      confirm.prepend_keymap = disableKeys ["j" "k"];
      cmp.prepend_keymap = disableKeys [
        "<A-j>"
        "<A-k>"
      ];
      help.prepend_keymap = disableKeys ["j" "k"];
    };
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

      opener =
        {
          extract = [
            {
              run = ''${ouch} decompress --yes "$@"'';
              desc = "Extract here";
              block = true;
              for = "unix";
            }
          ];
          extract-rar = [
            {
              run = ''${unrar} x -y "$@"'';
              desc = "Extract RAR here";
              block = true;
              for = "unix";
            }
          ];
          play = [
            {
              run = ''${mpv} --force-window "$@"'';
              desc = "Open with mpv";
              orphan = true;
              for = "unix";
            }
          ];
        }
        // lib.optionalAttrs emacsEnabled {
          emacs = [
            {
              run = ''${emacsclient} -c "$@"'';
              desc = "Emacs client";
              block = false;
              for = "unix";
            }
          ];
        };

      open.prepend_rules =
        lib.optionals emacsEnabled [
          {
            url = "*.org";
            use = "emacs";
          }
        ]
        ++ mediaRules
        ++ rarRules
        ++ archiveRules;
    };
  };
}

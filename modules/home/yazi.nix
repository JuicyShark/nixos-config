{
  pkgs,
  lib,
  osConfig,
  ...
}: let
  hasDesktop = pkgs.stdenv.hostPlatform.isDarwin || (osConfig.modules.desktop.enable or false);
  # This NixOS-only option also keeps Stylix definitions out of headless homes,
  # where the Stylix module is not imported.
  hasTerminalFileChooser = osConfig.modules.desktop.terminalFileChooser.enable or false;
  mpv = lib.getExe pkgs.mpv;
  terminal = import ../../lib/terminal.nix {inherit lib pkgs;};
  termfilechooser = pkgs.xdg-desktop-portal-termfilechooser;
  termfilechooserPath = pkgs.buildEnv {
    name = "termfilechooser-path";
    paths = [pkgs.yazi pkgs.bash pkgs.coreutils pkgs.gnused];
    pathsToLink = ["/bin"];
  };
  disableKeys = keys:
    map (key: {
      on = key;
      run = "noop";
    })
    keys;
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

  mkYaziPlugin = {
    name,
    owner,
    repo,
    rev,
    hash,
    subdir ? null,
  }:
    pkgs.stdenvNoCC.mkDerivation {
      pname = "yazi-plugin-${name}";
      version = "unstable-${builtins.substring 0 7 rev}";
      src = pkgs.fetchFromGitHub {inherit owner repo rev hash;};
      dontBuild = true;
      installPhase = ''
        mkdir -p "$out"
        cp -RL ${lib.escapeShellArg (
          if subdir == null
          then "."
          else subdir
        )}/. "$out/"
      '';
    };

  yaziPlugins =
    {
      inherit (pkgs.yaziPlugins) toggle-pane mount jump-to-char sudo;

      preview-audio = mkYaziPlugin {
        name = "preview-audio";
        owner = "AminurAlam";
        repo = "yazi-plugins";
        rev = "ce325af662cbdd438194c68b6d69a3ff59c1b305";
        hash = "sha256-5+Wopb+W0STi1JMTDnjmIXorZEzDzSdMfdHLK9vl8xs=";
        subdir = "preview-audio.yazi";
      };
      fast-enter = mkYaziPlugin {
        name = "fast-enter";
        owner = "ourongxing";
        repo = "fast-enter.yazi";
        rev = "9fe77d8292c6bc63538acdc97cb91b81542e85a4";
        hash = "sha256-E0r0XsyECKMJ8w+9OVJKDggSXhAqlwD3u9ZSEXHc6J0=";
      };
      what-size = mkYaziPlugin {
        name = "what-size";
        owner = "pirafrank";
        repo = "what-size.yazi";
        rev = "c1a8cb62f47b10741fa833f01166af6114b06449";
        hash = "sha256-ZCRxs7KecMgu5tSqQoKCPIELSI2X2SAOeYG6Ct6gTBo=";
      };
    }
    // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
      inherit (pkgs.yaziPlugins) recycle-bin;

      openscad = mkYaziPlugin {
        name = "openscad";
        owner = "ettom";
        repo = "openscad.yazi";
        rev = "4397564c669c6a7db64154662313ddf430b39733";
        hash = "sha256-daiVNvkqHqKzT6nY+pqZ2ZM5kkYtPl0EtZKVkpjei0I=";
      };

      preview-epub = mkYaziPlugin {
        name = "preview-epub";
        owner = "AminurAlam";
        repo = "yazi-plugins";
        rev = "ce325af662cbdd438194c68b6d69a3ff59c1b305";
        hash = "sha256-5+Wopb+W0STi1JMTDnjmIXorZEzDzSdMfdHLK9vl8xs=";
        subdir = "preview-epub.yazi";
      };
    };
in
  lib.mkMerge [
    {
      # Keep the file manager and its shell wrapper available on headless CLI
      # hosts; previews, plugins, and desktop openers are added below.
      programs.yazi = {
        enable = true;
        shellWrapperName = "y";
      };
    }
    (lib.optionalAttrs hasTerminalFileChooser {
      # GTK 4 and Qt applications need to opt into the portal; Firefox has its
      # own preference in firefox.nix. Keep Stylix's qt5ct theme ownership.
      home.sessionVariables.GDK_DEBUG = "portals";
      stylix.targets.qt.standardDialogs = "xdgdesktopportal";

      xdg.configFile."xdg-desktop-portal-termfilechooser/config".text = ''
        [filechooser]
        cmd=${termfilechooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh
        create_help_file=1
        default_dir=$HOME
        env=PATH=${termfilechooserPath}/bin
        env=TERMCMD='${lib.getExe terminal.package} --title=termfilechooser -e'
        open_mode=suggested
        save_mode=last
      '';
    })
    (lib.mkIf hasDesktop {
      xdg.configFile."yazi/init.lua".text = ''
        Header:children_add(function()
         if ya.target_family() ~= "unix" then
          return ui.Line {}
         end
         return ui.Span(ya.user_name() .. "@" .. ya.host_name() .. ":"):fg("blue")
        end, 500, Header.LEFT)

        ${lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
          -- Keep recycle-bin's setup declarative through the Nix-managed init.
          require("recycle-bin"):setup()
        ''}
      '';

      # Install only the preview helpers supported by each desktop platform.
      # Linux uses the Wayland overlay backend for reliable image previews.
      home.packages = with pkgs;
        [poppler]
        ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ueberzugpp];

      programs.yazi = {
        extraPackages = with pkgs;
          [
            exiftool
            nushell
          ]
          ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
            openscad
            gnome-epub-thumbnailer
            trash-cli
          ];
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
              {
                on = "Return";
                run = "plugin fast-enter";
                desc = "Open file or enter directory quickly";
              }
              {
                on = "T";
                run = "plugin toggle-pane min-preview";
                desc = "Toggle preview pane";
              }
              {
                on = ["R" "p" "p"];
                run = "plugin sudo -- paste";
                desc = "Paste with sudo";
              }
              {
                on = ["R" "P"];
                run = "plugin sudo -- paste --force";
                desc = "Force paste with sudo";
              }
              {
                on = ["R" "r"];
                run = "plugin sudo -- rename";
                desc = "Rename with sudo";
              }
              {
                on = ["R" "p" "l"];
                run = "plugin sudo -- link";
                desc = "Create symlink with sudo";
              }
              {
                on = ["R" "p" "r"];
                run = "plugin sudo -- link --relative";
                desc = "Create relative symlink with sudo";
              }
              {
                on = ["R" "p" "L"];
                run = "plugin sudo -- hardlink";
                desc = "Create hardlink with sudo";
              }
              {
                on = ["R" "a"];
                run = "plugin sudo -- create";
                desc = "Create file or directory with sudo";
              }
              {
                on = ["R" "d"];
                run = "plugin sudo -- remove";
                desc = "Trash with sudo";
              }
              {
                on = ["R" "D"];
                run = "plugin sudo -- remove --permanently";
                desc = "Delete permanently with sudo";
              }
              {
                on = ["R" "m"];
                run = "plugin sudo -- chmod";
                desc = "Change permissions with sudo";
              }
              {
                on = ["." "."];
                run = "hidden toggle";
                desc = "Toggle hidden files";
              }
              {
                on = ["." "s"];
                run = "plugin what-size";
                desc = "Calculate directory size";
              }
              {
                on = "f";
                run = "plugin jump-to-char";
                desc = "Jump to file by first character";
              }
              {
                on = "M";
                run = "plugin mount";
                desc = "Mount manager";
              }
            ]
            ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
              {
                on = ["R" "b"];
                run = "plugin recycle-bin";
                desc = "Open recycle bin";
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
        plugins = yaziPlugins;
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

          plugin = {
            prepend_previewers =
              lib.optionals pkgs.stdenv.hostPlatform.isLinux [
                {
                  url = "*.epub";
                  run = "preview-epub";
                }
                {
                  url = "*.{scad,csg,3mf,amf,dxf,off,stl}";
                  run = "openscad";
                }
              ]
              ++ [
                {
                  mime = "audio/mpegurl";
                  run = "code";
                }
                {
                  mime = "audio/*";
                  run = "preview-audio";
                }
              ];
            prepend_preloaders =
              lib.optionals pkgs.stdenv.hostPlatform.isLinux [
                {
                  url = "*.epub";
                  run = "preview-epub";
                }
                {
                  url = "*.{scad,csg,3mf,amf,dxf,off,stl}";
                  run = "openscad";
                }
              ]
              ++ [
                {
                  mime = "audio/mpegurl";
                  run = "code";
                }
                {
                  mime = "audio/*";
                  run = "preview-audio";
                }
              ];
          };

          opener.play = [
            {
              run = ''${mpv} --force-window "$@"'';
              desc = "Open with mpv";
              orphan = true;
              for = "unix";
            }
          ];

          open.prepend_rules = mediaRules;
        };
      };
    })
  ]

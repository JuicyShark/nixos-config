{
  system,
  config,
  pkgs,
  lib,
  ...
}: let
  isLinux = lib.hasSuffix "-linux" system;
  isWorkstation = pkgs.stdenv.isDarwin || (config.modules.desktop.enable or false);
  cfg = config.modules.shell;
in {
  options.modules.shell = {
    atuin.syncUrl = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Atuin sync server URL (empty string disables sync)";
    };

    admin.enable = lib.mkEnableOption "host administration and hardware diagnostics";
    dev.enable = lib.mkEnableOption "development and Nix authoring tools";
    extras.enable = lib.mkEnableOption "non-essential terminal toys";
  };

  config = lib.mkMerge [
    {
      environment.systemPackages = with pkgs;
        [
          jq
          fd
          xh
          file
          mtr
          whois
          duf
          p7zip
          tealdeer
        ]
        ++ lib.optionals cfg.dev.enable [
          nix-init
          nix-update
          nix-search-cli
          nix-tree
          nix-inspect
          dust # replaces: du
          procs # replaces: ps
          sd # replaces: sed (simple substitutions)
          choose # replaces: cut / awk (simple field extraction)
          hyperfine # benchmarking (no direct OG; replaces ad-hoc `time` loops)
          tokei # replaces: cloc / wc -l
          ouch # replaces: tar / unzip / 7z (universal archive)
          codex
        ]
        ++ lib.optionals isWorkstation [
          ffmpeg
          imagemagick
        ]
        ++ lib.optionals (isLinux && cfg.admin.enable) [
          hwinfo
          hdparm
          lsof
          nix-output-monitor
          nvd
          stress-ng
          gping
          trippy
          bandwhich # replaces: nethogs / iftop (per-process bandwidth)
        ]
        ++ lib.optionals (isWorkstation && cfg.extras.enable) [
          timg
          cmatrix
          peaclock
        ];

      programs = {
        zsh.enable = true;
        direnv = {
          enable = cfg.dev.enable || isWorkstation;
          nix-direnv.enable = cfg.dev.enable || isWorkstation;
        };
      };
    }

    # NixOS-only config — use optionalAttrs (not mkIf) so keys don't appear at all on darwin.
    # Must use `system` (not pkgs.stdenv) because optionalAttrs evaluates eagerly
    # and pkgs depends on config, which causes infinite recursion.
    (lib.optionalAttrs isLinux {
      users.defaultUserShell = pkgs.zsh;
      environment = {
        shells = with pkgs; [
          zsh
          bash
        ];
        pathsToLink = [
          "/share/zsh"
          "/share/bash-completion"
        ];
      };
      # NixOS manages neovim system-wide; on darwin home-manager handles it
      programs = {
        nh.enable = true;
        neovim.enable = !isWorkstation;
        direnv.silent = true;
      };
    })
  ];
}

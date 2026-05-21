{
  inputs,
  system,
  config,
  pkgs,
  lib,
  ...
}: let
  isLinux = lib.hasSuffix "-linux" system;
  systemCfg = config.modules.system;
in {
  options.modules.shell.atuin.syncUrl = lib.mkOption {
    type = lib.types.str;
    default = "";
    description = "Atuin sync server URL (empty string disables sync)";
  };

  config = lib.mkMerge [
    {
      nixpkgs.overlays = [inputs.nix-claude-code.overlays.default];

      environment.systemPackages = with pkgs;
        [
          jq
          fd
          xh
          file
          timg
          mtr
          whois
          duf
          stress
          fastfetch
          cmatrix
          p7zip
          peaclock
          tealdeer
          ffmpeg
          imagemagick
          nix-init
          nix-update
          nix-search-cli
          nix-tree
          nix-inspect
          # Modern CLI replacements / additions
          dust # replaces: du
          procs # replaces: ps
          sd # replaces: sed (simple substitutions)
          gping # replaces: ping (graphical)
          trippy # replaces: mtr / traceroute
          choose # replaces: cut / awk (simple field extraction)
          hyperfine # benchmarking (no direct OG; replaces ad-hoc `time` loops)
          tokei # replaces: cloc / wc -l
          ouch # replaces: tar / unzip / 7z (universal archive)
          dig
        ]
        ++ [claude-code]
        # Linux-only hardware/network tools
        ++ lib.optionals isLinux [
          hwinfo
          hdparm
          lsof
          nh
          nix-output-monitor
          nvd
          bandwhich # replaces: nethogs / iftop (per-process bandwidth)
        ];

      programs = {
        zsh.enable = true;
        direnv = {
          enable = true;
          nix-direnv.enable = true;
        };
      };
    }

    # NixOS-only config — use optionalAttrs (not mkIf) so keys don't appear at all on darwin.
    # Must use `system` (not pkgs.stdenv) because optionalAttrs evaluates eagerly
    # and pkgs depends on config, which causes infinite recursion.
    (lib.optionalAttrs isLinux {
      users.defaultUserShell = pkgs.zsh;
      programs.nh = {
        enable = true;
        flake = systemCfg.flakePath;
      };
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
      programs.neovim.enable = true;
      programs.direnv.silent = true;
    })
  ];
}

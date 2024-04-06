{ nix-config, pkgs, lib, ... }:

let
  inherit (builtins) attrValues;
  inherit (lib) singleton;
in
{
  imports = attrValues {
    inherit (nix-config.nixosModules) system shell desktop;

    customConfig = {
      modules.system.username = "asuna";
    };
  };

  home-manager.sharedModules = attrValues nix-config.homeManagerModules ++ singleton {
    programs.btop.enable = true;
  };

  environment.systemPackages = attrValues {
    inherit (nix-config.packages.x86_64-linux) fluent-icons hycov osu-backgrounds;
    inherit (pkgs) ruby php;
  };

  nixpkgs.overlays = attrValues {
    inherit (nix-config.overlays) kitty;

    exampleOverlay = final: prev: {
      btop = prev.btop.overrideAttrs (oldAttrs: {
        postInstall = (oldAttrs.postInstall or "") + /* bash */ ''
          echo "#!/usr/bin/env sh"  >> btop-overlay
          echo "echo 'hello world'" >> btop-overlay

          install -Dm755 btop-overlay $out/bin/btop-overlay
        '';
      });
    };
  };
}

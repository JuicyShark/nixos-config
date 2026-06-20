{lib, ...}: let
  mkApp = pkgs: name: text: {
    type = "app";
    meta.description = name;
    program =
      lib.getExe
      (pkgs.writeShellApplication {
        inherit name text;
        runtimeInputs = with pkgs; [
          coreutils
          nix
          nix-output-monitor
          nvd
          openssh
          nh
        ];
      });
  };

  deploymentApps = pkgs: let
    app = mkApp pkgs;
    flakePath = "\${NH_FLAKE:-\${FLAKE:-$PWD}}";
    zuesTargetHost = "juicy@192.168.1.99";
    localHostArg = ''
      host="''${1:-$(hostname)}"
      if [ "$#" -gt 0 ]; then
        shift
      fi
      flake="${flakePath}"
    '';
    zuesRebuild = action: ''
      flake="${flakePath}"
      exec nixos-rebuild ${action} \
        --flake "$flake#zues" \
        --target-host ${zuesTargetHost} \
        --use-remote-sudo \
        --ask-sudo-password \
        "$@"
    '';
  in {
    os-build = app "os-build" ''
      ${localHostArg}
      exec nh os build "$flake" -H "$host" "$@"
    '';

    os-switch = app "os-switch" ''
      ${localHostArg}
      exec nh os switch "$flake" -H "$host" "$@"
    '';

    os-diff = app "os-diff" ''
      ${localHostArg}
      new="$(nix build "$flake#nixosConfigurations.$host.config.system.build.toplevel" --no-link --print-out-paths "$@")"
      exec nvd diff /run/current-system "$new"
    '';

    zues-test = app "zues-test" (zuesRebuild "test");
    zues-switch = app "zues-switch" (zuesRebuild "switch");
    zues-diff = app "zues-diff" ''
      flake="${flakePath}"
      old="$(ssh ${zuesTargetHost} readlink -f /run/current-system)"
      nix copy --from ssh://${zuesTargetHost} "$old"
      new="$(nix build "$flake#nixosConfigurations.zues.config.system.build.toplevel" --no-link --print-out-paths "$@")"
      exec nvd diff "$old" "$new"
    '';
  };
in {
  perSystem = {pkgs, ...}: {
    apps = lib.optionalAttrs pkgs.stdenv.isLinux (deploymentApps pkgs);
  };
}

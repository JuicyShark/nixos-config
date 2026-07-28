{
  lib,
  self,
}: pkgs: let
  mkApp = name: text: {
    type = "app";
    meta.description = name;
    program =
      lib.getExe
      (pkgs.writeShellApplication {
        inherit name text;
        runtimeInputs = with pkgs; [
          coreutils
          nix
          nvd
          openssh
          nh
          nixos-rebuild
        ];
      });
  };

  flakePath = "\${NH_FLAKE:-\${FLAKE:-$PWD}}";
  leoUser = self.nixosConfigurations.leo.config.modules.profile.username;
  zuesUser = self.nixosConfigurations.zues.config.modules.profile.username;
  zuesTargetHost = "${zuesUser}@192.168.1.99";
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
in
  (lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
    nvim-lab = mkApp "nvim-lab" ''
      set -euo pipefail

      mode="''${1:-smart-focus}"
      if [ "$#" -gt 0 ]; then
        shift
      fi

      flake="${flakePath}"
      system="$(nix eval --raw --impure --expr builtins.currentSystem)"
      package_attr="$flake#nixosConfigurations.leo.config.home-manager.users.${leoUser}.programs.nixvim.build.package"
      init_attr="$flake#nixosConfigurations.leo.config.home-manager.users.${leoUser}.programs.nixvim.build.initFile"
      files_attr="$flake#nixosConfigurations.leo.config.home-manager.users.${leoUser}.programs.nixvim.build.extraFiles"
      smoke_attr="$flake#checks.$system.nixvim-smoke"

      build_nvim() {
        nvim_package="$(nix build "$package_attr" --no-link --print-out-paths)"
        nvim_init="$(nix build "$init_attr" --no-link --print-out-paths)"
        nvim_files="$(nix build "$files_attr" --no-link --print-out-paths)"
      }

      prep_xdg() {
        export HOME="$lab_dir/home"
        export XDG_CONFIG_HOME="$lab_dir/xdg/config"
        export XDG_DATA_HOME="$lab_dir/xdg/data"
        export XDG_STATE_HOME="$lab_dir/xdg/state"
        export XDG_CACHE_HOME="$lab_dir/xdg/cache"
        mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"
      }

      link_nvim_files() {
        ln -s "$nvim_files" "$XDG_CONFIG_HOME/nvim"
      }

      case "$mode" in
        preflight)
          nix build "$smoke_attr" --no-link
          ;;
        contract)
          lab_dir="$(mktemp -d -t nvim-lab-contract.XXXXXX)"
          prep_xdg
          build_nvim
          link_nvim_files
          "$nvim_package/bin/nvim" --headless \
            +"luafile $nvim_init" \
            +"luafile ${../modules/home/neovim/tests/contract.lua}" \
            +"luafile ${../modules/home/neovim/tests/neorg-contract.lua}" \
            +qa!
          ;;
        smart-focus)
          lab_dir="$(mktemp -d -t nvim-lab-smart-focus.XXXXXX)"
          prep_xdg
          build_nvim
          link_nvim_files
          exec "$nvim_package/bin/nvim" +"luafile $nvim_init" +"luafile ${../modules/home/neovim/tests/lab.lua}" +JuicyLabSmartFocus "$@"
          ;;
        *)
          echo "usage: nix run .#nvim-lab -- [preflight|contract|smart-focus]" >&2
          exit 2
          ;;
      esac
    '';
  })
  // {
    os-build = mkApp "os-build" ''
      ${localHostArg}
      exec nh os build "$flake" -H "$host" "$@"
    '';

    os-switch = mkApp "os-switch" ''
      ${localHostArg}
      exec nh os switch "$flake" -H "$host" "$@"
    '';

    os-diff = mkApp "os-diff" ''
      ${localHostArg}
      new="$(nix build "$flake#nixosConfigurations.$host.config.system.build.toplevel" --no-link --print-out-paths "$@")"
      exec nvd diff /run/current-system "$new"
    '';

    zues-test = mkApp "zues-test" (zuesRebuild "test");
    zues-switch = mkApp "zues-switch" (zuesRebuild "switch");
    zues-diff = mkApp "zues-diff" ''
      flake="${flakePath}"
      old="$(ssh ${zuesTargetHost} readlink -f /run/current-system)"
      nix copy --from ssh://${zuesTargetHost} "$old"
      new="$(nix build "$flake#nixosConfigurations.zues.config.system.build.toplevel" --no-link --print-out-paths "$@")"
      exec nvd diff "$old" "$new"
    '';
  }

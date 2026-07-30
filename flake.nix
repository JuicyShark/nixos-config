{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixflix = {
      url = "github:kiriwalawren/nixflix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    agenix = {
      url = "github:ryantm/agenix";
      inputs = {
        darwin.follows = "nix-darwin";
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
      };
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    nixpkgs-stable,
    nix-darwin,
    ...
  }: let
    inherit (nixpkgs) lib;

    linuxSystems = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    systems = linuxSystems ++ ["aarch64-darwin"];
    forAllSystems = function: lib.genAttrs systems function;
    forLinuxSystems = function: lib.genAttrs linuxSystems function;

    # Package policy ----------------------------------------------------------
    # Keep the exception list and every local override together. Hosts only
    # consume `mkPkgs`, never one-off nixpkgs imports with drifting settings.
    unfreePackages = [
      "2ship2harkinian"
      "bambu-studio"
      "castlabs-electron"
      "discord"
      "keymapp"
      "minecraft-server"
      "n64recomp"
      "aspell-dict-en-science"
      "obsidian"
      "osu-lazer-bin"
      "shipwright"
      "skyfactory5-server-pack"
      "steam"
      "steam-unwrapped"
      "unrar"
      "vivaldi"
      "wowup-cf"
      "xone-dongle-firmware"
    ];

    nixpkgsConfig = {
      allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) unfreePackages;
    };

    nixpkgsOverlays = [
      inputs.emacs-overlay.overlays.default
      (_final: prev: {
        sunshine = let
          stablePkgs = import nixpkgs-stable {
            inherit (prev.stdenv.hostPlatform) system;
            config = nixpkgsConfig;
          };
        in
          stablePkgs.sunshine;

        minecraft-server = prev.stdenv.mkDerivation {
          pname = "minecraft-server";
          version = "26.2";

          src = prev.fetchurl {
            url = "https://piston-data.mojang.com/v1/objects/823e2250d24b3ddac457a60c92a6a941943fcd6a/server.jar";
            sha1 = "823e2250d24b3ddac457a60c92a6a941943fcd6a";
          };

          preferLocalBuild = true;
          dontUnpack = true;
          nativeBuildInputs = [prev.makeWrapper];

          installPhase = ''
            runHook preInstall

            install -Dm644 $src $out/lib/minecraft/server.jar

            makeWrapper ${prev.lib.getExe prev.jdk25_headless} $out/bin/minecraft-server \
              --append-flags "-jar $out/lib/minecraft/server.jar nogui" \
              ${prev.lib.optionalString prev.stdenv.hostPlatform.isLinux "--prefix LD_LIBRARY_PATH : ${prev.lib.makeLibraryPath [prev.udev]}"}

            runHook postInstall
          '';

          passthru.updateInfo = {
            manifest = "https://launchermeta.mojang.com/mc/game/version_manifest_v2.json";
            releaseTime = "2026-06-16T12:03:33+00:00";
            serverSha1 = "823e2250d24b3ddac457a60c92a6a941943fcd6a";
          };

          meta = {
            description = "Minecraft Server";
            homepage = "https://minecraft.net";
            sourceProvenance = with prev.lib.sourceTypes; [binaryBytecode];
            license = prev.lib.licenses.unfreeRedistributable;
            platforms = prev.lib.platforms.unix;
            mainProgram = "minecraft-server";
          };
        };

        skyfactory5-server-pack = prev.fetchzip {
          name = "skyfactory5-server-pack-5.0.8";
          url = "https://edge.forgecdn.net/files/6290/699/SkyFactory_5_Server_5.0.8.zip";
          hash = "sha256-UowGdnLar/jWwMwjXpr+wygbRd6xiVl1n+0es84X7x4=";
          stripRoot = false;
          meta = {
            description = "SkyFactory 5 server pack";
            homepage = "https://www.curseforge.com/minecraft/modpacks/skyfactory-5";
            license = prev.lib.licenses.unfreeRedistributable;
            platforms = prev.lib.platforms.unix;
          };
        };

        lazymc = prev.lazymc.overrideAttrs (old: {
          patches =
            (old.patches or [])
            ++ [
              ./patches/lazymc-probe-until-login-ready.patch
            ];
        });
      })
    ];

    mkPkgs = system:
      import nixpkgs {
        inherit system;
        config = nixpkgsConfig;
        overlays = nixpkgsOverlays;
      };

    # Module catalog ----------------------------------------------------------
    # This is the only import registry. Host files stay readable by importing
    # named modules from `self.nixosModules` or `self.darwinModules`.
    nixosModules = {
      acme = import ./modules/nixos/acme.nix;
      desktop = import ./modules/nixos/desktop;
      emacs = import ./modules/common/emacs.nix;
      fonts = import ./modules/nixos/fonts.nix;
      git-server = import ./modules/nixos/git-server.nix;
      glance = import ./modules/nixos/glance.nix;
      homelab = import ./modules/nixos/homelab;
      ios = import ./modules/nixos/ios.nix;
      local-models = import ./modules/common/local-models.nix;
      monitoring = import ./modules/nixos/monitoring;
      nfs = import ./modules/nixos/nfs.nix;
      pipewire = import ./modules/nixos/pipewire.nix;
      ports = import ./modules/nixos/ports.nix;
      recomp = import ./modules/nixos/recomp.nix;
      shairport = import ./modules/nixos/shairport.nix;
      shell = import ./modules/common/shell.nix;
      stylix = import ./modules/common/stylix.nix;
      system = import ./modules/nixos/system.nix;
      unbound = import ./modules/nixos/unbound.nix;
    };

    darwinModules = {
      emacs = import ./modules/common/emacs.nix;
      jellyfin = import ./modules/darwin/jellyfin.nix;
      local-models = import ./modules/common/local-models.nix;
      minecraft = import ./modules/darwin/minecraft.nix;
      ollama = import ./modules/darwin/ollama.nix;
      shell = import ./modules/common/shell.nix;
      stylix = import ./modules/common/stylix.nix;
      system = import ./modules/darwin/system.nix;
    };

    homeModules = {
      atuin = import ./modules/home/atuin.nix;
      bat = import ./modules/home/bat.nix;
      btop = import ./modules/home/btop.nix;
      chromium = import ./modules/home/chromium.nix;
      desktop-apps = import ./modules/home/desktop-apps.nix;
      editorconfig = import ./modules/home/editorconfig.nix;
      emacs = import ./modules/home/emacs.nix;
      eza = import ./modules/home/eza.nix;
      fastfetch = import ./modules/home/fastfetch.nix;
      fzf = import ./modules/home/fzf.nix;
      git = import ./modules/home/git.nix;
      ghostty = import ./modules/home/ghostty.nix;
      gtk = import ./modules/home/gtk.nix;
      ha-presence = import ./modules/home/ha-presence.nix;
      hyprland = import ./modules/home/hyprland.nix;
      lazygit = import ./modules/home/lazygit.nix;
      mime-apps = import ./modules/home/mime-apps.nix;
      mpv = import ./modules/home/mpv.nix;
      neovim = import ./modules/home/neovim;
      noctalia-shell = import ./modules/home/noctalia-shell.nix;
      obs = import ./modules/home/obs.nix;
      qutebrowser = import ./modules/home/qutebrowser.nix;
      rbw = import ./modules/home/rbw.nix;
      ripgrep = import ./modules/home/ripgrep.nix;
      shairport = import ./modules/home/shairport.nix;
      ssh = import ./modules/home/ssh.nix;
      starship = import ./modules/home/starship.nix;
      tmux = import ./modules/home/tmux.nix;
      xdg-desktop-entries = import ./modules/home/xdg-desktop-entries.nix;
      xdg-user-dirs = import ./modules/home/xdg-user-dirs.nix;
      xresources = import ./modules/home/xresources.nix;
      yazi = import ./modules/home/yazi.nix;
      zoxide = import ./modules/home/zoxide.nix;
      zsh = import ./modules/home/zsh.nix;
    };

    repoLib = import ./lib {inherit lib;};

    # Home profiles -----------------------------------------------------------
    # Profiles list capabilities, while individual hosts choose exactly one.
    homeProfiles = rec {
      cli = with homeModules; [
        atuin
        bat
        btop
        eza
        fastfetch
        fzf
        git
        ripgrep
        ssh
        starship
        tmux
        zoxide
        zsh
      ];

      workstationCli =
        cli
        ++ (with homeModules; [
          editorconfig
          lazygit
          neovim
          yazi
        ]);

      desktop =
        workstationCli
        ++ (with homeModules; [
          chromium
          desktop-apps
          emacs
          ghostty
          gtk
          ha-presence
          hyprland
          mime-apps
          mpv
          noctalia-shell
          obs
          qutebrowser
          rbw
          shairport
          xdg-desktop-entries
          xdg-user-dirs
          xresources
        ]);

      darwin =
        workstationCli
        ++ (with homeModules; [
          emacs
          ghostty
          mpv
          xdg-user-dirs
        ]);
    };

    # Hosts -------------------------------------------------------------------
    specialArgs = system: {
      inherit inputs self system homeProfiles;
    };

    nixpkgsModule = {
      nixpkgs = {
        config = nixpkgsConfig;
        overlays = nixpkgsOverlays;
      };
    };

    patchedNixflix = system:
      nixpkgs.legacyPackages.${system}.applyPatches {
        name = "nixflix-patched";
        src = inputs.nixflix;
        patches = [
          ./patches/nixflix-prowlarr-indexer-field-secrets.patch
        ];
      };

    patchedNixflixModule = system: {
      imports = [
        (import "${patchedNixflix system}/modules")
        inputs.nixflix.inputs.vpn-confinement.nixosModules.default
      ];
    };

    mkNixosHost = {
      name,
      system,
      extraModules ? [],
      includeHardware ? true,
    }:
      lib.nixosSystem {
        inherit system;
        specialArgs = specialArgs system;
        modules =
          [
            nixpkgsModule
            ./hosts/${name}/configuration.nix
          ]
          ++ lib.optional includeHardware ./hosts/${name}/hardware-configuration.nix
          ++ extraModules;
      };

    mkDarwinHost = name: system:
      nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = specialArgs system;
        modules = [
          nixpkgsModule
          inputs.nix-homebrew.darwinModules.nix-homebrew
          ./hosts/${name}/configuration.nix
        ];
      };

    nixosConfigurations = {
      leo = mkNixosHost {
        name = "leo";
        system = "x86_64-linux";
      };
      fallarbor = mkNixosHost {
        name = "fallarbor";
        system = "x86_64-linux";
      };
      zues = mkNixosHost {
        name = "zues";
        system = "x86_64-linux";
        extraModules = [
          (patchedNixflixModule "x86_64-linux")
          ./hosts/zues/networking.nix
          ./hosts/zues/services.nix
          ./hosts/zues/gatus.nix
        ];
      };
      iso = mkNixosHost {
        name = "iso";
        system = "x86_64-linux";
        includeHardware = false;
      };
    };

    darwinConfigurations.mac = mkDarwinHost "mac" "aarch64-darwin";

    # Local workflow ----------------------------------------------------------
    mkApp = pkgs: name: text: {
      type = "app";
      meta.description = name;
      program = lib.getExe (pkgs.writeShellApplication {
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

    mkApps = pkgs: let
      app = mkApp pkgs;
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
        nvim-lab = app "nvim-lab" ''
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
                +"luafile ${./modules/home/neovim/tests/contract.lua}" \
                +"luafile ${./modules/home/neovim/tests/neorg-contract.lua}" \
                +qa!
              ;;
            smart-focus)
              lab_dir="$(mktemp -d -t nvim-lab-smart-focus.XXXXXX)"
              prep_xdg
              build_nvim
              link_nvim_files
              exec "$nvim_package/bin/nvim" +"luafile $nvim_init" +"luafile ${./modules/home/neovim/tests/lab.lua}" +JuicyLabSmartFocus "$@"
              ;;
            *)
              echo "usage: nix run .#nvim-lab -- [preflight|contract|smart-focus]" >&2
              exit 2
              ;;
          esac
        '';
      })
      // {
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

    mkDevShells = pkgs: {
      default = pkgs.mkShell {
        packages = with pkgs; [
          alejandra
          statix
          deadnix
          nixd
          lua-language-server
          lua5_4
          lua54Packages.luacheck
          stylua
          shellcheck
          shfmt
          jq
          ripgrep
          fd
        ];
      };
    };

    mkLinuxChecks = system: let
      pkgs = mkPkgs system;
      mediaVoteTests =
        pkgs.runCommand "media-vote-tests" {
          nativeBuildInputs = [
            (pkgs.python3.withPackages (pythonPackages: [pythonPackages.flask]))
          ];
        } ''
          export MEDIA_VOTE_DATABASE="$TMPDIR/media-vote.sqlite"
          export PYTHONDONTWRITEBYTECODE=1
          cd ${./packages/media-vote}
          python3 -W error::ResourceWarning -m unittest discover -s tests -v
          touch "$out"
        '';
      hyprlandLuaSyntax = pkgs.runCommand "hyprland-lua-syntax" {nativeBuildInputs = [pkgs.lua5_4];} ''
        find ${./modules/home/hyprland/lua} -name '*.lua' -print0 | xargs -0 luac -p
        touch "$out"
      '';
      hyprlandMonitorPolicy = pkgs.runCommand "hyprland-monitor-policy" {nativeBuildInputs = [pkgs.lua5_4];} ''
        lua ${./modules/home/hyprland/tests/monitor-policy.lua} ${./modules/home/hyprland/lua/monitor-policy.lua}
        lua ${./modules/home/hyprland/tests/monitor-controller.lua} \
          ${./modules/home/hyprland/lua/monitor-policy.lua} \
          ${./modules/home/hyprland/lua/monitor-states.lua}
        touch "$out"
      '';
      primaryUser = self.nixosConfigurations.leo.config.modules.profile.username;
      nixvimPackage = self.nixosConfigurations.leo.config.home-manager.users.${primaryUser}.programs.nixvim.build.package;
      nixvimInit = self.nixosConfigurations.leo.config.home-manager.users.${primaryUser}.programs.nixvim.build.initFile;
      nixvimFiles = self.nixosConfigurations.leo.config.home-manager.users.${primaryUser}.programs.nixvim.build.extraFiles;
      nixvimSmoke = pkgs.runCommand "nixvim-smoke" {} ''
        export HOME="$TMPDIR/home"
        export XDG_CONFIG_HOME="$TMPDIR/config"
        export XDG_DATA_HOME="$TMPDIR/data"
        export XDG_STATE_HOME="$TMPDIR/state"
        export XDG_CACHE_HOME="$TMPDIR/cache"
        mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"
        ln -s ${nixvimFiles} "$XDG_CONFIG_HOME/nvim"

        ${nixvimPackage}/bin/nvim --headless \
          +"luafile ${nixvimInit}" \
          +"luafile ${./modules/home/neovim/tests/contract.lua}" \
          +"luafile ${./modules/home/neovim/tests/neorg-contract.lua}" \
          +qa!
        touch "$out"
      '';
      static = pkgs.runCommand "nix-static" {nativeBuildInputs = with pkgs; [alejandra statix deadnix];} ''
        cd ${self}
        alejandra --check .
        statix check .
        deadnix --fail .
        touch "$out"
      '';
      monitoringConfig = pkgs.runCommand "monitoring-config" {nativeBuildInputs = with pkgs; [bash jq prometheus.cli shellcheck];} ''
        bash -n ${./modules/nixos/monitoring/homelab-diagnostics.sh}
        shellcheck ${./modules/nixos/monitoring/homelab-diagnostics.sh}
        bash -n ${./modules/nixos/monitoring/homelab-health-metrics.sh}
        shellcheck ${./modules/nixos/monitoring/homelab-health-metrics.sh}
        promtool check rules ${./modules/nixos/monitoring/prometheus-rules.yml}
        for dashboard in ${./modules/nixos/grafana-dashboards}/*.json; do
          jq empty "$dashboard"
        done
        touch "$out"
      '';
    in {
      inherit static;
      hyprland-lua-syntax = hyprlandLuaSyntax;
      hyprland-monitor-policy = hyprlandMonitorPolicy;
      monitoring-config = monitoringConfig;
      media-vote = mediaVoteTests;
      nixvim-smoke = nixvimSmoke;
      leo-eval = self.nixosConfigurations.leo.config.system.build.toplevel;
      fallarbor-eval = self.nixosConfigurations.fallarbor.config.system.build.toplevel;
      zues-eval = self.nixosConfigurations.zues.config.system.build.toplevel;
      iso-eval = self.nixosConfigurations.iso.config.system.build.isoImage;
    };
  in {
    inherit nixosModules darwinModules homeModules nixosConfigurations darwinConfigurations;
    lib = repoLib;

    apps = forLinuxSystems (system: mkApps (mkPkgs system));
    devShells = forAllSystems (system: mkDevShells (mkPkgs system));
    #formatter = forAllSystems (system: (mkPkgs system).alejandra);

    checks = {
      x86_64-linux = mkLinuxChecks "x86_64-linux";
      aarch64-darwin.mac-eval = self.darwinConfigurations.mac.system;
    };
  };
}

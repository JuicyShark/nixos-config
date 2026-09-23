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
      "discord-unwrapped"
      "keymapp"
      "n64recomp"
      "nvidia-settings"
      "nvidia-x11"
      "osu-lazer-bin"
      "shipwright"
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
      (final: prev: {
        nym-vpn-core = final.stdenv.mkDerivation {
          pname = "nym-vpn-core";
          version = "2026.11.3";
          src = final.fetchurl {
            url = "https://github.com/nymtech/nym-vpn-client/releases/download/nym-vpn-v2026.11.3/nym-vpn-core-v2026.11.3_linux_${final.stdenv.hostPlatform.parsed.cpu.name}.tar.gz";
            hash =
              if final.stdenv.hostPlatform.isAarch64
              then "sha256-VTXJiI9TyA/NYu/73ef2KorOk8HhXXH+Zr75CGaAOSg="
              else "sha256-MtnZZxzOWETflhdKYdJ8++kTgIjE4XuqeDTCTZw+7wQ=";
          };
          nativeBuildInputs = [final.autoPatchelfHook];
          buildInputs = [
            final.libmnl
            final.libnftnl
            final.dbus
            final.stdenv.cc.cc.lib
            final.openssl
          ];
          dontUnpack = true;
          installPhase = ''
            mkdir -p $out/bin
            tar -xzf $src --strip-components=1 -C $out/bin
            chmod +x $out/bin/*
            mkdir -p $out/share/polkit-1/actions
            cat > $out/share/polkit-1/actions/com.nymvpn.vpnd.unix-access.policy <<'EOF'
            <?xml version="1.0" encoding="UTF-8"?>
            <policyconfig>
              <action id="com.nymvpn.vpnd.unix-access">
                <description>Connect via unix socket</description>
                <message>Authentication is required to connect to the daemon</message>
                <defaults>
                  <allow_any>auth_admin</allow_any>
                  <allow_inactive>auth_admin</allow_inactive>
                  <allow_active>auth_self</allow_active>
                </defaults>
              </action>
            </policyconfig>
            EOF
          '';
          meta.mainProgram = "nym-vpnc";
        };

        sunshine = let
          stablePkgs = import nixpkgs-stable {
            inherit (prev.stdenv.hostPlatform) system;
            config = nixpkgsConfig;
          };
        in
          stablePkgs.sunshine;
      })
    ];

    mkPkgs = system:
      import nixpkgs {
        inherit system;

        config = nixpkgsConfig;
        overlays = nixpkgsOverlays;
      };

    repoLib = import ./lib {inherit lib;};

    # Deployment intent used by host modules and read-only catalog consumers.
    # Keeping these flags independent of a NixOS configuration avoids forcing
    # desktop-only modules to evaluate the complete zues system.
    homelabFeatures = {
      monitoring = true;
      atuin = true;
      filebrowser = true;
      gatus = true;
      jellyfin = true;
      jellystat = true;
      media = true;
      swiparr = true;
      syncthing = false;
      tidarr = true;
      vaultwarden = true;
    };

    # Home profiles -----------------------------------------------------------
    # Profiles list capabilities, while individual hosts choose exactly one.
    homeProfiles = rec {
      cli = [
        ./modules/home/atuin.nix
        ./modules/home/cli-tools.nix
        ./modules/home/fastfetch.nix
        ./modules/home/fzf.nix
        ./modules/home/git.nix
        ./modules/home/ssh.nix
        ./modules/home/starship.nix
        ./modules/home/yazi.nix
        ./modules/home/zellij.nix
        ./modules/home/zsh.nix
      ];

      workstationCli =
        cli
        ++ [
          ./modules/home/editorconfig.nix
          ./modules/home/lazygit.nix
          ./modules/home/neovim
        ];

      recovery =
        workstationCli
        ++ [
          inputs.stylix.homeModules.stylix
          ./modules/home/ghostty.nix
          ./modules/home/recovery.nix
        ];

      desktop =
        workstationCli
        ++ [
          ./modules/home/firefox.nix
          ./modules/home/desktop-apps.nix
          ./modules/home/ghostty.nix
          ./modules/home/gtk.nix
          ./modules/home/ha-presence.nix
          ./modules/home/hyprland.nix
          ./modules/home/mime-apps.nix
          ./modules/home/mpv.nix
          ./modules/home/noctalia-shell.nix
          ./modules/home/obs.nix
          ./modules/home/rbw.nix
          ./modules/home/shairport.nix
          ./modules/home/tether.nix
          ./modules/home/xdg-desktop-entries.nix
          ./modules/home/xdg-user-dirs.nix
          ./modules/home/xresources.nix
        ];

      darwin =
        workstationCli
        ++ [
          ./modules/home/ghostty.nix
          ./modules/home/mpv.nix
          ./modules/home/xdg-user-dirs.nix
        ];
    };

    # Hosts -------------------------------------------------------------------
    specialArgs = system: {
      inherit inputs self system homeProfiles homelabFeatures;
      ports = import ./lib/ports.nix;
    };

    nixpkgsModule = {
      nixpkgs = {
        config = nixpkgsConfig;
        overlays = nixpkgsOverlays;
      };
    };

    mkNixosHost = name:
      lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = specialArgs "x86_64-linux";
        modules = [
          nixpkgsModule
          ./hosts/${name}/configuration.nix
        ];
      };

    nixosConfigurations = {
      leo = mkNixosHost "leo";
      pallet = mkNixosHost "pallet";
      fallarbor = mkNixosHost "fallarbor";
      zues = mkNixosHost "zues";
      iso = mkNixosHost "iso";
    };

    darwinConfigurations.mac = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      specialArgs = specialArgs "aarch64-darwin";
      modules = [
        nixpkgsModule
        ./hosts/mac/configuration.nix
      ];
    };

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
  in {
    inherit nixosConfigurations darwinConfigurations;
    lib = repoLib;

    apps = forLinuxSystems (system: mkApps (mkPkgs system));
    devShells = forAllSystems (system: mkDevShells (mkPkgs system));
    formatter = forAllSystems (system: (mkPkgs system).alejandra);

    packages = forLinuxSystems (system: let
      pkgs = mkPkgs system;
    in {
      submap-cheatsheet = pkgs.callPackage ./packages/submap-cheatsheet {};
      smart-focus = pkgs.callPackage ./packages/smart-focus {};
    });

    # Build these explicitly when changing the corresponding custom runtime code.
    checks.x86_64-linux = let
      pkgs = mkPkgs "x86_64-linux";
      leo = self.nixosConfigurations.leo.config;
      nixvim = leo.home-manager.users.${leo.modules.profile.username}.programs.nixvim.build;
    in {
      smart-focus = pkgs.callPackage ./packages/smart-focus {};
      hyprland-runtime = pkgs.runCommand "hyprland-runtime" {nativeBuildInputs = [pkgs.lua5_4];} ''
        find ${./modules/home/hyprland/lua} -name '*.lua' -print0 | xargs -0 luac -p
        lua ${./modules/home/hyprland/tests/monitor-controller.lua} \
          ${./modules/home/hyprland/lua/monitor-states.lua}
        lua ${./modules/home/hyprland/tests/smart-focus.lua} ${./modules/home/hyprland/lua/smart-focus.lua}
        lua ${./modules/home/hyprland/tests/runtime-helpers.lua} \
          ${./modules/home/hyprland/lua/state.lua} \
          ${./modules/home/hyprland/lua/dispatch.lua} \
          ${./modules/home/hyprland/lua/terminal.lua} \
          ${./modules/home/hyprland/lua/feedback.lua}
        lua ${./modules/home/hyprland/tests/state-producers.lua} \
          ${./modules/home/hyprland/lua/state-watchers.lua} \
          ${./modules/home/hyprland/lua/sunshine.lua}
        touch "$out"
      '';
      smart-focus-integration =
        pkgs.runCommand "smart-focus-integration" {
          nativeBuildInputs = [pkgs.python3 pkgs.neovim pkgs.zellij pkgs.bash];
        } ''
          python ${./packages/smart-focus/tests/integration.py} \
            ${lib.getExe (pkgs.callPackage ./packages/smart-focus {})} \
            ${./modules/home/neovim/lua/juicy/smart_focus.lua}
          touch "$out"
        '';
      ha-presence-state-engine =
        pkgs.runCommand "ha-presence-state-engine" {
          nativeBuildInputs = [
            (pkgs.python3.withPackages (pythonPackages: [pythonPackages.paho-mqtt]))
          ];
        } ''
          python ${./modules/home/tests/ha-presence.py} ${./modules/home/ha-presence.py}
          touch "$out"
        '';
      nixvim-smoke = pkgs.runCommand "nixvim-smoke" {} ''
        export HOME="$TMPDIR/home"
        export XDG_CONFIG_HOME="$TMPDIR/config"
        export XDG_DATA_HOME="$TMPDIR/data"
        export XDG_STATE_HOME="$TMPDIR/state"
        export XDG_CACHE_HOME="$TMPDIR/cache"
        mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"
        ln -s ${nixvim.extraFiles} "$XDG_CONFIG_HOME/nvim"

        ${nixvim.package}/bin/nvim --headless \
          +"luafile ${nixvim.initFile}" \
          +"luafile ${./modules/home/neovim/tests/contract.lua}" \
          +"luafile ${./modules/home/neovim/tests/neorg-contract.lua}" \
          +qa!
        touch "$out"
      '';
      monitoring-config = pkgs.runCommand "monitoring-config" {nativeBuildInputs = with pkgs; [bash jq prometheus.cli shellcheck];} ''
        bash -n ${./modules/nixos/monitoring/homelab-health-metrics.sh}
        shellcheck ${./modules/nixos/monitoring/homelab-health-metrics.sh}
        promtool check rules ${./modules/nixos/monitoring/prometheus-rules.yml}
        for dashboard in ${./modules/nixos/grafana-dashboards}/*.json; do
          jq empty "$dashboard"
        done
        touch "$out"
      '';
    };
  };
}

{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";

    nixflix = {
      url = "github:kiriwalawren/nixflix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    emacs-overlay.url = "github:nix-community/emacs-overlay";
    emacs-overlay.inputs.nixpkgs.follows = "nixpkgs";

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:danth/stylix";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-claude-code = {
      url = "github:ryoppippi/nix-claude-code";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    nix-darwin,
    ...
  }: let
    inherit (nixpkgs) lib;

    systems = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];

    mkPkgs = system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [inputs.nix-claude-code.overlays.default];
      };

    homeProfiles = let
      hm = self.homeModules;
    in rec {
      cli = with hm; [
        atuin
        bat
        btop
        editorconfig
        eza
        fastfetch
        fzf
        git
        lazygit
        neovim
        ripgrep
        ssh
        starship
        tmux
        yazi
        zoxide
        zsh
      ];

      desktop =
        cli
        ++ (with hm; [
          barrier
          chromium
          emacs
          gtk
          ha-presence
          hyprland
          kitty
          mime-apps
          mpv
          noctalia-shell
          obs
          qutebrowser
          shairport
          xdg-desktop-entries
          xdg-user-dirs
          xresources
        ]);

      darwin =
        cli
        ++ (with hm; [
          emacs
          kitty
          mpv
          qutebrowser
          xdg-user-dirs
        ]);
    };

    specialArgs = system: {
      inherit inputs self system homeProfiles;
    };

    mkNixosHost = {
      name,
      system,
      extraModules ? [],
      includeHardware ? true,
    }:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = specialArgs system;
        modules =
          [
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
          ./hosts/${name}/configuration.nix
        ];
      };

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
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      inherit systems;

      imports = [
        inputs.treefmt-nix.flakeModule
      ];

      flake = {
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
              inputs.nixflix.nixosModules.default
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

        darwinConfigurations = {
          mac = mkDarwinHost "mac" "aarch64-darwin";
        };

        nixosModules = {
          acme = import ./modules/nixos/acme.nix;
          desktop = import ./modules/nixos/desktop;
          emacs = import ./modules/nixos/emacs.nix;
          filebrowser = import ./modules/nixos/filebrowser.nix;
          fonts = import ./modules/nixos/fonts.nix;
          glance = import ./modules/nixos/glance.nix;
          ha-presence = import ./modules/nixos/ha-presence.nix;
          homelab = import ./modules/nixos/homelab;
          htb = import ./modules/nixos/htb.nix;
          impermanence = import ./modules/nixos/impermanence.nix;
          ios = import ./modules/nixos/ios.nix;
          monitoring = import ./modules/nixos/monitoring;
          network = import ./modules/nixos/network.nix;
          nfs = import ./modules/nixos/nfs.nix;
          pipewire = import ./modules/nixos/pipewire.nix;
          ports = import ./modules/nixos/ports.nix;
          recomp = import ./modules/nixos/recomp.nix;
          shairport = import ./modules/nixos/shairport.nix;
          shell = import ./modules/nixos/shell.nix;
          stylix = import ./modules/nixos/stylix.nix;
          sunshine = import ./modules/nixos/sunshine.nix;
          system = import ./modules/nixos/system.nix;
          tailscale = import ./modules/nixos/tailscale.nix;
          unbound = import ./modules/nixos/unbound.nix;
        };

        darwinModules = {
          system = import ./modules/darwin/system.nix;
        };

        homeModules = {
          atuin = import ./modules/home/atuin.nix;
          barrier = import ./modules/home/barrier.nix;
          bat = import ./modules/home/bat.nix;
          btop = import ./modules/home/btop.nix;
          chromium = import ./modules/home/chromium.nix;
          editorconfig = import ./modules/home/editorconfig.nix;
          emacs = import ./modules/home/emacs.nix;
          eza = import ./modules/home/eza.nix;
          fastfetch = import ./modules/home/fastfetch.nix;
          fzf = import ./modules/home/fzf.nix;
          git = import ./modules/home/git.nix;
          gtk = import ./modules/home/gtk.nix;
          ha-presence = import ./modules/home/ha-presence.nix;
          hyprland = import ./modules/home/hyprland.nix;
          kitty = import ./modules/home/kitty.nix;
          lazygit = import ./modules/home/lazygit.nix;
          mime-apps = import ./modules/home/mime-apps.nix;
          mpv = import ./modules/home/mpv.nix;
          neovim = import ./modules/home/neovim;
          noctalia-shell = import ./modules/home/noctalia-shell.nix;
          obs = import ./modules/home/obs.nix;
          qutebrowser = import ./modules/home/qutebrowser.nix;
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

        lib = lib.genAttrs systems (
          _system:
            import ./lib {
              inherit (nixpkgs) lib;
            }
        );
      };

      perSystem = {
        config,
        pkgs,
        system,
        ...
      }: {
        _module.args.pkgs = mkPkgs system;

        treefmt = {
          projectRootFile = "flake.nix";
          programs = {
            alejandra.enable = true;
            statix.enable = true;
            deadnix.enable = true;
          };
        };

        devShells =
          {
            default = pkgs.mkShell {
              packages = [
                pkgs.alejandra
                pkgs.statix
                pkgs.deadnix
                pkgs.nixd
                pkgs.treefmt
              ];
              shellHook = ''
                fastfetch
              '';
            };
          }
          // lib.optionalAttrs (system == "x86_64-linux") {
            htb = pkgs.mkShell {
              packages = [
                pkgs.nmap
                pkgs.rustscan
                pkgs.masscan
                pkgs.enum4linux-ng
                pkgs.dnsenum
                pkgs.burpsuite
                pkgs.feroxbuster
                pkgs.gobuster
                pkgs.ffuf
                pkgs.sqlmap
                pkgs.nuclei
                pkgs.wfuzz
                pkgs.metasploit
                pkgs.exploitdb
                pkgs.python3Packages.pwntools
                pkgs.evil-winrm
                pkgs.netexec
                pkgs.python3Packages.impacket
                pkgs.bloodhound
                pkgs.responder
                pkgs.smbmap
                pkgs.hashcat
                pkgs.john
                pkgs.thc-hydra
                pkgs.chisel
                pkgs.ligolo-ng
                pkgs.proxychains-ng
                pkgs.ghidra
                pkgs.wireshark
                pkgs.tcpdump
                pkgs.netcat-gnu
                pkgs.pwncat
                pkgs.seclists
                pkgs.wordlists
                pkgs.openvpn
                pkgs.rlwrap
              ];
              shellHook = ''
                echo ""
                echo "  HTB / Pentesting Shell"
                echo "  nmap rustscan masscan       Scanning"
                echo "  feroxbuster gobuster ffuf   Web"
                echo "  evil-winrm netexec impacket Win/AD"
                echo "  metasploit sqlmap pwntools  Exploit"
                echo "  hashcat john hydra          Passwords"
                echo "  chisel ligolo proxychains   Pivoting"
                echo "  ghidra                      Rev. Eng."
                echo "  wireshark tcpdump netcat    Network"
                echo "  seclists wordlists          Wordlists"
                echo ""
              '';
            };
          };

        apps = lib.optionalAttrs pkgs.stdenv.isLinux (deploymentApps pkgs);

        formatter = config.treefmt.build.wrapper;

        checks =
          lib.optionalAttrs (system == "x86_64-linux") {
            leo-eval = self.nixosConfigurations.leo.config.system.build.toplevel;
            fallarbor-eval = self.nixosConfigurations.fallarbor.config.system.build.toplevel;
            zues-eval = self.nixosConfigurations.zues.config.system.build.toplevel;
            iso-eval = self.nixosConfigurations.iso.config.system.build.isoImage;

            hyprland-lua-lint = let
              renderedText =
                self.nixosConfigurations.leo.config.home-manager.users.juicy.xdg.configFile."hypr/hyprland.lua".text;
              renderedFile = pkgs.writeText "hyprland.lua" renderedText;
              luarc = ./modules/home/hyprland/lua/.luarc.json;
              meta = ./modules/home/hyprland/lua/hl.meta.lua;
            in
              pkgs.runCommand "hyprland-lua-lint"
              {
                buildInputs = [
                  pkgs.lua-language-server
                  pkgs.jq
                ];
              }
              ''
                mkdir -p work logs
                cp ${renderedFile} work/hyprland.lua
                cp ${meta}         work/hl.meta.lua
                cp ${luarc}        work/.luarc.json

                export HOME="$TMPDIR/home"
                mkdir -p "$HOME"

                lua-language-server \
                  --check="$PWD/work" \
                  --check_format=json \
                  --check_out_path="$PWD/logs/result.json" \
                  --checklevel=Warning \
                  --logpath="$PWD/logs" \
                  >/dev/null 2>&1 || true

                if [ ! -s logs/result.json ] || [ "$(tr -d '[:space:]' < logs/result.json)" = "[]" ]; then
                  touch "$out"
                else
                  echo "lua-language-server reported diagnostics in rendered hyprland.lua:"
                  jq . logs/result.json
                  exit 1
                fi
              '';
          }
          // lib.optionalAttrs (system == "aarch64-darwin") {
            mac-eval = self.darwinConfigurations.mac.system;
          };
      };
    };
}

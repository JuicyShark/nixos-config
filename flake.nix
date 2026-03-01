{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    emacs-overlay.url = "github:nix-community/emacs-overlay";
    emacs-overlay.inputs.nixpkgs.follows = "nixpkgs";

    caelestia-shell.url = "github:caelestia-dots/shell";

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
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    let
      inherit (nixpkgs.lib)
        genAttrs
        hasSuffix
        nixosSystem
        replaceStrings
        ;
      inherit (nixpkgs.lib.filesystem) packagesFromDirectoryRecursive listFilesRecursive;
      rootPath = toString self;

      forAllSystems =
        function:
        genAttrs
          [
            "x86_64-linux"
            "aarch64-linux"
          ]
          (
            system:
            function (
              import nixpkgs {
                inherit system;
                config.allowUnfree = true;
              }
            )
          );

      nameOf =
        path:
        builtins.unsafeDiscardStringContext (replaceStrings [ ".nix" ] [ "" ] (baseNameOf (toString path)));

      modulesFrom =
        dir:
        genAttrs (map nameOf (
          builtins.filter (path: hasSuffix ".nix" (toString path)) (listFilesRecursive dir)
        )) (name: import (dir + "/${name}.nix"));

      modulesFromRel =
        relPath:
        let
          dir = "${rootPath}/${relPath}";
        in
        if builtins.pathExists dir then modulesFrom (builtins.toPath dir) else { };

      mkNixosHost =
        hostName:
        nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
            nix-config = self;
          };
          modules = listFilesRecursive ./hosts/${hostName};
        };
    in
    {
      # Shared library functions for use across modules
      lib = forAllSystems (
        pkgs:
        import ./lib {
          inherit pkgs;
          inherit (nixpkgs) lib;
        }
      );

      packages = forAllSystems (
        pkgs:
        let
          rawPackages = packagesFromDirectoryRecursive {
            inherit (pkgs) callPackage;

            directory = ./packages;
          };
        in
        rawPackages
        // {
          peon-ping = rawPackages.peon-ping.default;
          default = rawPackages.peon-ping.default;
        }
      );

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          shellHook = ''
            fastfetch
          '';
        };
      });
      nixosModules = modulesFromRel "modules/nixos";
      homeModules = modulesFromRel "home";

      nixosConfigurations = genAttrs [ "leo" "fallarbor" "zues" ] mkNixosHost;
      formatter = forAllSystems (pkgs: pkgs.alejandra);
      checks.x86_64-linux =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          smartFocusAction = import ./lib/smart-focus-action.nix { inherit pkgs; };
          smartFocusActionExe = pkgs.lib.getExe smartFocusAction;
          tmuxTerminalAction = import ./lib/tmux-terminal-action.nix { inherit pkgs; };
          tmuxTerminalActionExe = pkgs.lib.getExe tmuxTerminalAction;
        in
        {
          leo-eval = self.nixosConfigurations.leo.config.system.build.toplevel;
          fallarbor-eval = self.nixosConfigurations.fallarbor.config.system.build.toplevel;
          zues-eval = self.nixosConfigurations.zues.config.system.build.toplevel;
          format-check = pkgs.runCommand "nix-format-check" { buildInputs = [ pkgs.alejandra ]; } ''
            cd ${self}
            alejandra --check .
            touch "$out"
          '';
          smart-movement-test =
            pkgs.runCommand "smart-movement-test"
              {
                buildInputs = [
                  pkgs.bash
                  pkgs.coreutils
                  pkgs.gnugrep
                  pkgs.jq
                  pkgs.procps
                  pkgs.tmux
                ];
              }
              ''
                    set -euo pipefail

                export HOME="$TMPDIR/home"
                mkdir -p "$HOME"
                export TERM="xterm-256color"

                    export TMUX_TMPDIR="$TMPDIR/tmux"
                    mkdir -p "$TMUX_TMPDIR"

                    tmux kill-server >/dev/null 2>&1 || true

                    tmux new-session -d -s main -n focus "sleep 1000"
                    tmux split-window -h -t main:focus
                    tmux select-pane -t main:focus.1

                    focused_before="$(tmux display-message -p -t main:focus '#{pane_index}')"
                    [ "$focused_before" = "1" ]

                    tmux_server_pid="$(pgrep -xo tmux)"
                    [ -n "$tmux_server_pid" ]

                    mkdir -p "$TMPDIR/mockbin"
                    cat > "$TMPDIR/mockbin/hyprctl" <<'EOF'
                    #!/usr/bin/env bash
                    set -euo pipefail

                    if [ "''${1:-}" = "activewindow" ] && [ "''${2:-}" = "-j" ]; then
                      printf '{"class":"kitty","pid":%s}\n' "$TEST_ACTIVE_PID"
                      exit 0
                    fi

                    if [ "''${1:-}" = "dispatch" ] && [ "''${2:-}" = "sendshortcut" ]; then
                      case "''${3:-}" in
                        "CTRL, left, activewindow") tmux select-pane -t main:focus -L ;;
                        "CTRL, right, activewindow") tmux select-pane -t main:focus -R ;;
                        "CTRL, up, activewindow") tmux select-pane -t main:focus -U || true ;;
                        "CTRL, down, activewindow") tmux select-pane -t main:focus -D || true ;;
                        *) exit 10 ;;
                      esac
                      exit 0
                    fi

                    if [ "''${1:-}" = "dispatch" ] && [ "''${2:-}" = "movefocus" ]; then
                      printf '%s\n' "''${3:-}" >> "$TMPDIR/movefocus.log"
                      exit 0
                    fi

                    exit 11
                    EOF
                    chmod +x "$TMPDIR/mockbin/hyprctl"
                    export PATH="$TMPDIR/mockbin:$PATH"

                    export HYPRLAND_INSTANCE_SIGNATURE="test"
                    export TEST_ACTIVE_PID="$tmux_server_pid"

                    ${smartFocusActionExe} left auto
                    focused_after_left="$(tmux display-message -p -t main:focus '#{pane_index}')"
                    [ "$focused_after_left" = "0" ]

                    ${smartFocusActionExe} right auto
                    focused_after_right="$(tmux display-message -p -t main:focus '#{pane_index}')"
                    [ "$focused_after_right" = "1" ]

                    ${tmuxTerminalActionExe} new-window
                    window_count="$(tmux list-windows -t main | wc -l)"
                    [ "$window_count" -ge 2 ]

                    tmux select-window -t main:0
                    ${tmuxTerminalActionExe} next-window
                    [ "$(tmux display-message -p -t main '#{window_index}')" = "1" ]

                    ${tmuxTerminalActionExe} prev-window
                    [ "$(tmux display-message -p -t main '#{window_index}')" = "0" ]

                    touch "$out"
              '';
        };
    };
}

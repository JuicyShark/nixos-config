{
  self,
  lib,
  ...
}: {
  perSystem = {
    config,
    pkgs,
    system,
    ...
  }: {
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
          luarc = ../modules/home/hyprland/lua/.luarc.json;
          meta = ../modules/home/hyprland/lua/hl.meta.lua;
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
}

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
        hyprland-lua-syntax = pkgs.runCommand "hyprland-lua-syntax" {nativeBuildInputs = [pkgs.lua5_4];} ''
          find ${../modules/home/hyprland/lua} -name '*.lua' -print0 | xargs -0 luac -p
          touch "$out"
        '';
        leo-eval = self.nixosConfigurations.leo.config.system.build.toplevel;
        fallarbor-eval = self.nixosConfigurations.fallarbor.config.system.build.toplevel;
        zues-eval = self.nixosConfigurations.zues.config.system.build.toplevel;
        iso-eval = self.nixosConfigurations.iso.config.system.build.isoImage;
      }
      // lib.optionalAttrs (system == "aarch64-darwin") {
        mac-eval = self.darwinConfigurations.mac.system;
      };
  };
}

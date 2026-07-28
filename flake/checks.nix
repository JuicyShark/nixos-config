{
  self,
  mkPkgs,
}: system: let
  pkgs = mkPkgs system;
  hyprlandLuaSyntax = pkgs.runCommand "hyprland-lua-syntax" {nativeBuildInputs = [pkgs.lua5_4];} ''
    find ${../modules/home/hyprland/lua} -name '*.lua' -print0 | xargs -0 luac -p
    touch "$out"
  '';
  hyprlandMonitorPolicy = pkgs.runCommand "hyprland-monitor-policy" {nativeBuildInputs = [pkgs.lua5_4];} ''
    lua ${../modules/home/hyprland/tests/monitor-policy.lua} ${../modules/home/hyprland/lua/monitor-policy.lua}
    lua ${../modules/home/hyprland/tests/monitor-controller.lua} \
      ${../modules/home/hyprland/lua/monitor-policy.lua} \
      ${../modules/home/hyprland/lua/monitor-states.lua}
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
      +"luafile ${../modules/home/neovim/tests/contract.lua}" \
      +"luafile ${../modules/home/neovim/tests/neorg-contract.lua}" \
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
  monitoringConfig = pkgs.runCommand "monitoring-config" {nativeBuildInputs = with pkgs; [jq prometheus.cli];} ''
    promtool check rules ${../modules/nixos/monitoring/prometheus-rules.yml}
    for dashboard in ${../modules/nixos/grafana-dashboards}/*.json; do
      jq empty "$dashboard"
    done
    touch "$out"
  '';
in {
  inherit static;
  hyprland-lua-syntax = hyprlandLuaSyntax;
  hyprland-monitor-policy = hyprlandMonitorPolicy;
  monitoring-config = monitoringConfig;
  nixvim-smoke = nixvimSmoke;
  leo-eval = self.nixosConfigurations.leo.config.system.build.toplevel;
  fallarbor-eval = self.nixosConfigurations.fallarbor.config.system.build.toplevel;
  zues-eval = self.nixosConfigurations.zues.config.system.build.toplevel;
  iso-eval = self.nixosConfigurations.iso.config.system.build.isoImage;
}

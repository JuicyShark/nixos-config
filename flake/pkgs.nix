{
  inputs,
  lib,
  ...
}: let
  unfreePackages = [
    "2ship2harkinian"
    "bloodhound"
    "burpsuite"
    "castlabs-electron"
    "claude"
    "discord"
    "hashcat"
    "keymapp"
    "metasploit"
    "n64recomp"
    "aspell-dict-en-science"
    "obsidian"
    "osu-lazer-bin"
    "shipwright"
    "steam"
    "steam-unwrapped"
    "vivaldi"
    "wowup-cf"
    "xone-dongle-firmware"
  ];

  nixpkgsOverlays = [
    inputs.emacs-overlay.overlays.default
    inputs.nix-claude-code.overlays.default
    (_final: prev: {
      hyprlandPlugins =
        prev.hyprlandPlugins
        // {
          hyprbars = prev.hyprlandPlugins.hyprbars.overrideAttrs (old: {
            postPatch =
              (old.postPatch or "")
              + ''
                sed -i '/#include <hyprland\/src\/Compositor.hpp>/a #include <hyprland/src/state/MonitorState.hpp>' main.cpp
                substituteInPlace main.cpp \
                  --replace-fail 'g_pCompositor->m_monitors' 'State::monitorState()->monitors()'
              '';
          });
          hy3 = inputs.hy3.packages.${prev.stdenv.hostPlatform.system}.hy3.overrideAttrs (old: {
            postPatch =
              (old.postPatch or "")
              + ''
                substituteInPlace src/Hy3Layout.cpp \
                  --replace-fail '#include <hyprland/src/state/WorkspaceState.hpp>' "" \
                  --replace-fail 'State::workspaceState()->query().id(target.id).run()' 'g_pCompositor->getWorkspaceByID(target.id)' \
                  --replace-fail 'State::workspaceState()->create(target.id, origin_ws->monitorID(), target.name)' 'g_pCompositor->createNewWorkspace(target.id, origin_ws->monitorID(), target.name)'
                sed -i '/auto next_monitor = State::monitorState()/,+4c\	auto next_monitor = g_pCompositor->getMonitorInDirection(this->monitor().lock(), shiftToMathDirection(direction));' src/Hy3Layout.cpp
              '';
          });
        };
    })
  ];

  nixpkgsConfig = {
    allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) unfreePackages;
  };

  mkPkgs = system:
    import inputs.nixpkgs {
      inherit system;
      config = nixpkgsConfig;
      overlays = nixpkgsOverlays;
    };
in {
  _module.args = {
    inherit mkPkgs nixpkgsConfig nixpkgsOverlays unfreePackages;
  };

  perSystem = {system, ...}: {
    _module.args.pkgs = mkPkgs system;
  };
}

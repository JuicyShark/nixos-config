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

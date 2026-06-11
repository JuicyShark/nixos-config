# nix-config

Personal NixOS and nix-darwin configuration.

## Shape

```text
flake.nix       Input pins and the flake-parts entrypoint.
flake/          Explicit hosts, module exports, pkgs policy, apps, shells, and checks.
hosts/          Machine-specific NixOS/nix-darwin configuration.
modules/common/ Shared NixOS/nix-darwin modules.
modules/nixos/  NixOS-only modules.
modules/darwin/ nix-darwin-only modules.
modules/home/   Home Manager modules.
lib/            Pure helper functions used by modules and checks.
secrets/        agenix-encrypted secrets.
```

## Common Commands

```bash
nix flake check --keep-going
nix flake check --all-systems --no-build
nix develop -c statix check
nix develop -c deadnix --fail
nix fmt
sudo nixos-rebuild switch --flake .#leo
sudo nixos-rebuild switch --flake .#zues
nix build .#nixosConfigurations.iso.config.system.build.isoImage
```

## Validation

CI mirrors the local fast path:

```bash
nix flake check --all-systems --no-build
nix build \
  .#checks.x86_64-linux.treefmt \
  .#checks.x86_64-linux.hyprland-lua-lint \
  --no-link
```

The repo has an optional pre-push hook in `.githooks/pre-push`. To install it from the dev shell:

```bash
NIX_CONFIG_AUTO_HOOKS=1 nix develop
```

## Backup Recovery Notes

`zues` creates restic repository passwords on first backup run:

- `/var/lib/restic-services/password`
- `/var/lib/restic-family/password`

Keep offline copies of both files. A restore requires the matching password file; copy it back to the same path with root-only permissions before running restic or pass it with `restic --password-file`.

[NixOS]: https://nixos.org/
[Nix Flakes]: https://wiki.nixos.org/wiki/Flakes
[Agenix]: https://github.com/ryantm/agenix
[Home Manager]: https://nix-community.github.io/home-manager/
[Stylix]: https://danth.github.io/stylix/
[Hyprland]: https://hyprland.org/

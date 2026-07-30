# nix-config

Personal NixOS and nix-darwin configuration.

## Shape

```text
flake.nix       Input pins, host outputs, module exports, pkgs policy, apps, shells, and checks.
hosts/          Machine-specific NixOS/nix-darwin configuration.
modules/common/ Shared NixOS/nix-darwin modules.
modules/nixos/  NixOS-only modules.
modules/darwin/ nix-darwin-only modules.
modules/home/   Home Manager modules.
lib/            Pure helper functions used by modules and checks.
secrets/        agenix-encrypted secrets.
```

## Design

`flake.nix` is deliberately the one top-level map: package policy, module
catalog, Home Manager profiles, host constructors, local apps, dev shells, and
checks are labeled sections in that file. Host files compose named modules and
set machine facts; feature modules own the behavior. This keeps the route from
a host to its configuration visible without a second layer of flake imports.

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
  .#checks.x86_64-linux.static \
  .#checks.x86_64-linux.hyprland-lua-syntax \
  --no-link
```

The repo has an optional pre-push hook in `.githooks/pre-push`. To enable it:

```bash
git config core.hooksPath .githooks
```

## Backup Recovery Notes

Leo and Zues use the same age-managed Restic credential:

- Zues service state and family data are backed up from `chonk` to
  `/mnt/smol/backups/zues-*`.
- Leo's shared Git and Nix configuration are backed up from `smol` to
  `/mnt/chonk/backups/leo-smol`.

Recover the repository password with:

```bash
age --decrypt -i ~/.ssh/id_ed25519 secrets/restic-repository-password.age
```

The initrd emergency shell uses a dedicated generated password, not the login
password. Recover it for offline storage with:

```bash
age --decrypt -i ~/.ssh/id_ed25519 secrets/initrd-recovery-password.age
```

[NixOS]: https://nixos.org/
[Nix Flakes]: https://wiki.nixos.org/wiki/Flakes
[Agenix]: https://github.com/ryantm/agenix
[Home Manager]: https://nix-community.github.io/home-manager/
[Stylix]: https://danth.github.io/stylix/
[Hyprland]: https://hyprland.org/

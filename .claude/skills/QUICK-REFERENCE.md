# NixOS Config Quick Reference Card

## ⚠️ Critical Settings

```nix
home-manager.useGlobalPkgs = false  // System and Home Manager have SEPARATE package sets!
```

## Command Pattern

```bash
# ALWAYS use this pattern for tools not in environment
nix-shell -p <package> --run '<command>'

# Examples
nix-shell -p alejandra --run 'alejandra .'
nix-shell -p manix --run 'manix services.nginx'
nix-shell -p ripgrep --run 'rg "pattern" -A 5'
```

## Where Do Overlays Go?

| Package Type | Overlay Location | File |
|--------------|------------------|------|
| Home Manager | `home/*.nix` | Create `home/overlays.nix` |
| System | `modules/nixos/*.nix` | e.g., `modules/nixos/system.nix` |

**Why?** Because `useGlobalPkgs = false`, they have separate package sets!

## Where Do Packages Go?

| Package Type | Location | Variable |
|--------------|----------|----------|
| User apps/tools | Home Manager | `home.packages = with pkgs; [ ... ];` |
| System services | NixOS | `environment.systemPackages = with pkgs; [ ... ];` |

## Module Loading

| Module Type | Location | How Loaded | Example |
|-------------|----------|------------|---------|
| NixOS | `modules/nixos/` | Explicit `imports = [ ... ]` | `system`, `desktop` |
| Home | `home/` | Auto via `sharedModules` | `git.nix`, `tmux.nix` |

## Build Commands

```bash
# Test (no boot entry)
sudo nixos-rebuild test --flake .#leo

# Switch (creates boot entry)
sudo nixos-rebuild switch --flake .#leo

# Build only (no activation)
sudo nixos-rebuild build --flake .#leo

# Show what will build
nix flake show
```

## Common Tasks

### Add Package from Flake Input

1. Add to `flake.nix` inputs
2. `nix flake lock --update-input <name>`
3. For Home Manager: Create `home/<name>.nix` with overlay
4. For System: Add overlay to system module
5. `sudo nixos-rebuild switch --flake .#leo`

### Add NixOS Service Module

1. Create `modules/nixos/<service>.nix`
2. Add to host config: `imports = with nix-config.nixosModules; [ <service> ];`
3. Configure in host: `modules.<service> = { enable = true; };`

### Add Home Manager Config

1. Create `home/<program>.nix`
2. Auto-loaded via `sharedModules`
3. Configure with `programs.<program> = { ... };`

## Debugging

### Package Not Found?

```bash
# Check Home Manager packages
nix eval .#nixosConfigurations.leo.config.home-manager.users.juicy.home.packages --apply "map (p: p.pname)"

# Check system packages
nix eval .#nixosConfigurations.leo.config.environment.systemPackages --apply "map (p: p.pname)"

# Check overlay count
nix eval .#nixosConfigurations.leo.config.home-manager.users.juicy.nixpkgs.overlays --apply "builtins.length"
```

### Config Changes Not Applying?

1. Did you rebuild? `sudo nixos-rebuild switch --flake .#leo`
2. Is module imported? Check `imports = [ ... ]` in host config
3. Check syntax: `nix flake check`
4. Verbose: `nixos-rebuild switch --flake .#leo --show-trace`

### Overlay Not Working?

1. Check `useGlobalPkgs` setting (currently `false`)
2. For Home Manager packages → overlay in `home/*.nix`
3. For system packages → overlay in system module
4. Verify: `nix repl` → `:lf .` → `:p nixosConfigurations.leo.pkgs.yourPackage`

## File Locations

| Config Type | File Path |
|-------------|-----------|
| Flake | `./flake.nix` |
| System module | `./modules/nixos/system.nix` |
| Host config | `./hosts/leo/configuration.nix` |
| Home modules | `./home/*.nix` |
| Custom packages | `./packages/*/default.nix` |

## Hosts

- `leo` - Desktop (main)
- `fallarbor` - Server
- `zues` - Desktop (secondary)

Default user: `juicy`

## Maintenance

```bash
# Format
nix fmt

# Check
nix flake check

# Update all inputs
nix flake update

# Update specific input
nix flake lock --update-input nixpkgs

# Garbage collect
nix-collect-garbage -d
sudo nix-collect-garbage -d
```

## Help

```bash
# Find options
nix-shell -p manix --run 'manix <search>'

# Search packages
nix search nixpkgs <term>

# Check option value
nix eval .#nixosConfigurations.leo.config.services.<service>.enable
```

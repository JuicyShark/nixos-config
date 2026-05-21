---
name: nixos-config-helper
description: Ensures commands use nix-shell properly, considers flake layout, discovers NixOS/Home Manager configuration options, and follows overlay/home-manager best practices
license: MIT
metadata:
  author: AI Assistant
  version: "2.0.0"
---

# NixOS Configuration Helper Skill

This skill provides guidance for working with NixOS configurations, ensuring proper command execution with nix-shell, flake-aware operations, configuration option discovery, and correct overlay/home-manager usage.

## Core Principles

### Critical: Overlay and Home Manager Integration

**ALWAYS check `home-manager.useGlobalPkgs` setting before adding overlays!**

Current configuration (from `modules/nixos/system.nix:187`):
```nix
home-manager.useGlobalPkgs = false;
```

This means:
- ❌ System-level `nixpkgs.overlays` do NOT affect Home Manager packages
- ✅ Home Manager has its own separate pkgs instance
- ✅ Overlays for Home Manager packages must be defined in home-manager configuration
- ✅ Each user can have different package sets and overlays

#### Overlay Scope Decision Matrix

| useGlobalPkgs | Where to Define Overlay | Affects |
|---------------|------------------------|---------|
| `false` (CURRENT) | `home.nix` with `nixpkgs.overlays` | Home Manager packages only |
| `false` (CURRENT) | System `nixpkgs.overlays` | System packages only (NOT Home Manager) |
| `true` | `home-manager.nixpkgs.overlays` in host config | Both system + Home Manager |
| `true` | `home.nix` with `nixpkgs.overlays` | **Nothing** (ignored!) |

#### Common Overlay Mistakes to Avoid

**❌ WRONG: Adding overlay to system config expecting it to affect Home Manager packages (when useGlobalPkgs=false)**
```nix
# hosts/leo/configuration.nix or modules/nixos/system.nix
{
  nixpkgs.overlays = [ inputs.some-overlay.overlays.default ];
  # This will NOT affect Home Manager packages!
}
```

**✅ CORRECT: For current config (useGlobalPkgs=false), add to Home Manager modules**
```nix
# home/<module>.nix or create new overlay module
{ inputs, ... }:
{
  nixpkgs.overlays = [ 
    inputs.some-overlay.overlays.default 
    (final: prev: {
      # Custom overlay modifications
    })
  ];
}
```

**✅ ALSO CORRECT: System-only overlays (for system services)**
```nix
# modules/nixos/system.nix or host config
{
  nixpkgs.overlays = [ 
    # This affects system packages only (services, systemPackages, etc.)
    (final: prev: {
      customSystemPackage = prev.package.override { ... };
    })
  ];
}
```

#### Red Flags - STOP and Check Overlay Scope

- "Overlay in home.nix isn't working" → Verify it's in the RIGHT home.nix module location
- "Package available in nix repl but not installed" → Check if overlay is in correct scope
- "Changes don't apply after rebuild" → Verify overlay location matches useGlobalPkgs setting
- "I'll add overlays everywhere" → Define once at the appropriate scope
- "Should I change useGlobalPkgs?" → Only if you need unified package sets (typically for single-user systems)

### 1. Command Execution with nix-shell

**CRITICAL: When running commands not available in the current environment, ALWAYS use nix-shell!**

Pattern:
```bash
nix-shell -p <package> --run '<command>'
```

**Examples:**
- `nix-shell -p nixpkgs-fmt --run 'nixpkgs-fmt --check .'`
- `nix-shell -p alejandra --run 'alejandra --check .'`
- `nix-shell -p jq --run 'jq . flake.lock'`
- `nix-shell -p manix --run 'manix services.nginx'`
- `nix-shell -p ripgrep --run 'rg "pattern" -A 5'`

**Important Notes:**
- Use single quotes for the command to prevent shell expansion
- For commands with arguments, include them within the single quotes
- Package names may differ from command names (e.g., `nixpkgs-fmt` package for `nixpkgs-fmt` command)
- NEVER assume a tool is globally available - always use nix-shell for consistency

### 2. Flake Layout Awareness

This configuration uses a flake-based structure. Always consider:

#### Directory Structure
```
nixos-config/
├── flake.nix          # Main flake configuration
├── flake.lock         # Locked dependency versions
├── hosts/             # Per-host configurations
│   ├── leo/
│   ├── fallarbor/
│   └── zues/
├── modules/           # Reusable NixOS modules
│   └── nixos/
├── home/              # Home Manager configurations
├── packages/          # Custom package definitions
├── lib/               # Helper functions and utilities
└── secrets/           # agenix encrypted secrets
```

#### Key Flake Outputs
Based on `flake.nix:91-118`, the flake provides:
- `packages.<system>.*` - Custom packages (line 92-105)
- `devShells.<system>.default` - Development shell (line 107-113)
- `nixosModules.*` - Reusable NixOS modules from `modules/nixos/` (line 114)
- `homeModules.*` - Home Manager modules from `home/` (line 115)
- `nixosConfigurations.*` - Host configurations (leo, fallarbor, zues) (line 117)
- `formatter.<system>` - Code formatter (alejandra) (line 118)
- `checks.<system>.*` - CI checks (line 119-223)

#### Flake Inputs
From `flake.nix:2-34`:
- `nixpkgs` - NixOS/nixpkgs unstable
- `home-manager` - Home configuration management
- `emacs-overlay` - Emacs packages
- `caelestia-shell` - Custom shell configuration
- `agenix` - Secret management
- `stylix` - System-wide theming
- `hyprland` - Wayland compositor
- `nixvim` - Neovim configuration

### 3. Configuration Option Discovery

When discovering configuration options for services and programs:

#### Method 1: Search NixOS Options (for system services)
```bash
nix-shell -p nix-search --run 'nix search nixpkgs#<package-name>'
```

#### Method 2: Use `nixos-option` (on NixOS systems)
```bash
nixos-option services.<service-name>
```

#### Method 3: Browse Options in nixpkgs
```bash
# Search for module definition
nix-shell -p ripgrep --run 'rg "services\.<service>" -A 20'

# View specific module from nixpkgs
nix-shell -p bat --run 'bat $(nix-build --no-out-link '<nixpkgs/nixos/modules/services/<category>/<service>.nix>')'
```

#### Method 4: Use `nix repl` for Interactive Discovery
```bash
nix repl '<nixpkgs/nixos>'
:a { config, pkgs, ... }
:p options.services.<service>
```

#### Method 5: Check Home Manager Options
```bash
# For home-manager configurations
nix-shell -p home-manager --run 'man home-configuration.nix'

# Or browse online
# https://nix-community.github.io/home-manager/options.html
```

#### Method 6: Use `nix-option-search` (Recommended)
```bash
# Search all available options
nix-shell -p manix --run 'manix <search-term>'

# Or use nix search for flake inputs
nix search nixpkgs <package-name>
```

### 4. Working with This Configuration

#### Building Configurations
```bash
# Build a specific host configuration
nixos-rebuild build --flake .#leo

# Build and switch (requires sudo)
sudo nixos-rebuild switch --flake .#<hostname>

# Test configuration without switching boot
sudo nixos-rebuild test --flake .#<hostname>
```

#### Updating Dependencies
```bash
# Update all flake inputs
nix flake update

# Update specific input
nix flake lock --update-input <input-name>

# Example: Update nixpkgs only
nix flake lock --update-input nixpkgs
```

#### Evaluating Flake Outputs
```bash
# Show all flake outputs
nix flake show

# Evaluate specific output
nix eval .#nixosConfigurations.leo.config.system.stateVersion

# Check what will be built
nix flake check
```

#### Working with Modules

**NixOS Modules** (from `modules/nixos/`):
- Available as `self.nixosModules.*` in other flakes
- Automatically discovered from `modules/nixos/` directory
- Include in host configs with `imports = [ ]`
- Example from `hosts/leo/configuration.nix:9-21`:
  ```nix
  imports = with nix-config.nixosModules; [
    system
    shell
    desktop
    # ... more modules
  ];
  ```

**Home Manager Modules** (from `home/`):
- Available as `self.homeModules.*`
- Automatically discovered from `home/` directory
- Loaded via `home-manager.sharedModules` in host configs
- Example from `hosts/leo/configuration.nix:23`:
  ```nix
  home-manager.sharedModules = attrValues nix-config.homeModules;
  ```
- All modules in `home/` are automatically loaded for all users

**Critical: Home Manager Module Structure**

Since `useGlobalPkgs = false`, home modules have their own nixpkgs instance:
```nix
# home/<module>.nix
{ config, pkgs, lib, inputs, ... }:
{
  # Overlays defined here affect THIS home-manager user
  nixpkgs.overlays = [ /* ... */ ];
  
  # Packages from this pkgs instance
  home.packages = with pkgs; [ ... ];
  
  # Program configurations
  programs.git = { ... };
}
```

**Inspecting Module Structure:**
```bash
# List available nixosModules
nix eval .#nixosModules --apply builtins.attrNames

# List available homeModules  
nix eval .#homeModules --apply builtins.attrNames

# Check if overlay is being applied in Home Manager
nix eval .#nixosConfigurations.leo.config.home-manager.users.juicy.nixpkgs.overlays --apply "builtins.length"
```

### 5. Adding Overlays - Step by Step

Given the current configuration (`useGlobalPkgs = false`), follow these steps:

#### For Home Manager Packages (User Environment)

1. **Create or edit a home module** in `home/overlays.nix`:
   ```nix
   { inputs, ... }:
   {
     nixpkgs.overlays = [
       # From flake input
       inputs.some-package.overlays.default
       
       # Custom overlay
       (final: prev: {
         myPackage = prev.myPackage.override {
           enableFeature = true;
         };
       })
     ];
   }
   ```

2. **Module is auto-loaded** via `home-manager.sharedModules = attrValues nix-config.homeModules`

3. **Verify overlay is applied**:
   ```bash
   # Rebuild and check
   sudo nixos-rebuild switch --flake .#leo
   
   # Verify in nix repl
   nix repl
   :lf .
   :p nixosConfigurations.leo.config.home-manager.users.juicy.home.packages
   ```

#### For System Packages (Services, systemPackages)

1. **Add to system configuration** (e.g., `modules/nixos/system.nix` or host config):
   ```nix
   { inputs, ... }:
   {
     nixpkgs.overlays = [
       (final: prev: {
         customService = prev.package.override { ... };
       })
     ];
     
     environment.systemPackages = [ pkgs.customService ];
   }
   ```

2. **Remember**: System overlays DON'T affect Home Manager packages when `useGlobalPkgs = false`

#### Adding a Flake Input for Overlays

1. **Add to `flake.nix` inputs**:
   ```nix
   inputs = {
     # ... existing inputs
     new-package = {
       url = "github:user/repo";
       inputs.nixpkgs.follows = "nixpkgs";
     };
   };
   ```

2. **Pass to modules** - already configured via `specialArgs` in `mkNixosHost`:
   ```nix
   specialArgs = {
     inherit inputs;
     nix-config = self;
   };
   ```

3. **Update lock file**:
   ```bash
   nix flake lock --update-input new-package
   ```

4. **Use in home or system modules** as shown above

### 6. Common Workflows

#### Adding a New Service
1. Check if service exists in nixpkgs:
   ```bash
   nix-shell -p manix --run 'manix services.<service-name>'
   ```

2. Create a module in `modules/nixos/<service-name>.nix`:
   ```nix
   { config, pkgs, lib, ... }:
   
   with lib;
   
   {
     options.services.<service-name> = {
       enable = mkEnableOption "<service-name>";
       # Add custom options here
     };
     
     config = mkIf config.services.<service-name>.enable {
       # Service configuration
     };
   }
   ```

3. Import in host configuration:
   ```nix
   imports = [ ../../modules/nixos/<service-name>.nix ];
   ```

#### Adding a New Package
1. Create package definition in `packages/<name>/default.nix`
2. Package will be auto-discovered by `packagesFromDirectoryRecursive` (see `flake.nix:94-98`)
3. Build with: `nix build .#<package-name>`

#### Working with Secrets (agenix)
```bash
# Edit a secret
nix-shell -p agenix --run 'agenix -e secrets/<secret-name>.age'

# Rekey secrets after adding new keys
nix-shell -p agenix --run 'agenix -r'
```

### 7. Package Installation Best Practices

#### System vs User Packages

**System Packages** (via `environment.systemPackages`):
- Available to all users
- Requires root to rebuild
- Used for system services, daemons, system tools
- Example from `modules/nixos/system.nix:64-70`:
  ```nix
  environment.systemPackages = with pkgs;
    optionals (hasRole "keyboard-zsa") [ keymapp kontroll ]
    ++ [ agenix ]
    ++ optional (hasRole "peon-ping") nix-config.packages.${pkgs.stdenv.hostPlatform.system}.peon-ping;
  ```

**User Packages** (via Home Manager):
- Per-user installation
- User can rebuild with `home-manager switch`
- Preferred for user applications and tools
- Example in any `home/*.nix` module:
  ```nix
  home.packages = with pkgs; [
    firefox
    git
    neovim
  ];
  ```

#### When to Use Each

| Use System Packages | Use Home Manager Packages |
|-------------------|--------------------------|
| System services (nginx, postgresql) | User applications (browsers, editors) |
| System tools (parted, mkfs) | Development tools (gcc, nodejs) |
| Daemons and background services | CLI utilities (ripgrep, fd, bat) |
| Hardware-specific tools | Desktop applications |
| Security tools (agenix) | Theme/customization packages |

#### Adding Packages from Flake Outputs

This configuration exposes packages from `packages/` directory:
```nix
# In flake.nix:92-105
packages = forAllSystems (pkgs: let
  rawPackages = packagesFromDirectoryRecursive {
    inherit (pkgs) callPackage;
    directory = ./packages;
  };
in rawPackages // {
  peon-ping = rawPackages.peon-ping.default;
  default = rawPackages.peon-ping.default;
});
```

**Usage in host config** (from `hosts/fallarbor/configuration.nix:23-25`):
```nix
environment.systemPackages = lib.optionals (nix-config ? packages) (
  attrValues nix-config.packages.${pkgs.stdenv.hostPlatform.system}
);
```

**Build and test custom package**:
```bash
nix build .#peon-ping
./result/bin/peon-ping
```

### 8. Formatting and Checking

#### Format Code
```bash
# Format all Nix files with alejandra (configured as formatter)
nix fmt

# Or manually:
nix-shell -p alejandra --run 'alejandra .'
```

#### Run Checks
```bash
# Run all checks defined in flake
nix flake check

# Run specific check
nix build .#checks.x86_64-linux.format-check
```

### 9. Helper Functions and Utilities

From `flake.nix:50-90`, this configuration provides:

- `forAllSystems` - Apply function across supported systems (line 51-65)
- `nameOf` - Extract name from path (line 67-68)
- `modulesFrom` - Load modules from directory (line 70-73)
- `modulesFromRel` - Load modules from relative path (line 75-80)
- `mkNixosHost` - Create NixOS configuration for host (line 82-90)

### 10. Development Shell

When entering the development environment:
```bash
nix develop

# Or for a specific package environment
nix develop .#<package-name>
```

The default dev shell runs `fastfetch` on entry (see `flake.nix:109-111`).

## Quick Reference Commands

### Essential Commands

| Task | Command |
|------|---------|
| Build host config | `sudo nixos-rebuild build --flake .#<hostname>` |
| Switch to new config | `sudo nixos-rebuild switch --flake .#<hostname>` |
| Test config (no boot) | `sudo nixos-rebuild test --flake .#<hostname>` |
| Show flake outputs | `nix flake show` |
| Search for package | `nix search nixpkgs <term>` |
| Find option docs | `nix-shell -p manix --run 'manix <term>'` |
| Format code | `nix fmt` |
| Update flake | `nix flake update` |
| Update single input | `nix flake lock --update-input <input-name>` |
| Run checks | `nix flake check` |
| Build package | `nix build .#<package-name>` |
| Enter dev shell | `nix develop` |
| Run with package | `nix-shell -p <pkg> --run '<cmd>'` |

### Overlay Quick Reference

**Current config: `useGlobalPkgs = false`**

| I want to modify... | Define overlay in... | Example |
|-------------------|---------------------|---------|
| Home Manager package | `home/*.nix` module | `home/overlays.nix` |
| System package | System or `modules/nixos/*.nix` | `modules/nixos/system.nix` |
| Both (if useGlobalPkgs=true) | `home-manager.nixpkgs.overlays` in host | N/A (not current config) |

### Module Organization

| Type | Location | Loaded via | Example |
|------|----------|-----------|---------|
| NixOS module | `modules/nixos/` | Host config `imports` | `system.nix`, `desktop.nix` |
| Home module | `home/` | `home-manager.sharedModules` | `git.nix`, `neovim.nix` |
| Host config | `hosts/<name>/` | `nixosConfigurations` in flake | `leo/configuration.nix` |
| Package | `packages/` | Auto-discovered | `peon-ping/default.nix` |
| Library | `lib/` | Manual import | `services.nix`, `streamer-mode.nix` |

## Best Practices

1. **Always use nix-shell for one-off commands** - Don't assume tools are available globally
2. **Know your overlay scope** - Check `useGlobalPkgs` setting before adding overlays (currently `false`)
3. **System vs User packages** - System packages in `environment.systemPackages`, user packages in Home Manager
4. **Overlays for Home Manager** - With `useGlobalPkgs=false`, define in `home/*.nix` modules, NOT system config
5. **Check flake.nix first** - Understand the structure before making changes
6. **Follow the module pattern** - Use proper option definitions and config blocks
7. **Test before switching** - Use `nixos-rebuild test` to verify changes
8. **Keep modules focused** - One module per service/feature
9. **Document custom options** - Use `description` fields in option definitions
10. **Use `lib` functions** - Leverage `mkEnableOption`, `mkOption`, `mkIf`, etc.
11. **Respect the directory structure** - NixOS modules in `modules/nixos/`, home configs in `home/`
12. **Lock dependencies** - Commit `flake.lock` changes
13. **Run checks before commits** - Ensure `nix flake check` passes
14. **One rebuild scope at a time** - Don't mix system and home-manager concerns in the same change

## Configuration Layers (Bottom to Top)

Understanding the layer structure is critical for proper configuration:

1. **Base nixpkgs** - The upstream Nixpkgs package set

2. **System configuration layer** (`modules/nixos/`, host configs)
   - System-wide services (nginx, postgresql, etc.)
   - System packages (`environment.systemPackages`)
   - System overlays (when `useGlobalPkgs=false`, these DON'T affect Home Manager)
   - Applied to: systemd services, system binaries, root environment

3. **Home Manager layer** (`home/` modules)
   - **Separate pkgs instance** (because `useGlobalPkgs=false`)
   - User packages (`home.packages`)
   - User program configs (`programs.*`, `services.*`)
   - Home Manager overlays defined here ONLY affect user packages
   - Applied to: user environment, user services, dotfiles

**Key Insight**: With `useGlobalPkgs = false`, these are **two separate package universes**. An overlay in one does NOT affect the other.

## Troubleshooting

### Build Failures
```bash
# Verbose build output
nixos-rebuild build --flake .#<hostname> --show-trace

# Check for evaluation errors
nix eval .#nixosConfigurations.<hostname>.config.system.build.toplevel --show-trace
```

### Finding Why Something Is Included
```bash
# Show dependency graph
nix why-depends /run/current-system <package>

# Show closure size
nix path-info -Sh .#nixosConfigurations.<hostname>.config.system.build.toplevel
```

### Debugging Modules
```bash
# Evaluate specific option
nix eval .#nixosConfigurations.<hostname>.config.services.<service>.enable

# Show all services
nix eval .#nixosConfigurations.<hostname>.config.services --apply builtins.attrNames
```

### Overlay Not Working - Debugging Checklist

**Problem: Package modifications not appearing after rebuild**

1. **Check useGlobalPkgs setting**:
   ```bash
   nix eval .#nixosConfigurations.leo.config.home-manager.useGlobalPkgs
   # Should return: false
   ```

2. **Verify overlay location based on package type**:
   - For Home Manager packages → Check `home/*.nix` modules
   - For system packages → Check system config or `modules/nixos/*.nix`

3. **Confirm overlay is being loaded**:
   ```bash
   # For Home Manager
   nix eval .#nixosConfigurations.leo.config.home-manager.users.juicy.nixpkgs.overlays --apply "builtins.length"
   
   # For system
   nix eval .#nixosConfigurations.leo.config.nixpkgs.overlays --apply "builtins.length"
   ```

4. **Test overlay in nix repl**:
   ```bash
   nix repl
   :lf .
   pkgs = nixosConfigurations.leo.config.home-manager.users.juicy.home.sessionVariables.NIX_PATH
   # Or for system pkgs:
   pkgs = nixosConfigurations.leo.pkgs
   :p pkgs.yourPackage
   ```

5. **Check if package is in correct scope**:
   ```bash
   # Is it a Home Manager package?
   nix eval .#nixosConfigurations.leo.config.home-manager.users.juicy.home.packages --apply "map (p: p.pname)"
   
   # Or a system package?
   nix eval .#nixosConfigurations.leo.config.environment.systemPackages --apply "map (p: p.pname)"
   ```

### Common Error Messages and Solutions

| Error | Likely Cause | Solution |
|-------|--------------|----------|
| "attribute 'package' missing" | Overlay not in correct scope | Move overlay to home config (for user pkg) or system config (for system pkg) |
| "infinite recursion" | Overlay references itself incorrectly | Use `final` for new derivations, `prev` for existing ones |
| "Package works in repl but not installed" | Overlay in wrong pkgs instance | Check useGlobalPkgs and move overlay accordingly |
| "Changes don't apply after rebuild" | Overlay not loaded by any module | Ensure overlay is in an imported module |
| "collision between package versions" | Overlay defined in multiple places | Remove duplicate overlay definitions |

### When Configuration Changes Don't Apply

1. **Did you rebuild?**
   ```bash
   sudo nixos-rebuild switch --flake .#leo
   ```

2. **Is the module imported?**
   - Check `imports = [ ... ]` in host config
   - Check `home-manager.sharedModules` includes your home module

3. **Are you editing the right file?**
   - System config: `modules/nixos/` or `hosts/<hostname>/`
   - Home config: `home/` directory
   - Verify with: `nix-shell -p ripgrep --run 'rg "your-option" -l'`

4. **Clear evaluation cache**:
   ```bash
   nix eval --no-eval-cache .#nixosConfigurations.leo.config.system.build.toplevel
   ```

5. **Check syntax errors**:
   ```bash
   nix flake check
   nix eval .#nixosConfigurations.leo.config --show-trace
   ```

## Decision Trees

### Should I Add This as a System or Home Manager Package?

```
Is it a system service or daemon?
├─ YES → System package (environment.systemPackages)
│         Example: nginx, postgresql, systemd services
│
└─ NO → Is it needed by multiple users?
        ├─ YES → System package (environment.systemPackages)
        │         Example: shared development tools, system utilities
        │
        └─ NO → Is it user-specific or a GUI application?
                └─ YES → Home Manager package (home.packages)
                          Example: browsers, editors, user CLI tools
```

### Where Do I Add This Overlay?

```
Current config: useGlobalPkgs = false

What package are you modifying?
├─ System package (in environment.systemPackages or used by services)
│   └─ Add overlay to system config
│       Location: modules/nixos/*.nix or hosts/<hostname>/configuration.nix
│       Example: nixpkgs.overlays = [ (final: prev: { ... }) ];
│
└─ Home Manager package (in home.packages or user programs)
    └─ Add overlay to home module
        Location: home/overlays.nix (create if needed)
        Example: nixpkgs.overlays = [ (final: prev: { ... }) ];
        
Note: If useGlobalPkgs were true (it's not), overlays would go in:
      home-manager.nixpkgs.overlays in the host config
```

### Where Do I Add This Configuration?

```
What are you configuring?

├─ NixOS system service (services.*, networking.*, boot.*, etc.)
│   └─ Location: modules/nixos/<service-name>.nix
│       OR hosts/<hostname>/configuration.nix
│       Pattern: Use options.modules.* for custom options
│       
├─ User program (programs.git, programs.tmux, etc.)
│   └─ Location: home/<program-name>.nix
│       Pattern: Use programs.* or home.file for configs
│       
├─ User-specific system config
│   └─ Location: modules/nixos/system.nix (home-manager.users.<username>)
│       Example: User groups, home directory
│       
└─ Host-specific anything
    └─ Location: hosts/<hostname>/configuration.nix
        Example: Hardware, filesystems, host-specific services
```

## Workflows

### Workflow: Adding a New Package from a Flake Input

1. **Add input to `flake.nix`**:
   ```nix
   inputs = {
     # ... existing inputs
     my-package = {
       url = "github:user/my-package";
       inputs.nixpkgs.follows = "nixpkgs";
     };
   };
   ```

2. **Update flake lock**:
   ```bash
   nix flake lock --update-input my-package
   ```

3. **For Home Manager package**, create `home/my-package.nix`:
   ```nix
   { inputs, pkgs, ... }:
   {
     nixpkgs.overlays = [ inputs.my-package.overlays.default ];
     home.packages = [ pkgs.my-package ];
   }
   ```

4. **For system package**, add to host config or system module:
   ```nix
   { inputs, pkgs, ... }:
   {
     nixpkgs.overlays = [ inputs.my-package.overlays.default ];
     environment.systemPackages = [ pkgs.my-package ];
   }
   ```

5. **Rebuild**:
   ```bash
   sudo nixos-rebuild switch --flake .#leo
   ```

### Workflow: Creating a Custom NixOS Service Module

1. **Create module file** `modules/nixos/my-service.nix`:
   ```nix
   { config, pkgs, lib, ... }:
   
   with lib;
   
   let
     cfg = config.modules.my-service;
   in {
     options.modules.my-service = {
       enable = mkEnableOption "my-service";
       port = mkOption {
         type = types.port;
         default = 8080;
         description = "Port to listen on";
       };
     };
     
     config = mkIf cfg.enable {
       systemd.services.my-service = {
         description = "My Service";
         wantedBy = [ "multi-user.target" ];
         serviceConfig = {
           ExecStart = "${pkgs.my-service}/bin/my-service --port ${toString cfg.port}";
           Restart = "always";
         };
       };
       
       networking.firewall.allowedTCPPorts = [ cfg.port ];
     };
   }
   ```

2. **Import in host config** `hosts/leo/configuration.nix`:
   ```nix
   imports = with nix-config.nixosModules; [
     # ... existing modules
     my-service
   ];
   
   modules.my-service = {
     enable = true;
     port = 9000;
   };
   ```

3. **Test**:
   ```bash
   sudo nixos-rebuild test --flake .#leo
   systemctl status my-service
   ```

### Workflow: Debugging "Package Not Found" Errors

1. **Identify package source**:
   - Is it from nixpkgs? `nix search nixpkgs <package>`
   - Is it from a flake input? Check `flake.nix` inputs
   - Is it a custom package? Check `packages/` directory

2. **Check overlay scope**:
   ```bash
   # For Home Manager package
   nix-shell -p ripgrep --run 'rg "nixpkgs.overlays" home/'
   
   # For system package
   nix-shell -p ripgrep --run 'rg "nixpkgs.overlays" modules/nixos/'
   ```

3. **Verify in nix repl**:
   ```bash
   nix repl
   :lf .
   # For Home Manager
   :p nixosConfigurations.leo.config.home-manager.users.juicy.home.packages
   # For system
   :p nixosConfigurations.leo.config.environment.systemPackages
   ```

4. **Check if overlay is needed**:
   - If package is in nixpkgs unstable: No overlay needed
   - If modified/overridden: Need overlay
   - If from flake input: Need overlay from input

5. **Add overlay in correct location** (see decision tree above)

6. **Rebuild and verify**:
   ```bash
   sudo nixos-rebuild switch --flake .#leo
   which <package-name>
   ```

## Summary - Critical Points

1. **`useGlobalPkgs = false`** means system and Home Manager have separate package sets
2. **Always use `nix-shell -p <pkg> --run '<cmd>'`** for tools not in environment
3. **Home Manager overlays** go in `home/*.nix` modules (current config)
4. **System overlays** go in `modules/nixos/*.nix` or host config
5. **All `home/` modules** are auto-loaded via `home-manager.sharedModules`
6. **NixOS modules** must be explicitly imported in host config
7. **Flake inputs** are already passed via `specialArgs`
8. **Test before switch** using `nixos-rebuild test`
9. **Run `nix flake check`** before committing
10. **Format with `nix fmt`** (alejandra) before committing

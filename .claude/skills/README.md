# Claude Code Skills for NixOS Configuration

This directory contains specialized skills that guide AI assistants in working with this NixOS configuration repository.

## Available Skills

### nixos-config-helper

**Purpose**: Comprehensive guide for NixOS flake-based configuration management

**Key Features**:
- Command execution patterns using `nix-shell -p <pkg> --run '<cmd>'`
- Flake structure awareness and navigation
- Configuration option discovery (6 different methods)
- Overlay management with `useGlobalPkgs = false` consideration
- Home Manager vs System package placement
- Module organization and loading patterns
- Common workflows and decision trees
- Comprehensive troubleshooting guides

**When to Use**:
- Adding new packages or services
- Working with overlays
- Debugging build or configuration issues
- Understanding the flake structure
- Making changes to NixOS or Home Manager configurations

**Critical Knowledge Areas**:
1. **Overlay Scope**: With `useGlobalPkgs = false`, system and Home Manager have separate package sets
2. **Command Pattern**: Always use `nix-shell -p <pkg> --run '<cmd>'` for tools
3. **Module Auto-loading**: Home modules auto-load via `sharedModules`, NixOS modules need explicit imports
4. **Configuration Layers**: System vs Home Manager separation

## Skill Format

Skills follow the standard format:
```markdown
---
name: skill-name
description: Brief description
license: MIT
metadata:
  author: Author Name
  version: "1.0.0"
---

# Skill Title

Content...
```

## Using Skills

Skills are automatically loaded by Claude Code and provide contextual guidance. The AI assistant will reference these skills when:
- Working with NixOS configurations
- Adding packages or overlays
- Troubleshooting build issues
- Navigating the repository structure

## Contributing

When adding new skills:

1. Follow the standard skill format with frontmatter
2. Include practical examples and code snippets
3. Reference actual file paths and line numbers from the repo
4. Provide decision trees and workflows for common tasks
5. Include troubleshooting sections with common errors
6. Keep content focused and actionable

## Repository Structure Reference

```
nixos-config/
├── .claude/
│   └── skills/              # This directory
│       ├── README.md        # This file
│       └── nixos-config-helper.md  # Main skill
├── flake.nix               # Flake configuration
├── flake.lock              # Locked dependencies
├── hosts/                  # Per-host configurations
│   ├── leo/
│   ├── fallarbor/
│   └── zues/
├── modules/
│   └── nixos/              # NixOS modules (explicit imports)
├── home/                   # Home Manager modules (auto-loaded)
├── packages/               # Custom packages (auto-discovered)
├── lib/                    # Helper functions
└── secrets/                # agenix encrypted secrets
```

## Key Configuration Settings

- **useGlobalPkgs**: `false` (from `modules/nixos/system.nix:187`)
- **Formatter**: `alejandra` (from `flake.nix:118`)
- **Hosts**: `leo`, `fallarbor`, `zues`
- **Default user**: `juicy`
- **Flake inputs**: nixpkgs, home-manager, emacs-overlay, agenix, stylix, hyprland, nixvim, caelestia-shell

## Quick Links

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Home Manager Options](https://nix-community.github.io/home-manager/options.html)
- [Nixpkgs Manual](https://nixos.org/manual/nixpkgs/stable/)
- [Nix Flakes](https://nixos.wiki/wiki/Flakes)

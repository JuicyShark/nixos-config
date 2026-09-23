# Submap cheatsheet

Vendored on 2026-09-13 from the local `submap-cheatsheet` project, including its
working-tree changes. Its HEAD was `2f2b0fbe584989e45cf1c7559bebb333834267b7`;
no remote was configured. The runtime files in `config/` are copied unchanged.

`default.nix` packages the overlay with this repository's pinned Quickshell.
`modules/home/hyprland.nix` owns the user service, monitor selection, and
Stylix-generated palette. Changes here are explicit snapshots; the original
checkout is no longer needed to evaluate or build this configuration.

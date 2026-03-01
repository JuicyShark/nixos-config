# nix-config

My [NixOS] configuration with [Nix Flakes], [Home Manager], [Stylix], [Agenix], and Wayland compositors like [Hyprland] and [Niri].

## Features

- Clean, readable code that can be easily modified to add/remove things as needed.
- Fully reproducible and declarative environment thanks to NixOS.
- Nix Flakes + Home Manager + Btrfs on LUKS.
- Simple yet effective Neovim setup with nvim-lspconfig.
- Modern Wayland support with Hyprland and Niri
- A universal color scheme inherited by all applications.

## Session selection

You can enable both Hyprland and Niri sessions with roles and pick one at login with greetd (auto-enabled when both are enabled):

```nix
modules.system.roles = [
  "desktop"
  "desktop-niri"
  # optional: "desktop-hyprland" (hyprland is enabled by default for desktop)
];

modules.desktop = {
  primaryMonitorName = "DP-2";
};
```



[NixOS]: https://nixos.org/
[Nix Flakes]: https://wiki.nixos.org/wiki/Flakes
[Agenix]: https://github.com/ryantm/agenix
[Home Manager]: https://nix-community.github.io/home-manager/
[Stylix]: https://danth.github.io/stylix/
[Hyprland]: https://hyprland.org/
[Niri]: https://github.com/YaLTeR/niri
[Caelestia-shell]: github.com/caelestia-dots/shell/

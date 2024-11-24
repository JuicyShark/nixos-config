{nix-config, ...}: {
  imports = with nix-config.nixosModules; [shell desktop system];

  home-manager.sharedModules = with nix-config.homeModules; [
    git
    style
    foot
    neovim
    xresources
    yazi
  ];

  nixpkgs.overlays = builtins.attrValues nix-config.overlays;

  modules.system.username = "juicy";

  environment = {
    variables = {TERM = "foot-direct";};

    sessionVariables = {
      WAYLAND_DISPLAY = "wayland-1";
      QT_QPA_PLATFORM = "wayland";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      SDL_VIDEODRIVER = "wayland";
      CLUTTER_BACKEND = "wayland";
      MOZ_ENABLE_WAYLAND = "1";
      XDG_RUNTIME_DIR = "/run/user/1000";
      DISPLAY = ":0";
      GLFW_IM_MODULE = "ibus";
    };
  };

  hardware.graphics.enable = true;
}

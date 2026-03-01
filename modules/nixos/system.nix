{
  nix-config,
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib.types) listOf nullOr str;
  inherit (config.boot) isContainer;
  inherit (nix-config.inputs.home-manager.nixosModules) home-manager;
  inherit (nix-config.inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}) agenix;
  inherit
    (lib)
    mkOption
    mkIf
    optional
    optionalAttrs
    optionals
    ;
  inherit (cfg) username hashedPasswordFile;

  cfg = config.modules.system;
  hasRole = role: builtins.elem role cfg.roles;
  mkStrOption = default:
    mkOption {
      type = str;
      inherit default;
    };
in {
  imports = [
    home-manager
    nix-config.inputs.agenix.nixosModules.default
  ];

  options.modules.system = {
    roles = mkOption {
      type = listOf str;
      default = [];
      description = "Global role/tag selectors used to enable opinionated defaults.";
    };
    username = mkStrOption "juicy";
    hashedPasswordFile = mkOption {
      type = nullOr str;
      default = null;
    };
    hostName = mkStrOption "nixos";
  };

  config = {
    age = {
      identityPaths = [
        "${config.users.users.${username}.home}/.ssh/id_rsa"
        "${config.users.users.${username}.home}/.ssh/id_ed25519"
        "/etc/ssh/ssh_host_ed25519_key"
      ];
      secrets = {
        wifi-pass.file = ../../secrets/wifi-pass.age;
        juicy-password.file = ../../secrets/juicy-password.age;
      };
    };

    environment = {
      defaultPackages = lib.mkForce [];
      systemPackages = with pkgs;
        optionals (hasRole "keyboard-zsa") [
          keymapp
          kontroll
        ]
        ++ [agenix]
        ++ optional (hasRole "peon-ping") nix-config.packages.${pkgs.stdenv.hostPlatform.system}.peon-ping;
      variables = {
        EDITOR = "nvim";
        VISUAL =
          if hasRole "desktop-emacs"
          then "emacs"
          else "nvim";
      };
    };
    boot = {
      initrd.systemd.emergencyAccess = true;
      tmp =
        if hasRole "ram-high"
        then {useTmpfs = true;}
        else {cleanOnBoot = true;};

      binfmt.emulatedSystems = mkIf (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
        "aarch64-linux"
      ];

      loader = mkIf (!isContainer) {
        systemd-boot = mkIf (pkgs.stdenv.hostPlatform.system != "aarch64-linux") {
          enable = true;
          editor = false;
          configurationLimit = 10;
        };

        timeout = 0;
        efi.canTouchEfiVariables = builtins.pathExists "/sys/firmware/efi";
      };

      kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_stable;
      blacklistedKernelModules = ["floppy"];
    };

    systemd = {
      settings.Manager.DefaultTimeoutStopSec = "10s";
      services.NetworkManager-wait-online.enable = false;
    };

    nixpkgs.config.allowUnfree = true;
    nix = {
      package = pkgs.nixVersions.latest;
      gc.automatic = true;
      optimise.automatic = true;
      settings = {
        substituters = [
          "https://cache.nixos.org/"
          "https://nix-community.cachix.org"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "max-deploy:3kPzEf0z7cR3xHAgh2bsS0lp9GZGWzEKsw/ZuQc1z60="
        ];
        auto-optimise-store = true;
        warn-dirty = false;
        allow-import-from-derivation = true;
        keep-going = true;

        experimental-features = [
          "nix-command"
          "flakes"
        ];
        trusted-users = [
          "root"
          "juicy"
          "@wheel"
        ];
      };
    };
    zramSwap = {
      enable = false;
      memoryPercent = 25;
    };

    time.timeZone = "Australia/Brisbane";

    i18n = {
      defaultLocale = "en_AU.UTF-8";
      supportedLocales = [
        "en_AU.UTF-8/UTF-8"
        "en_US.UTF-8/UTF-8"
      ];
    };

    system.stateVersion = "25.11";

    users = {
      mutableUsers = true;
      allowNoPasswordLogin = mkIf isContainer true;

      users.${username} =
        {
          isNormalUser = true;
          createHome = true;
          uid = 1000;

          extraGroups =
            if isContainer
            then []
            else [
              "wheel"
              "networkmanager"
              "dialout"
              "feedbackd"
              "video"
              "audio"
              "render"
              "input"
              "media"
            ];
        }
        // optionalAttrs (hashedPasswordFile != null) {inherit hashedPasswordFile;};
    };

    home-manager = {
      useGlobalPkgs = false;
      useUserPackages = true;

      sharedModules = [
        {
          home.stateVersion = "25.11";
          programs.man.generateCaches = true;
        }
      ];

      users.${username} = {
        home = {
          inherit username;
          homeDirectory = "/home/${username}";
        };
        nixpkgs.config.allowUnfree = true;
      };
    };

    networking = {
      inherit (cfg) hostName;
      useDHCP = lib.mkDefault true;
      enableIPv6 = lib.mkDefault true;
      domain = "local";

      networkmanager = mkIf (hasRole "desktop") {
        enable = true;
        wifi.macAddress = "random";
        unmanaged = ["interface-name:ve-*"];
      };

      firewall = {
        allowedUDPPorts =
          [
            67
            68
            60344
            24800
          ]
          ++ optionals (hasRole "allow-srb2-port") [5029];
        allowedTCPPorts = [] ++ optionals (hasRole "allow-dev-port") [3000];
      };
    };
    services = {
      resolved.settings.Resolve.LLMNR = "false";

      mullvad-vpn = mkIf (hasRole "mullvad") {
        enable = true;
        enableExcludeWrapper = false;
      };
      openssh = {
        enable = true;
        openFirewall = true;
        settings = {
          PubkeyAuthentication = true;
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitRootLogin = "no";
          X11Forwarding = false;
          UseDns = false;
        };
      };
    };

    programs = {
      command-not-found.enable = true;
      ssh.startAgent = false;
    };
    security.sudo.extraConfig = ''
      Defaults env_keep += "EDITOR VISUAL"
    '';
    security.pam.sshAgentAuth = {
      enable = true;
      authorizedKeysFiles = ["/etc/ssh/authorized_keys.d/%u"];
    };
    hardware.keyboard.zsa.enable = mkIf (hasRole "keyboard-zsa") true;
  };
}

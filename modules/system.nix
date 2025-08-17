{
  nix-config,
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib.types) nullOr str listOf;
  inherit (config.boot) isContainer;
  inherit (nix-config.inputs.home-manager.nixosModules) home-manager;
  inherit (nix-config.inputs.agenix.packages.${pkgs.system}) agenix;

  inherit (lib)
    mkOption
    mkEnableOption
    mkIf
    singleton
    optional
    ;

  inherit (cfg)
    username
    iHaveLotsOfRam
    hashedPassword
    mullvad
    nomad
    allowSRB2Port
    allowDevPort
    ;

  cfg = config.modules.system;
in
{
  imports = [
    home-manager
    nix-config.inputs.agenix.nixosModules.default
  ];

  options.modules.system = {
    username = mkOption {
      type = str;
      default = "juicy";
    };

    hashedPassword = mkOption {
      type = nullOr str;
      default = null;
    };

    timeZone = mkOption {
      type = str;
      default = "Australia/Brisbane";
    };

    defaultLocale = mkOption {
      type = str;
      default = "en_AU.UTF-8";
    };

    supportedLocales = mkOption {
      type = listOf str;

      default = [
        "en_AU.UTF-8/UTF-8"
        "en_US.UTF-8/UTF-8"
      ];
    };

    stateVersion = mkOption {
      type = str;
      default = "25.05";
    };

    hostName = mkOption {
      type = str;
      default = "nixos";
    };
    hostMonitoring = mkEnableOption "host device monitoring via glances";
    iHaveLotsOfRam = mkEnableOption "tmpfs on /tmp";
    mullvad = mkEnableOption "mullvad vpn";
    nomad = mkEnableOption "nomad hive";
    allowSRB2Port = mkEnableOption "port for srb2";
    allowDevPort = mkEnableOption "port for development server";
  };

  config = {

    age = {
      identityPaths = [
        "/home/${username}/.ssh/id_ed25519"
        "/etc/ssh/ssh_host_ed25519_key"
      ];
      secrets.wifi-pass.file = ../secrets/wifi-pass.age;
      secrets.deploy-key.file = ../secrets/deploy-key.age;
    };

    environment = {
      defaultPackages = lib.mkForce [ ];
      systemPackages = [ agenix ];
      variables = {
        EDITOR = "nvim";
        VISUAL = "emacs";
      };
    };
    boot = {
      tmp =
        if iHaveLotsOfRam then
          {
            useTmpfs = true;
          }
        else
          {
            cleanOnBoot = true;
          };

      #     binfmt.emulatedSystems = mkIf (pkgs.system == "x86_64-linux") [ "aarch64-linux" ];

      loader = mkIf (!isContainer) {
        systemd-boot = mkIf (pkgs.system != "aarch64-linux") {
          enable = true;
          editor = false;
          configurationLimit = 10;
        };

        timeout = 0;
        efi.canTouchEfiVariables = builtins.pathExists "/sys/firmware/efi";
      };

      kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_stable;
      blacklistedKernelModules = [ "floppy" ];
    };

    nixpkgs.config.allowUnfree = true;

    nix = {
      package = pkgs.nixVersions.latest;
      gc.automatic = true;
      optimise.automatic = true;
      settings = {
        secret-key-files = [ config.age.secrets.deploy-key.path ];
        trusted-public-keys = [
          "max-deploy:3kPzEf0z7cR3xHAgh2bsS0lp9GZGWzEKsw/ZuQc1z60="
        ];
        auto-optimise-store = true;
        warn-dirty = false;
        allow-import-from-derivation = false;
        keep-going = true;

        experimental-features = [
          "nix-command"
          "flakes"
        ];

        trusted-users = [
          "root"
          "@wheel"
        ];
      };
    };

    zramSwap = {
      enable = true;
      memoryPercent = 100;
    };

    time = { inherit (cfg) timeZone; };

    i18n = { inherit (cfg) defaultLocale supportedLocales; };

    system = { inherit (cfg) stateVersion; };

    users = {
      mutableUsers = false;
      allowNoPasswordLogin = mkIf isContainer true;

      users.${username} = {
        #inherit hashedPassword;
        password = "juicy";
        isNormalUser = true;
        uid = 1000;

        extraGroups =
          if isContainer then
            [ ]
          else
            [
              "wheel"
              "networkmanager"
              "dialout"
              "feedbackd"
              "video"
            ];
      };
    };

    home-manager = {
      #useGlobalPkgs = true;
      #useUserPackages = true;

      sharedModules = singleton {
        home = { inherit (cfg) stateVersion; };
        programs.man.generateCaches = true;
      };

      users.${username}.home = {
        inherit username;
        homeDirectory = "/home/${username}";
      };
    };

    networking = {
      inherit (cfg) hostName;
      useDHCP = lib.mkDefault true;
      defaultGateway.address = lib.mkDefault "192.168.1.1";
      nameservers = lib.mkDefault [
        "192.168.1.99"
      ];
      enableIPv6 = lib.mkDefault true;

      networkmanager = mkIf config.modules.desktop.enable {
        enable = true;
        wifi.macAddress = "random";

        unmanaged = [ "interface-name:ve-*" ];
        ensureProfiles.profiles.Packet_Sniffers_Anon = {
          connection = {
            id = "Packet_Sniffers_Anon";
            interface-name = "wlp6s0";
            type = "wifi";
            uuid = "1bbc8c9c-2caf-4706-aa9f-362f8879d04b";
          };
          ipv4 = {
            method = "auto";
          };
          ipv6 = {
            addr-gen-mode = "default";
            method = "auto";
          };
          proxy = { };
          wifi = {
            mode = "infrastructure";
            ssid = "Packet_Sniffers_Anon";
          };
          wifi-security = {
            auth-alg = "open";
            key-mgmt = "wpa-psk";
            psk = config.age.secrets.wifi-pass.path;
          };
        };
      };

      resolvconf.enable = false;

      firewall = {
        allowedUDPPorts = [
          67
          68
          60344
          24885
        ]
        ++ optional allowSRB2Port [ 5029 ];

        allowedTCPPorts = [
          2049
          4000
          4001
          4002
          4646 # Nomad HTTP
          4647 # Nomad RPC
          4648 # Nomad Serf LAN
          8500 # Consul HTTP
          8300 # Consul server RPC
          8301 # Consul Serf LAN
          8302 # Consul WAN (optional)
          #   4242 # lan-mouse
          24885
        ]
        ++ optional allowDevPort [ 3000 ];

      };
    };
    services = {
      resolved.llmnr = "false";
      logrotate.enable = true;

      mullvad-vpn = mkIf mullvad {
        enable = true;
        enableExcludeWrapper = false;
      };
      openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = true;
          KbdInteractiveAuthentication = false;
        };
      };
    };

    programs = {
      /*
        mosh = {
          enable = true;
          withUtempter = true;
        };
      */
      command-not-found.enable = false;
      ssh.startAgent = false;
    };

    security.pam.sshAgentAuth = {
      enable = true;
      authorizedKeysFiles = [
        "/etc/ssh/authorized_keys.d/%u"
      ];
    };
  };
}

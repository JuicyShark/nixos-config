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
      default = "24.05";
    };

    hostName = mkOption {
      type = str;
      default = "nixos";
    };

    iHaveLotsOfRam = mkEnableOption "tmpfs on /tmp";
    mullvad = mkEnableOption "mullvad vpn";
    allowSRB2Port = mkEnableOption "port for srb2";
    allowDevPort = mkEnableOption "port for development server";
  };

  config = {
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

      binfmt.emulatedSystems = mkIf (pkgs.system == "x86_64-linux") [ "aarch64-linux" ];

      loader = {
        systemd-boot = mkIf (pkgs.system != "aarch64-linux") {
          enable = true;
          editor = false;
          configurationLimit = 10;
        };

        timeout = 0;
        efi.canTouchEfiVariables = true;
      };

      kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_stable;
      blacklistedKernelModules = [ "floppy" ];
    };

    systemd = {
      extraConfig = "DefaultTimeoutStopSec=10s";
      services.NetworkManager-wait-online.enable = false;
    };
    nixpkgs.config.allowUnfree = true;
    #nixpkgs.config.allowUnsupportedSystem = true;
    nix = {
      package = pkgs.nixVersions.latest;
      gc.automatic = true;
      optimise.automatic = true;
      settings = {
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
        password = "juicy"; # config.age.secrets.juicy-password.path;

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
      # useGlobalPkgs = true;
      #useUserPackages = true;

      sharedModules = singleton {
        home = { inherit (cfg) stateVersion; };
        #programs.man.generateCaches = true;
      };

      users.${username}.home = {
        inherit username;
        homeDirectory = "/home/${username}";
      };
    };

    networking = {
      inherit (cfg) hostName;
      useDHCP = lib.mkForce true;
      /*
          defaultGateway = lib.mkForce "192.168.1.99";
        nameservers = lib.mkForce ["1.1.1.1" "8.8.8.8"];

        interfaces.enp5s0.ipv4.addresses = [
          {
            address = "192.168.1.54";
            prefixLength = 24;
          }
        ];
      */
      enableIPv6 = lib.mkDefault true;

      networkmanager = {
        enable = lib.mkDefault true;
        wifi.macAddress = "random";
        #ethernet.macAddress = "random";

        unmanaged = [ "interface-name:ve-*" ];
        #useDHCP = true;
      };

      #resolvconf.enable = mkIf mullvad false;

      nat = mkIf mullvad {
        enable = true;
        internalInterfaces = lib.mkDefault [ "ve-+" ];
        externalInterface = lib.mkDefault "wg0-mullvad";
      };

      firewall = {
        allowedUDPPorts = [
          67
          68
        ] ++ optional allowSRB2Port [ 5029 ];
        allowedTCPPorts = mkIf allowDevPort [ 3000 ];
      };
      /*
          wireguard.interfaces.wg0-mullvad = mkIf mullvad {
            privateKey = "OB8oklFPX+ZHnTLj09l058y8HY4Xg/z57m1Idut4vkM=";
            ips = [
              "10.73.64.1/32"
              "fc00:bbbb:bbbb:bb01::a:4000/128"
            ];
            peers = [
              # Leo
              {
                publicKey = "1H/gj8SVNebAIEGlvMeUVC5Rnf274dfVKbyE+v5G8HA=";
                allowedIPs = ["0.0.0.0/0""::0/0"];
                endpoint = "[2404:f780:4:deb::f001]:51820";
              }
              # Dante
              {
                publicKey = "6vgsf3fnpiMELuHKOV4IXkufW34lzTaJGTC1BMcu/FY=";
                allowedIPs = ["192.168.54.60"];
                #endpiont = "192.168.54.60/0";
              }
            ];
        };
      */
    };

    services = {
      resolved.llmnr = "false";

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
    programs.command-not-found.enable = false;

    programs.ssh.startAgent = false;

    security.pam.services."greetd".gnupg.enable = true;
    security.pam.sshAgentAuth = {
      enable = true;
      authorizedKeysFiles = [
        "/etc/ssh/authorized_keys.d/%u"
      ];
    };
  };
}

{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}: let
  cfg = osConfig.modules;
  serverHost = cfg.network.hosts.imac-machop or "192.168.1.52";
  serverPort = cfg.ports.barrier or 24800;
  profilePath = "${config.xdg.configHome}/Deskflow/profiles/imac-machop.conf";
  barrierMac = pkgs.writeShellScriptBin "barrier-mac" ''
    exec ${pkgs.deskflow}/bin/deskflow --settings "${profilePath}"
  '';
in
  lib.mkIf pkgs.stdenv.isLinux {
    home.packages = [
      pkgs.deskflow
      barrierMac
    ];

    xdg.configFile."Deskflow/profiles/imac-machop.conf".text = ''
      [client]
      remoteHost=${serverHost}

      [core]
      coreMode=1
      port=${toString serverPort}
      screenName=${osConfig.networking.hostName}
      startedBefore=true

      [gui]
      enableUpdateCheck=false
    '';

    xdg.desktopEntries.barrier-mac = {
      name = "Barrier Mac";
      comment = "Connect keyboard and mouse sharing to ${serverHost}";
      exec = "barrier-mac";
      terminal = false;
      type = "Application";
      categories = [
        "Utility"
        "Network"
      ];
      settings.Keywords = "barrier;deskflow;keyboard;mouse;";
    };
  }

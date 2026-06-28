{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.modules.minecraft.server;

  user = "minecraft";
  userId = 503;
  serviceHome = "/var/${user}";
  dataDir = "${serviceHome}/data";
  logDir = "${serviceHome}/logs";
  launchdLog = "${logDir}/launchd.log";
  stableStartLazymc = "/Library/PrivilegedHelperTools/org.nixos.lazymc.start";

  jvmOpts = "-Xms1G -Xmx12G";
  rconPort = 25575;
  rconPasswordFile = config.age.secrets.minecraft-rcon-password.path;

  serverProperties = {
    "server-ip" = "127.0.0.1";
    "server-port" = 25566;
    "enable-query" = false;
    "enforce-whitelist" = false;
    "white-list" = false;
    difficulty = "normal";
    gamemode = "survival";
    hardcore = false;
    "max-players" = 6;
    motd = "You Only Live Once, So Go Fucking Nuts";
    "pause-when-empty-seconds" = 0;
    "simulation-distance" = 20;
    "view-distance" = 32;
    "online-mode" = true;
    "prevent-proxy-connections" = true;
    "spawn-protection" = 0;
  };

  effectiveServerProperties =
    lib.removeAttrs serverProperties [
      "enable-rcon"
      "rcon.password"
      "rcon.port"
    ]
    // {
      "enable-rcon" = true;
      "rcon.port" = rconPort;
    };

  cfgToString = value:
    if builtins.isBool value
    then lib.boolToString value
    else toString value;

  eulaFile = pkgs.writeText "minecraft-eula.txt" ''
    eula=true
  '';

  serverPropertiesFile = pkgs.writeText "minecraft-server.properties" (
    ''
      # server.properties managed by nix-darwin configuration
    ''
    + lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: value: "${name}=${cfgToString value}") effectiveServerProperties
    )
  );

  lazymcConfigTemplate = (pkgs.formats.toml {}).generate "lazymc.toml" {
    public.address = "192.168.1.52:25565";

    server = {
      address = "127.0.0.1:${toString serverProperties.server-port}";
      directory = dataDir;
      command = "${pkgs.minecraft-server}/bin/minecraft-server ${jvmOpts}";
      freeze_process = false;
      wake_on_start = false;
      wake_on_crash = false;
      start_timeout = 300;
      stop_timeout = 150;
    };

    rcon = {
      enabled = true;
      port = rconPort;
      password = "__RCON_PASSWORD__";
      randomize_password = false;
    };

    time = {
      sleep_after = 300;
      minimum_online_time = 60;
    };

    motd = {
      sleeping = "${toString serverProperties.motd}\nJoin to start it up";
      starting = "Server is starting...\nPlease reconnect shortly";
      stopping = "Server is going to sleep...\nPlease wait";
      from_server = false;
    };

    join = {
      methods = [
        "hold"
        "kick"
      ];
      hold.timeout = 25;
      kick.starting = "Server is starting. Please reconnect in a minute.";
      kick.stopping = "Server is going to sleep. Please reconnect in a minute.";
    };

    advanced.rewrite_server_properties = false;
    config.version = "0.2.11";
  };

  writeMinecraftConfig = pkgs.writeText "write-minecraft-config.py" ''
    import json
    import pathlib
    import sys

    server_properties_template, lazymc_template, secret_path, data_dir = sys.argv[1:]
    data_dir = pathlib.Path(data_dir)
    rcon_password = pathlib.Path(secret_path).read_text().replace("\r", "").replace("\n", "")

    server_properties = pathlib.Path(server_properties_template).read_text()
    (data_dir / "server.properties").write_text(
        server_properties + f"\nrcon.password={rcon_password}\n"
    )

    lazymc = pathlib.Path(lazymc_template).read_text()
    (data_dir / "lazymc.toml").write_text(
        lazymc.replace('"__RCON_PASSWORD__"', json.dumps(rcon_password))
    )
  '';

  startLazymc = pkgs.writeShellScript "start-lazymc" ''
    set -eu

    ${pkgs.coreutils}/bin/install -d -m 0700 ${lib.escapeShellArg dataDir}
    ${pkgs.coreutils}/bin/install -m 0644 ${eulaFile} ${lib.escapeShellArg dataDir}/eula.txt

    ${pkgs.python3}/bin/python3 ${writeMinecraftConfig} ${serverPropertiesFile} ${lazymcConfigTemplate} ${lib.escapeShellArg rconPasswordFile} ${lib.escapeShellArg dataDir}
    ${pkgs.coreutils}/bin/chmod 0600 ${lib.escapeShellArg dataDir}/server.properties ${lib.escapeShellArg dataDir}/lazymc.toml

    exec ${pkgs.lazymc}/bin/lazymc --config ${lib.escapeShellArg dataDir}/lazymc.toml start
  '';
in {
  options.modules.minecraft.server = {
    enable = mkEnableOption "hibernating vanilla Minecraft server for darwin";
  };

  config = mkIf cfg.enable {
    age.secrets.minecraft-rcon-password = {
      file = ../../secrets/minecraft-rcon-password.age;
      owner = user;
      mode = "0400";
    };

    users = {
      knownGroups = [user];
      knownUsers = [user];

      groups.${user} = {
        gid = userId;
        description = "Minecraft service";
        members = [user];
      };

      users.${user} = {
        uid = userId;
        gid = userId;
        description = "Minecraft service";
        home = serviceHome;
        createHome = false;
        isHidden = true;
      };
    };

    # `etc` runs after nix-darwin creates managed users and before launchd reloads.
    system.activationScripts.etc.text = lib.mkAfter ''
      echo "securing Minecraft service home..." >&2
      ${pkgs.coreutils}/bin/install -d -m 0700 -o ${lib.escapeShellArg user} -g ${lib.escapeShellArg user} ${lib.escapeShellArg serviceHome}
      ${pkgs.coreutils}/bin/install -d -m 0700 -o ${lib.escapeShellArg user} -g ${lib.escapeShellArg user} ${lib.escapeShellArg dataDir}
      ${pkgs.coreutils}/bin/install -d -m 0700 -o ${lib.escapeShellArg user} -g ${lib.escapeShellArg user} ${lib.escapeShellArg logDir}
      /usr/bin/install -d -o root -g wheel -m 0755 /Library/PrivilegedHelperTools
      /usr/bin/install -o root -g wheel -m 0755 ${lib.escapeShellArg startLazymc} ${lib.escapeShellArg stableStartLazymc}
      /usr/bin/touch ${lib.escapeShellArg launchdLog}
      /usr/sbin/chown ${lib.escapeShellArg user}:${lib.escapeShellArg user} ${lib.escapeShellArg launchdLog}
      /bin/chmod 0644 ${lib.escapeShellArg launchdLog}
    '';

    launchd.daemons.lazymc = {
      serviceConfig = {
        ProgramArguments = [stableStartLazymc];
        KeepAlive = true;
        RunAtLoad = true;
        UserName = user;
        GroupName = user;
        EnvironmentVariables.HOME = serviceHome;
        StandardOutPath = launchdLog;
        StandardErrorPath = launchdLog;
        ThrottleInterval = 30;
      };
    };
  };
}

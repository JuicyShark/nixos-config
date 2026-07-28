{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption;
  inherit (lib.types) enum;

  cfg = config.modules.minecraft.server;

  user = "minecraft";
  userId = 503;
  loginUser = config.modules.profile.username;
  serviceHome = "/var/${user}";
  isSkyFactory5 = cfg.pack == "skyfactory5";
  levelName =
    if isSkyFactory5
    then "world"
    else "world";
  dataDir =
    if isSkyFactory5
    then "${serviceHome}/skyfactory5"
    else "${serviceHome}/data";
  logDir = "${serviceHome}/logs";
  launchdLog = "${logDir}/launchd.log";
  stableStartLazymc = "/Library/PrivilegedHelperTools/org.nixos.lazymc.start";

  javaPackage =
    if isSkyFactory5
    then pkgs.jdk17_headless
    else pkgs.jdk25_headless;
  jvmOpts = "-Xms1G -Xmx12G";
  serverPort = 25566;
  serverAddress = "127.0.0.1:${toString serverPort}";
  rconPort = 25575;
  rconPasswordFile = config.age.secrets.minecraft-rcon-password.path;
  serverProperties = {
    "level-name" = levelName;
    "level-type" =
      if isSkyFactory5
      then "minecraft\\:normal"
      else "default";
    "generator-settings" =
      if isSkyFactory5
      then "{}"
      else "";
    "enable-query" = false;
    "enforce-whitelist" = false;
    "white-list" = false;
    difficulty = "normal";
    gamemode = "survival";
    hardcore = false;
    "max-players" = 6;
    motd = "I am Steve and im diggin a hole, diggy diggy hole";
    "pause-when-empty-seconds" = 0;
    "simulation-distance" = 20;
    "view-distance" = 32;
    "online-mode" = true;
    "prevent-proxy-connections" = true;
    "spawn-protection" = 0;
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
      # server.properties seed managed by nix-darwin configuration
      # LazyMC rewrites proxy, status, query, and RCON settings at start.
    ''
    + lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: value: "${name}=${cfgToString value}") serverProperties
    )
  );

  syncSkyFactoryPack = pkgs.writeShellScript "sync-skyfactory5-pack" ''
    set -eu

    pack=${lib.escapeShellArg pkgs.skyfactory5-server-pack}
    target=${lib.escapeShellArg dataDir}

    ${pkgs.coreutils}/bin/install -d -m 0750 "$target"
    ${pkgs.coreutils}/bin/chmod -R u+rwX "$target"

    # Keep world state mutable and persistent; refresh pack-owned files only.
    for entry in "$pack"/* "$pack"/.[!.]* "$pack"/..?*; do
      [ -e "$entry" ] || continue
      name="$(${pkgs.coreutils}/bin/basename "$entry")"

      case "$name" in
        world|eula.txt|server.properties|lazymc.toml|logs)
          continue
          ;;
      esac

      ${pkgs.coreutils}/bin/rm -rf "$target/$name"
      ${pkgs.coreutils}/bin/cp -R "$entry" "$target/$name"
    done

    ${pkgs.coreutils}/bin/chmod -R u+rwX,g+rX "$target"

    if [ -f "$target/ServerStart.sh" ]; then
      ${pkgs.coreutils}/bin/chmod +x "$target/ServerStart.sh"
    fi
    if [ -f "$target/run.sh" ]; then
      ${pkgs.coreutils}/bin/chmod +x "$target/run.sh"
    fi
    if [ -f "$target/Install.sh" ]; then
      ${pkgs.coreutils}/bin/chmod +x "$target/Install.sh"
    fi
    if [ -f "$target/settings.sh" ]; then
      ${pkgs.gnused}/bin/sed -i \
        -e 's|^export MIN_RAM=.*|export MIN_RAM="1024M"|' \
        -e 's|^MAX_RAM=.*|MAX_RAM=8192M|' \
        -e 's|^export MAX_RAM=.*|export MAX_RAM="8192M"|' \
        "$target/settings.sh"
    fi
    if [ -f "$target/user_jvm_args.txt" ]; then
      ${pkgs.coreutils}/bin/printf '%s\n' '-Xms1G' '-Xmx12G' > "$target/user_jvm_args.txt"
    fi
  '';

  skyFactoryCommand = pkgs.writeShellScript "start-skyfactory5-server" ''
    set -eu

    export JAVA_HOME=${lib.escapeShellArg javaPackage}
    export PATH=${
      lib.makeBinPath [
        javaPackage
        pkgs.coreutils
        pkgs.gnused
        pkgs.gnugrep
        pkgs.gawk
        pkgs.bash
      ]
    }:/usr/bin:/bin

    cd ${lib.escapeShellArg dataDir}

    if [ ! -x ./run.sh ] && [ -x ./Install.sh ]; then
      ${pkgs.bash}/bin/bash ./Install.sh
    fi

    if [ -x ./run.sh ]; then
      exec ${pkgs.bash}/bin/bash ./run.sh nogui
    fi

    unix_args="$(${pkgs.findutils}/bin/find ./libraries -path '*/net/minecraftforge/forge/*/unix_args.txt' | ${pkgs.coreutils}/bin/head -n 1)"
    if [ -n "$unix_args" ]; then
      exec ${javaPackage}/bin/java ${jvmOpts} @"$unix_args" nogui
    fi

    echo "No SkyFactory 5 run.sh or Forge unix_args.txt found in ${dataDir}" >&2
    exit 1
  '';

  lazymcConfigTemplate = (pkgs.formats.toml {}).generate "lazymc.toml" {
    public = {
      address = "192.168.1.52:25565";
      version =
        if isSkyFactory5
        then "1.20.1"
        else "1.21.10";
      protocol =
        if isSkyFactory5
        then 763
        else 773;
    };

    server = {
      address = serverAddress;
      directory = dataDir;
      command =
        if isSkyFactory5
        then "${skyFactoryCommand}"
        else "${pkgs.minecraft-server}/bin/minecraft-server ${jvmOpts}";
      freeze_process = false;
      wake_on_start = false;
      wake_on_crash = false;
      probe_on_start = isSkyFactory5;
      forge = isSkyFactory5;
      start_timeout = 600;
      stop_timeout = 180;
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
      starting = "Looking for me hole\nReconnect shortly";
      stopping = "Server is going to sleep...\nPlease wait";
      from_server = false;
    };

    join = {
      methods = [
        "forward"
      ];
      forward.address = serverAddress;
      forward.send_proxy_v2 = false;
      hold.timeout = 180;
      kick.starting = "Grabbing Pickaxe and Getting ready.";
      kick.stopping = "That's enough holes today son";
    };

    advanced.rewrite_server_properties = true;
    config.version = "0.2.11";
  };

  writeMinecraftConfig = pkgs.writeText "write-minecraft-config.py" ''
    import json
    import pathlib
    import sys

    lazymc_template, secret_path, data_dir = sys.argv[1:]
    data_dir = pathlib.Path(data_dir)
    rcon_password = pathlib.Path(secret_path).read_text().replace("\r", "").replace("\n", "")

    lazymc = pathlib.Path(lazymc_template).read_text()
    (data_dir / "lazymc.toml").write_text(
        lazymc.replace('"__RCON_PASSWORD__"', json.dumps(rcon_password))
    )
  '';

  startLazymc = pkgs.writeShellScript "start-lazymc" ''
    set -eu

    umask 0007

    ${pkgs.coreutils}/bin/install -d -m 0750 ${lib.escapeShellArg dataDir}
    ${lib.optionalString isSkyFactory5 "${syncSkyFactoryPack}"}
    ${pkgs.coreutils}/bin/install -m 0644 ${eulaFile} ${lib.escapeShellArg dataDir}/eula.txt
    ${pkgs.coreutils}/bin/install -m 0600 ${serverPropertiesFile} ${lib.escapeShellArg dataDir}/server.properties

    ${pkgs.python3}/bin/python3 ${writeMinecraftConfig} ${lazymcConfigTemplate} ${lib.escapeShellArg rconPasswordFile} ${lib.escapeShellArg dataDir}
    ${pkgs.coreutils}/bin/chmod 0600 ${lib.escapeShellArg dataDir}/server.properties ${lib.escapeShellArg dataDir}/lazymc.toml

    exec ${pkgs.lazymc}/bin/lazymc --config ${lib.escapeShellArg dataDir}/lazymc.toml start
  '';
in {
  options.modules.minecraft.server = {
    enable = mkEnableOption "hibernating Minecraft server for darwin";

    pack = mkOption {
      type = enum [
        "vanilla"
        "skyfactory5"
      ];
      default = "vanilla";
      description = "Minecraft server pack to run behind lazymc.";
    };
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
        members = [
          user
          loginUser
        ];
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
      ${pkgs.coreutils}/bin/install -d -m 0750 -o ${lib.escapeShellArg user} -g ${lib.escapeShellArg user} ${lib.escapeShellArg serviceHome}
      ${pkgs.coreutils}/bin/install -d -m 0750 -o ${lib.escapeShellArg user} -g ${lib.escapeShellArg user} ${lib.escapeShellArg dataDir}
      ${pkgs.coreutils}/bin/install -d -m 0750 -o ${lib.escapeShellArg user} -g ${lib.escapeShellArg user} ${lib.escapeShellArg logDir}
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

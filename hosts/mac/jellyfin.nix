{
  config,
  lib,
  pkgs,
  ...
}: let
  loginUser = config.modules.profile.username;
  loginHome = config.users.users.${loginUser}.home;
  # Upstream's complete server/web bundle stays current while nixpkgs is on 12.0.
  package = pkgs.stdenvNoCC.mkDerivation {
    pname = "jellyfin";
    version = "12.1";
    src = pkgs.fetchurl {
      url = "https://lon1.mirror.jellyfin.org/files/server/macos/stable/v12.1/arm64/jellyfin_12.1-arm64.tar.xz";
      hash = "sha256-E5kxvr3A3WmX1yKBa0VlnmSP+sG42uhBNDc5g/AFq68=";
    };
    nativeBuildInputs = [pkgs.makeWrapper];
    dontBuild = true;
    dontStrip = true;
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/lib/jellyfin" "$out/bin"
      cp -R . "$out/lib/jellyfin/"
      makeWrapper "$out/lib/jellyfin/jellyfin" "$out/bin/jellyfin" \
        --add-flags "--webdir=$out/lib/jellyfin/jellyfin-web" \
        --add-flags "--ffmpeg=${pkgs.jellyfin-ffmpeg}/bin/ffmpeg"
      runHook postInstall
    '';
    meta = {
      mainProgram = "jellyfin";
      platforms = ["aarch64-darwin"];
      license = lib.licenses.gpl2Plus;
    };
  };
  group = "staff";
  dataDir = "/var/lib/jellyfin";
  configDir = "${dataDir}/config";
  cacheDir = "/var/cache/jellyfin";
  logDir = "${dataDir}/log";
  jellyfinProgram = lib.getExe package;
  jellyfinBinary = "${package}/lib/jellyfin/jellyfin";
  launchdLog = "${logDir}/launchd.log";
  mediaDirectories = ["/Volumes/chonk/media"];
  mediaProbeFiles = ["/Volumes/chonk/media/.jellyfin-read-probe"];
  launchConfig = {
    ProgramArguments = [
      launcherProgram
      "--daemon"
    ];
    WorkingDirectory = dataDir;
    RunAtLoad = true;
    KeepAlive.SuccessfulExit = false;
    EnvironmentVariables.HOME = loginHome;
    StandardOutPath = launchdLog;
    StandardErrorPath = launchdLog;
    ProcessType = "Background";
    ThrottleInterval = 30;
    ExitTimeOut = 15;
    Umask = 7;
  };

  cString = value: builtins.toJSON (toString value);
  cArray = values: lib.concatMapStringsSep ",\n    " cString values;
  launcherSource = pkgs.writeText "jellyfin-launcher.c" ''
    #include <errno.h>
    #include <fcntl.h>
    #include <signal.h>
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include <sys/stat.h>
    #include <unistd.h>

    static const char *probe_files[] = {
      ${cArray mediaProbeFiles},
      NULL
    };

    static const char *media_directories[] = {
      ${cArray mediaDirectories},
      NULL
    };

    static void probe_timeout(int signal_number) {
      static const char message[] = "Jellyfin NFS byte-read probe timed out\n";
      (void)signal_number;
      (void)write(STDERR_FILENO, message, sizeof(message) - 1);
      _exit(EXIT_FAILURE);
    }

    static int probe_file(const char *path) {
      char byte;
      int fd;
      ssize_t bytes_read;

      alarm(8);
      fd = open(path, O_RDONLY);
      if (fd == -1) {
        fprintf(stderr, "Jellyfin media probe is unreadable: %s: %s\n", path, strerror(errno));
        alarm(0);
        return -1;
      }

      bytes_read = read(fd, &byte, 1);
      if (bytes_read != 1) {
        fprintf(stderr, "Jellyfin media probe byte read failed: %s: %s\n", path,
                bytes_read == -1 ? strerror(errno) : "empty file");
        close(fd);
        alarm(0);
        return -1;
      }

      close(fd);
      alarm(0);
      return 0;
    }

    int main(int argc, char **argv) {
      struct stat path_stat;
      size_t index;
      char *const jellyfin_arguments[] = {
        "/nix/var/nix/profiles/system/sw/bin/jellyfin",
        "--datadir", ${cString dataDir},
        "--configdir", ${cString configDir},
        "--cachedir", ${cString cacheDir},
        "--logdir", ${cString logDir},
        NULL
      };

      if (signal(SIGALRM, probe_timeout) == SIG_ERR) {
        perror("Unable to install the Jellyfin NFS timeout handler");
        return EXIT_FAILURE;
      }

      for (index = 0; probe_files[index] != NULL; ++index) {
        if (probe_file(probe_files[index]) == -1) {
          return EXIT_FAILURE;
        }
      }

      if (argc != 2 || strcmp(argv[1], "--daemon") != 0) {
        puts("Jellyfin network-volume access is available.");
        return EXIT_SUCCESS;
      }

      for (index = 0; media_directories[index] != NULL; ++index) {
        if (stat(media_directories[index], &path_stat) == -1) {
          fprintf(stderr, "Jellyfin media directory is unavailable: %s: %s\n",
                  media_directories[index], strerror(errno));
          return EXIT_FAILURE;
        }
      }

      execv(jellyfin_arguments[0], jellyfin_arguments);
      fprintf(stderr, "Unable to execute Jellyfin: %s\n", strerror(errno));
      return EXIT_FAILURE;
    }
  '';
  launcherInfo = pkgs.writeText "jellyfin-launcher-Info.plist" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>CFBundleExecutable</key>
      <string>jellyfin-launcher</string>
      <key>CFBundleIdentifier</key>
      <string>home.juicy.jellyfin-server</string>
      <key>CFBundleName</key>
      <string>Jellyfin Server</string>
      <key>CFBundlePackageType</key>
      <string>APPL</string>
      <key>CFBundleShortVersionString</key>
      <string>1.0</string>
      <key>CFBundleVersion</key>
      <string>1</string>
      <key>LSUIElement</key>
      <true/>
      <key>NSNetworkVolumesUsageDescription</key>
      <string>Jellyfin needs access to the Chonk media library.</string>
    </dict>
    </plist>
  '';
  launcherApp = pkgs.stdenv.mkDerivation {
    pname = "jellyfin-launcher-app";
    version = "1.0";
    dontUnpack = true;
    buildPhase = ''
      runHook preBuild
      $CC -O2 -Wall -Wextra -Werror -o jellyfin-launcher ${launcherSource}
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      app="$out/Applications/Jellyfin Server.app"
      mkdir -p "$app/Contents/MacOS"
      install -m 0755 jellyfin-launcher "$app/Contents/MacOS/jellyfin-launcher"
      install -m 0644 ${launcherInfo} "$app/Contents/Info.plist"
      runHook postInstall
    '';
    postFixup = ''
      /usr/bin/codesign --force --sign - --identifier home.juicy.jellyfin-server \
        "$out/Applications/Jellyfin Server.app"
    '';
    meta.platforms = lib.platforms.darwin;
  };
  installedLauncherApp = "/Applications/Jellyfin Server.app";
  launcherProgram = "${installedLauncherApp}/Contents/MacOS/jellyfin-launcher";
in {
  environment.systemPackages = [
    package
    launcherApp
  ];

  system.activationScripts.etc.text = lib.mkAfter ''
    echo "preparing Jellyfin service state..." >&2
    /usr/bin/install -d -o ${lib.escapeShellArg loginUser} -g ${group} -m 0750 ${dataDir}
    /usr/bin/install -d -o ${lib.escapeShellArg loginUser} -g ${group} -m 0750 ${configDir}
    /usr/bin/install -d -o ${lib.escapeShellArg loginUser} -g ${group} -m 0750 ${cacheDir}
    /usr/bin/install -d -o ${lib.escapeShellArg loginUser} -g ${group} -m 0750 ${logDir}
    /usr/bin/install -d -o ${lib.escapeShellArg loginUser} -g ${group} -m 0750 ${dataDir}/data
    /usr/bin/touch ${lib.escapeShellArg launchdLog}
    /usr/sbin/chown ${lib.escapeShellArg loginUser}:${group} ${lib.escapeShellArg launchdLog}
    /bin/chmod 0640 ${lib.escapeShellArg launchdLog}

    # TCC grants Network Volumes access to a code identity at a stable app
    # location. Launching the bundle directly from its generation-specific
    # Nix store path invalidates that grant whenever the derivation changes.
    /usr/bin/ditto \
      ${lib.escapeShellArg "${launcherApp}/Applications/Jellyfin Server.app"} \
      ${lib.escapeShellArg installedLauncherApp}
    /usr/sbin/chown -R root:wheel ${lib.escapeShellArg installedLauncherApp}

    echo "allowing Jellyfin through the macOS application firewall..." >&2
      reconcile_firewall_app() {
        current_app="$1"
        app_suffix="$2"

        /usr/libexec/ApplicationFirewall/socketfilterfw --listapps |
          /usr/bin/awk -F ' : ' '/^[[:space:]]*[0-9]+ : / { print $2 }' |
          while IFS= read -r registered_app; do
            case "$registered_app" in
              /nix/store/*"$app_suffix")
                if [ "$registered_app" != "$current_app" ]; then
                  /usr/libexec/ApplicationFirewall/socketfilterfw --remove "$registered_app" || true
                fi
                ;;
            esac
          done

        /usr/libexec/ApplicationFirewall/socketfilterfw --add "$current_app" || true
        /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp "$current_app"
      }

    reconcile_firewall_app ${lib.escapeShellArg jellyfinProgram} /bin/jellyfin
    reconcile_firewall_app ${lib.escapeShellArg jellyfinBinary} /lib/jellyfin/jellyfin
  '';

  launchd.agents.jellyfin.serviceConfig =
    launchConfig
    // {
      LimitLoadToSessionType = "Aqua";
    };
}

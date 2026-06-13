{
  self,
  homeProfiles,
  pkgs,
  ...
}: let
  audioOutputName = "Max Linux";
  selectAudioOutput = pkgs.writeShellScript "select-max-linux-audio" ''
    set -u

    switch_audio="${pkgs.switchaudio-osx}/bin/SwitchAudioSource"
    attempts=20

    while [ "$attempts" -gt 0 ]; do
      if "$switch_audio" -a -t output | /usr/bin/grep -Fxq ${pkgs.lib.escapeShellArg audioOutputName}; then
        exec "$switch_audio" -s ${pkgs.lib.escapeShellArg audioOutputName} -t output
      fi

      attempts=$((attempts - 1))
      /bin/sleep 1
    done

    echo "Audio output ${audioOutputName} was not available"
    exit 0
  '';
  startJellyfin = pkgs.writeShellScript "start-jellyfin" ''
    set -u

    for candidate in \
      "/Applications/Jellyfin.app/Contents/MacOS/Jellyfin" \
      "/Applications/Jellyfin.app/Contents/MacOS/jellyfin" \
      "/Applications/Jellyfin Server.app/Contents/MacOS/Jellyfin Server" \
      "/opt/homebrew/bin/jellyfin" \
      "/usr/local/bin/jellyfin"
    do
      if [ -x "$candidate" ]; then
        echo "Starting Jellyfin from $candidate"
        exec "$candidate"
      fi
    done

    echo "No Jellyfin executable found in expected locations"
    exit 1
  '';
in {
  imports = with self.darwinModules; [
    system
    shell
    stylix
    emacs
  ];

  modules = {
    emacs.enable = true;
  };

  networking.hostName = "mac";
  environment.variables.FLAKE = "/Users/juicy/nixos-config";
  home-manager.sharedModules = homeProfiles.darwin;

  # GNU userland parity with Linux hosts (prefixed as g* — gsed, gtar, gfind, etc.)
  environment.systemPackages = with pkgs; [
    coreutils-prefixed
    gnused
    gnutar
    findutils
    input-leap
    mas
    switchaudio-osx
  ];

  launchd.daemons.jellyfin = {
    serviceConfig = {
      ProgramArguments = ["${startJellyfin}"];
      KeepAlive = true;
      RunAtLoad = true;
      UserName = "juicy";
      EnvironmentVariables.HOME = "/Users/juicy";
      StandardOutPath = "/tmp/jellyfin-launchd.log";
      StandardErrorPath = "/tmp/jellyfin-launchd.log";
      ThrottleInterval = 30;
    };
  };

  launchd.user.agents.mac-audio-output = {
    serviceConfig = {
      ProgramArguments = ["${selectAudioOutput}"];
      RunAtLoad = true;
      ProcessType = "Interactive";
      StandardOutPath = "/tmp/mac-audio-output.log";
      StandardErrorPath = "/tmp/mac-audio-output.log";
    };
    managedBy = "hosts.mac.audio-output";
  };

  launchd.user.agents.input-leap-client = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.input-leap}/bin/input-leapc"
        "-f"
        "-n"
        "mac"
        "leo:24800"
      ];
      KeepAlive = true;
      RunAtLoad = true;
      ProcessType = "Interactive";
      StandardOutPath = "/tmp/input-leap-client.log";
      StandardErrorPath = "/tmp/input-leap-client.log";
    };
    managedBy = "hosts.mac.input-leap";
  };

  # nix-darwin tailscale module only manages the daemon.
  # After first login run:
  #   tailscale up --login-server=https://ts.nixlab.au --accept-routes --accept-dns=false
  services.tailscale.enable = true;
}

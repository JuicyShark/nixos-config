{
  nix-config,
  system,
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  inherit (nix-config.lib.${system}.roles) mkHasRoleHome;
  hasRole = mkHasRoleHome osConfig;
  desktopEnabled = hasRole "desktop";
  jellyfinApiSecretPath = osConfig.age.secrets.jellyfin-api.path;
  jellyfinServerUrl = "http://jellyfin.home.arpa";
  jellyfinShimConfigDir = "${config.xdg.configHome}/jellyfin-mpv-shim";
in
lib.mkIf (desktopEnabled && osConfig ? age && osConfig.age.secrets ? jellyfin-api) {
  home.packages = [ pkgs.jellyfin-mpv-shim ];

  systemd.user.services.jellyfin-mpv-shim = {
    Unit = {
      Description = "Jellyfin MPV Shim";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      ExecStartPre =
        let
          bootstrapScript = pkgs.writeShellScript "jellyfin-mpv-shim-bootstrap" ''
            set -euo pipefail

            mkdir -p "${jellyfinShimConfigDir}"

            token="$(tr -d '\n' < "${jellyfinApiSecretPath}")"
            auth_header="X-Emby-Token: ''${token}"

            server_info_json="$(${lib.getExe pkgs.curl} --silent --show-error --fail \
              --header "''${auth_header}" \
              "${jellyfinServerUrl}/System/Info/Public")"
            user_info_json="$(${lib.getExe pkgs.curl} --silent --show-error --fail \
              --header "''${auth_header}" \
              "${jellyfinServerUrl}/Users/Me")"

            server_id="$(printf '%s' "''${server_info_json}" | ${lib.getExe pkgs.jq} -r '.Id')"
            server_name="$(printf '%s' "''${server_info_json}" | ${lib.getExe pkgs.jq} -r '.ServerName')"
            user_id="$(printf '%s' "''${user_info_json}" | ${lib.getExe pkgs.jq} -r '.Id')"

            cat > "${jellyfinShimConfigDir}/conf.json" <<'EOF'
            {
              "enable_gui": false,
              "player_name": "${osConfig.networking.hostName}"
            }
            EOF

            cat > "${jellyfinShimConfigDir}/cred.json" <<EOF
            [
              {
                "AccessToken": "''${token}",
                "Id": "''${server_id}",
                "Name": "''${server_name}",
                "UserId": "''${user_id}",
                "address": "${jellyfinServerUrl}",
                "connected": false,
                "username": "${config.home.username}",
                "uuid": "${osConfig.networking.hostName}"
              }
            ]
            EOF
          '';
        in
        [ bootstrapScript ];
      ExecStart = "${lib.getExe pkgs.jellyfin-mpv-shim}";
      Restart = "on-failure";
      RestartSec = 5;
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}

{
  pkgs,
  config,
  lib,
  osConfig,
  ...
}: let
  inherit (config.xdg.userDirs) videos;
  jellyfinMpvShim =
    pkgs.stdenv.hostPlatform.isLinux
    && (osConfig.modules.desktop.media.jellyfinMpvShim.enable or false);
  configureJellyfinMpvShim = pkgs.writeShellApplication {
    name = "configure-jellyfin-mpv-shim";
    runtimeInputs = [pkgs.coreutils pkgs.jq];
    text = ''
      config_dir="$1"
      config_file="$config_dir/conf.json"
      umask 077
      mkdir -p "$config_dir"
      temporary="$(mktemp "$config_file.XXXXXX")"
      trap 'rm -f "$temporary"' EXIT

      # Missing config is a first run; invalid existing config must remain intact.
      source=/dev/null
      if [[ -e "$config_file" || -L "$config_file" ]]; then
        source="$config_file"
      fi
      jq -es --argjson first_run "$([[ "$source" == /dev/null ]] && echo true || echo false)" '
        if $first_run then {}
        elif length == 1 and (.[0] | type == "object") then .[0]
        else error("Shim configuration must contain one JSON object")
        end
        | .discord_presence = false
        | .enable_gui = false
        | .display_mirroring = false
        | .direct_paths = true
        | .shader_pack_enable = false
        | .path_substitutions = (
            ((.path_substitutions // [])
              | map(select(.[0] != "/Volumes/chonk")))
            + [["/Volumes/chonk", "/mnt/chonk"]]
          )
      ' "$source" >"$temporary"
      mv -T "$temporary" "$config_file"
    '';
  };
in {
  programs.mpv = lib.mkIf ((osConfig.modules.desktop.enable or false) || pkgs.stdenv.hostPlatform.isDarwin) {
    enable = true;

    config =
      {
        profile = "gpu-hq";
      }
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        ao = "pipewire";
        gpu-api = "vulkan";
        gpu-context = "waylandvk";
      }
      // {
        vo = "gpu-next";
        hwdec = "auto-safe";

        video-sync = "display-resample";
        interpolation = true;
        tscale = "oversample";

        # Let libplacebo handle HDR metadata and tone-map to the active output.
        # Native HDR output remains compositor/output policy, not an mpv guess.
        tone-mapping = "auto";
        hdr-compute-peak = true;

        # Direct NFS playback benefits from a bounded read-ahead buffer.
        cache = true;
        cache-secs = 30;
        demuxer-max-bytes = "512MiB";
        demuxer-max-back-bytes = "128MiB";

        keep-open = true;
        sub-auto = "fuzzy";
        sub-blur = 10;

        screenshot-format = "png";

        title = "\${filename} - mpv";
        script-opts = "osc-title=\${filename},osc-boxalpha=150,osc-visibility=never,osc-boxvideo=yes";
        ytdl-format = "bestvideo[height<=?1440]+bestaudio/best";
        # audio
        alang = "eng,en";
        slang = "eng,en,enUS";

        # High-quality libplacebo scaling without stacking external shaders.
        scale = "ewa_lanczossharp";
        cscale = "ewa_lanczossharp";
        dscale = "mitchell";
        deband = "yes";
        scale-antiring = 1;

        osc = "no";
        osd-on-seek = "no";
        osd-bar = "no";
        osd-bar-w = 30;
        osd-bar-h = "0.2";
        osd-duration = 750;

        really-quiet = "yes";
        autofit = "65%";
      };

    bindings = {
      "ctrl+a" = "script-message osc-visibility cycle";
    };

    scripts =
      lib.optionals pkgs.stdenv.hostPlatform.isLinux [pkgs.mpvScripts.thumbfast pkgs.mpvScripts.sponsorblock pkgs.mpvScripts.quality-menu];
  };
  programs.yt-dlp = {
    enable = true;
    extraConfig = ''
      -o ${videos}/youtube/%(title)s.%(ext)s
    '';
  };

  # Apply policy while the service is stopped, before it reads mutable settings.
  # Credentials, device identity, and unrelated path mappings remain writable.
  systemd.user.services.jellyfin-mpv-shim = lib.mkIf jellyfinMpvShim {
    Unit = {
      Description = "Jellyfin MPV Shim";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      Environment = "XDG_CONFIG_HOME=${config.xdg.configHome}";
      ExecStartPre = "${lib.getExe configureJellyfinMpvShim} ${lib.escapeShellArg "${config.xdg.configHome}/jellyfin-mpv-shim"}";
      ExecStart = lib.getExe pkgs.jellyfin-mpv-shim;
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = ["graphical-session.target"];
  };

  home.packages = lib.optionals jellyfinMpvShim [
    pkgs.jellyfin-mpv-shim
  ];
}

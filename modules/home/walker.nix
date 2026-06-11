{
  osConfig,
  pkgs,
  lib,
  inputs,
  ...
}: let
  desktopEnabled = osConfig.modules.desktop.enable or false;
  gamingEnabled = osConfig.modules.desktop.gaming.enable or false;
  walker = lib.getExe inputs.walker.packages.${pkgs.stdenv.hostPlatform.system}.default;
  steamGamesScript = pkgs.writeText "steam-games.py" ''
    import glob
    import re
    import shutil
    import subprocess
    import sys
    from pathlib import Path


    def steam_roots():
        home = Path.home()
        candidates = [
            home / ".local/share/Steam",
            home / ".steam/steam",
        ]
        return [path for path in candidates if path.exists()]


    def unescape_vdf(value):
        return value.replace(r"\\", "\\").replace(r"\"", '"')


    def read_text(path):
        try:
            return Path(path).read_text(errors="replace")
        except OSError:
            return ""


    def library_paths(roots):
        paths = []
        seen = set()

        def add(path):
            resolved = str(Path(path).expanduser())
            if resolved not in seen and Path(resolved).exists():
                seen.add(resolved)
                paths.append(Path(resolved))

        for root in roots:
            add(root)
            library_vdf = root / "steamapps/libraryfolders.vdf"
            for match in re.finditer(r'"path"\s*"([^"]+)"', read_text(library_vdf), re.IGNORECASE):
                add(unescape_vdf(match.group(1)))

        return paths


    def installed_games(libraries):
        games = {}
        for library in libraries:
            steamapps = library / "steamapps"
            for manifest in steamapps.glob("appmanifest_*.acf"):
                appid = manifest.stem.removeprefix("appmanifest_")
                text = read_text(manifest)
                name_match = re.search(r'"name"\s*"([^"]+)"', text)
                if not name_match:
                    continue
                games[appid] = unescape_vdf(name_match.group(1))
        return games


    def c_string(data, start):
        end = data.find(b"\x00", start)
        if end < 0:
            return None
        return data[start:end].decode("utf-8", errors="replace")


    def shortcut_games(roots):
        games = {}
        for root in roots:
            for path in glob.glob(str(root / "userdata/*/config/shortcuts.vdf")):
                try:
                    data = Path(path).read_bytes()
                except OSError:
                    continue

                for marker in (b"\x01appname\x00", b"\x01AppName\x00"):
                    offset = 0
                    while True:
                        idx = data.find(marker, offset)
                        if idx < 0:
                            break
                        name = c_string(data, idx + len(marker))
                        search_start = max(0, idx - 512)
                        appid_idx = data.rfind(b"\x02appid\x00", search_start, idx)
                        if name and appid_idx >= 0 and appid_idx + 11 <= len(data):
                            appid = int.from_bytes(data[appid_idx + 7 : appid_idx + 11], "little", signed=False)
                            games[str(appid)] = name
                        offset = idx + len(marker)
        return games


    def unique_rows(games):
        rows = {}
        seen_names = {}
        for appid, name in sorted(games.items(), key=lambda item: item[1].casefold()):
            label = name.strip() or f"Steam app {appid}"
            count = seen_names.get(label, 0)
            seen_names[label] = count + 1
            if count:
                label = f"{label} ({appid})"
            rows[label] = appid
        return rows


    roots = steam_roots()
    games = installed_games(library_paths(roots))
    games.update(shortcut_games(roots))
    rows = unique_rows(games)

    if not rows:
        notify = shutil.which("notify-send")
        if notify:
            subprocess.run([notify, "Steam games", "No Steam games found"], check=False)
        sys.exit(1)

    walker_input = "\n".join(rows.keys()) + "\n"
    selected = subprocess.run(
        ["${walker}", "--dmenu", "--placeholder", "Games"],
        input=walker_input,
        text=True,
        stdout=subprocess.PIPE,
        check=False,
    ).stdout.strip()

    appid = rows.get(selected)
    if appid:
        steam = shutil.which("steam") or "steam"
        subprocess.Popen([steam, f"steam://rungameid/{appid}"])
  '';
  steamGames = pkgs.writeShellApplication {
    name = "steam-games";
    runtimeInputs = [pkgs.python3];
    text = ''
      exec python3 ${steamGamesScript} "$@"
    '';
  };
in {
  imports = [inputs.walker.homeManagerModules.default];

  config = lib.optionalAttrs desktopEnabled {
    programs.walker = {
      enable = true;
      runAsService = false;

      config = {
        close_when_open = true;
        click_to_close = true;
        selection_wrap = true;
        disable_mouse = false;
        theme = "default";

        placeholders = {
          default = {
            input = "Search";
            list = "No results";
          };
          desktopapplications = {
            input = "Launch";
            list = "No applications";
          };
          runner = {
            input = "Run command";
            list = "No commands";
          };
          clipboard = {
            input = "Clipboard";
            list = "Clipboard empty";
          };
          bitwarden = {
            input = "Bitwarden";
            list = "Vault locked or empty";
          };
          dmenu = {
            input = "Games";
            list = "No games";
          };
          windows = {
            input = "Windows";
            list = "No windows";
          };
        };

        keybinds = {
          close = ["Escape"];
          next = ["Down" "Tab"];
          previous = ["Up" "ISO_Left_Tab"];
          toggle_exact = ["ctrl e"];
          resume_last_query = ["ctrl r"];
          show_actions = ["alt j"];
          quick_activate = ["F1" "F2" "F3" "F4"];
        };

        providers = {
          default = [
            "desktopapplications"
            "calc"
            "runner"
            "commands"
          ];
          empty = ["desktopapplications"];
          max_results = 40;

          sets = {
            launcher = {
              default = [
                "desktopapplications"
                "calc"
                "runner"
                "commands"
              ];
              empty = ["desktopapplications"];
            };
            commands = {
              default = [
                "runner"
                "commands"
              ];
              empty = ["runner"];
            };
            clipboard = {
              default = ["clipboard"];
              empty = ["clipboard"];
            };
            bitwarden = {
              default = ["bitwarden"];
              empty = ["bitwarden"];
            };
            games = {
              default = ["dmenu"];
              empty = ["dmenu"];
            };
            windows = {
              default = ["windows"];
              empty = ["windows"];
            };
          };

          max_results_provider = {
            desktopapplications = 12;
            runner = 16;
            clipboard = 20;
            bitwarden = 20;
            windows = 20;
          };

          prefixes = [
            {
              prefix = ";";
              provider = "providerlist";
            }
            {
              prefix = ">";
              provider = "runner";
            }
            {
              prefix = ":";
              provider = "clipboard";
            }
            {
              prefix = "$";
              provider = "windows";
            }
            {
              prefix = "!";
              provider = "bitwarden";
            }
            {
              prefix = "=";
              provider = "calc";
            }
          ];

          clipboard.time_format = "relative";
        };
      };

      elephant = {
        installService = false;
        providers = [
          "bitwarden"
          "calc"
          "clipboard"
          "desktopapplications"
          "providerlist"
          "runner"
          "windows"
        ];
        provider.bitwarden.settings = {
          copy_command = "${pkgs.wl-clipboard-rs}/bin/wl-copy --sensitive --";
          clear_command = "${pkgs.wl-clipboard-rs}/bin/wl-copy --clear";
          autotype_support = true;
          autotype_command = "${lib.getExe pkgs.wtype} -- %VALUE%";
        };
      };
    };

    home.packages =
      (with pkgs; [
        libqalculate
        wl-clipboard-rs
        wtype
      ])
      ++ lib.optionals gamingEnabled [
        steamGames
      ];
  };
}

{pkgs, ...}: {
  programs.fastfetch.enable = true;

  xdg.configFile."fastfetch/config.jsonc".text = ''
    {
      "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/master/doc/json_schema.json",
      "logo": {
        "source": "${
      if pkgs.stdenv.hostPlatform.isDarwin
      then "macos"
      else "NixOS"
    }",
        "padding": {
          "top": 1,
          "left": 2,
          "right": 3
        }
      },
      "display": {
        "separator": "  ",
        "key": {
          "width": 12
        }
      },
      "modules": [
        {
          "type": "custom",
          "format": "\u001b[1;38;5;111m╭────────────────────────────╮"
        },
        {
          "type": "title",
          "key": "  "
        },
        {
          "type": "custom",
          "format": "\u001b[1;38;5;111m├────────────────────────────┤"
        },
        {
          "type": "os",
          "key": "   OS",
          "format": "{2}"
        },
        {
          "type": "host",
          "key": "  󰌢 Host"
        },
        {
          "type": "kernel",
          "key": "   Kernel"
        },
        {
          "type": "uptime",
          "key": "  󰔟 Uptime"
        },
        {
          "type": "packages",
          "key": "  󰏖 Pkgs"
        },
        {
          "type": "shell",
          "key": "   Shell"
        },
        {
          "type": "terminal",
          "key": "   Term"
        },
        {
          "type": "wm",
          "key": "  󱂬 WM"
        },
        {
          "type": "de",
          "key": "  󰧨 DE"
        },
        {
          "type": "display",
          "key": "  󰍹 Display",
          "compactType": "original-with-refresh-rate"
        },
        {
          "type": "custom",
          "format": "\u001b[1;38;5;111m├──────────── silicon ────────┤"
        },
        {
          "type": "cpu",
          "key": "   CPU",
          "format": "{1}"
        },
        {
          "type": "gpu",
          "key": "  󰢮 GPU",
          "format": "{1}"
        },
        {
          "type": "memory",
          "key": "   RAM"
        },
        {
          "type": "disk",
          "key": "  󰋊 Disk",
          "folders": "/",
          "format": "{1} / {2} ({3})"
        },
        {
          "type": "localip",
          "key": "  󰩟 LAN",
          "showIpv6": false,
          "showMac": false,
          "showLoop": false
        },
        {
          "type": "custom",
          "format": "\u001b[1;38;5;111m├──────────── palette ────────┤"
        },
        {
          "type": "colors",
          "symbol": "circle"
        },
        {
          "type": "custom",
          "format": "\u001b[1;38;5;111m╰────────────────────────────╯"
        }
      ]
    }
  '';
}

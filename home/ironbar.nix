{ config, ... }:

{
  xdg.configFile."ironbar/config.json".text = /* json */ ''
    {
      "icon_theme": "Fluent-dark",
      "position": "bottom",
      "anchor_to_edges": true,

      "start": [
        {
          "type": "clipboard",
          "max_items": 3,
          "truncate": {
            "length": 50,
            "mode": "end"
          }
        }
      ],

      "center": [
        {
          "type": "launcher",
          "icon_size": 40,
          "favorites": [
            "librewolf",
            "kitty",
            "Thunar",
            "srb2",
            "org.qutebrowser.qutebrowser",
            "Logseq",
            "spek",
            "mullvadbrowser"
          ]
        }
      ],

      "end": [
        {
          "type": "clock",
          "format": "%x（%a）%R"
        }
      ]
    }
  '';

  xdg.configFile."ironbar/style.css".text = with config.lib.stylix.colors; /* css */ ''
    * {
      font-family: "Noto Sans CJK JP", "Font Awesome 6 Free Solid";
      font-size: 16px;
      text-shadow: 2px 2px #${base00};
      border: none;
      border-radius: 0;
      outline: none;
      font-weight: 500;
      background: none;
      color: #${base05};
    }

    .background {
      background: alpha(#${base00}, 0.9);
    }

    .clipboard {
      padding-right: 1em;
    }

    button:hover {
      background: #${base01};
    }

    #bar {
      border-top: 1px solid #${base01};
    }

    .label {
      padding-left: 1em;
      padding-right: 1em;
    }

    .popup {
      border: 1px solid #${base01};
      padding: 1em;
    }

    .popup-clipboard .item {
      padding-bottom: 0.3em;
    }

    .popup-clock .calendar-clock {
      font-family: "Maple Mono";
      font-size: 2.5em;
      padding-bottom: 0.1em;
    }

    .popup-clock .calendar .header {
      padding-top: 1em;
      border-top: 1px solid #${base01};
      font-size: 1.5em;
    }

    .popup-clock .calendar {
      padding: 0.2em 0.4em;
    }

    .popup-clock .calendar:selected {
      color: #${base09};
    }

    .launcher .item {
      padding-left: 1em;
      padding-right: 1em;
      margin-right: 4px;
    }

    button:active {
      background: #${base04};
    }

    .launcher .open {
      box-shadow: inset 0 -2px;
    }

    .launcher .focused {
      box-shadow: inset 0 -2px #${base09};
      background: #${base01};
    }

    .popup-launcher {
      padding: 0;
    }

    .popup-launcher .popup-item:not(:first-child) {
      border-top: 1px solid #${base01};
    }
  '';
}

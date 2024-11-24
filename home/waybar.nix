{ pkgs, config, ... }:
let


  colors = config.lib.stylix.colors.withHashtag;

in
{
  programs.waybar = {
    enable = true;
settings.mainBar = {
    position= "bottom";
    layer= "top";
    height= 30;
    output = "DP-1";
    margin-top= 0;
    margin-bottom= 0;
    margin-left= 0;
    margin-right= 0;
    modules-left= [
        "custom/launcher"
        "hyprland/workspaces"
        "tray"
    ];
    modules-center= [
        "clock"
    ];
    modules-right= [
        "cpu"
        "memory"
        "disk"
        "network"
        "pulseaudio"

        #"battery"
        "custom/notification"
    ];
    clock= {
        calendar = {
          format = { today = "<span foreground='${colors.base0D}'><b>{}</b></span>"; };
        };
        format = "<span foreground='${colors.base0D}'> </span> {:%H:%M}";
        tooltip= "true";
        tooltip-format= "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        format-alt= "  {:%d/%m}";
    };
    "hyprland/workspaces"= {
        active-only= false;
        disable-scroll= true;
        format = "{icon}";
        on-click= "activate";
        format-icons= {
            "1"  = "I";
            "2"  = "II";
            "3"  = "III";
            "4"  = "IV";
            "5"  = "V";
            "6"  = "VI";
            "7"  = "VII";
            "8"  = "VIII";
            "9"  = "IX";
            "10" = "X";
            sort-by-number= true;
        };
        persistent-workspaces = {
            "1"= [];
            "2"= [];
            "3"= [];
            "4"= [];
            "5"= [];
        };
    };
    cpu= {
        format= "<span foreground='${colors.base0F}'> </span> {usage}%";
        format-alt= "<span foreground='${colors.base0F}'> </span> {avg_frequency} GHz";
        interval= 2;
        on-click-right = "foot --override font_size=14 --title float_foot zenith";
    };
    memory= {
        format= "<span foreground='${colors.base0A}'>󰟜 </span>{}%";
        format-alt= "<span foreground='${colors.base0A}'>󰟜 </span>{used} GiB"; # 
        interval= 2;
        on-click-right = "foot --override font_size=14 --title float_foot btop";
    };
    disk = {
        # path = "/";
        format = "<span foreground='${colors.base0C}'>󰋊 </span>{percentage_used}%";
        interval= 60;
        on-click-right = "foot --override font_size=14 --title float_foot btop";
    };
    network = {
        format-wifi = "<span foreground='${colors.base0B}'></span> {signalStrength}%";
        format-ethernet = "<span foreground='${colors.base0B}'>󰀂</span> {bandwidthTotalBytes}";
        tooltip-format = "Connected to {essid} {ifname} via {gwaddr}";
        format-linked = "{ifname} (No IP)";
        format-disconnected = "<span foreground='${colors.base0B}'>󰖪</span>";
    };
    tray= {
        icon-size= 20;
        spacing= 8;
    };
    pulseaudio= {
        format= "{icon}  {volume}%";
        format-muted= "<span foreground='${colors.base0D}'>  </span> {volume}%";
        format-icons= {
            default= ["<span foreground='${colors.base0D}'>  </span>"];
        };
        scroll-step= 2;
        on-click= "pwvucontrol";
    };

    "custom/launcher"= {
        format= "";
        on-click= "rofi -show drun";
        on-click-right= "wallpaper-picker";
        tooltip= "false";
    };
    "custom/notification" = {
        tooltip = false;
        format = "{icon} ";
        format-icons = {
            notification = "<span foreground='${colors.base08}'><sup></sup></span>  <span foreground='${colors.base08}'></span>";
            none = "  <span foreground='${colors.base08}'></span>";
            dnd-notification = "<span foreground='${colors.base08}'><sup></sup></span>  <span foreground='${colors.base08}'></span>";
            dnd-none = "  <span foreground='${colors.base08}'></span>";
            inhibited-notification = "<span foreground='${colors.base08}'><sup></sup></span>  <span foreground='${colors.base08}'></span>";
            inhibited-none = "  <span foreground='${colors.base08}'></span>";
            dnd-inhibited-notification = "<span foreground='${colors.base08}'><sup></sup></span>  <span foreground='${colors.base08}'></span>";
            dnd-inhibited-none = "  <span foreground='${colors.base08}'></span>";
        };
        return-type = "json";
        exec-if = "which swaync-client";
        exec = "swaync-client -swb";
        on-click = "swaync-client -t -sw";
        on-click-right = "swaync-client -d -sw";
        escape = true;
    };
  };
    style = ''
      * {
        border: none;
        border-radius: 0px;
        padding: 0;
        margin: 0;
        font-family: JetBrainsMono Nerd Font;
        font-weight: bold;
        opacity: 1;
        font-size: 18px;
      }

    tooltip label {
      margin: 5px;

    }

    #workspaces {
      padding-left: 15px;
    }
    #workspaces button {
      padding-left:  5px;
      padding-right: 5px;
      margin-right: 10px;
      }
    #workspaces button.active {
      color: ${colors.base0B};
    }
    #tray {
      margin-left: 10px;

    }
    #tray menu {
      padding: 8px;
    }
    #tray menuitem {
      padding: 1px;
    }

    #pulseaudio, #network, #cpu, #memory, #disk, #battery, #custom-notification {
      padding-left: 5px;
      padding-right: 5px;
      margin-right: 10px;

    }

    #pulseaudio {
      margin-left: 15px;
    }

    #custom-notification {
      margin-left: 15px;
      padding-right: 2px;
      margin-right: 5px;
    }

    #custom-launcher {
      font-size: 20px;

      font-weight: bold;
      margin-left: 15px;
      padding-right: 10px;
    }
  '';


  package = pkgs.waybar.overrideAttrs (oa: {
    mesonFlags = (oa.mesonFlags or [ ]) ++ [ "-Dexperimental=true" ];
  });
};
}

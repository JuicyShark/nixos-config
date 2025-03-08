{ pkgs, config, ... }:
let


  colors = config.lib.stylix.colors.withHashtag;

in
{
  programs.waybar = {
    enable = true;
    settings.mainBar = {
      position= "top";
      layer= "top";
      height= 30;
    output = "DP-1";
    margin-top= 0;
    margin-bottom= 0;
    margin-left= 0;
    margin-right= 0;
    modules-left= [
      "custom/launcher"
      "sway/workspaces"
      "sway/mode"

    ];
    modules-center= [

      "sway/window"

    ];
    modules-right= [
      "mpd"
      "pulseaudio"
      "temperature"
      "cpu"
      "memory"
      "network"
      "clock"
      "custom/vpn"
      "tray"
      "custom/notification"
    ];
    clock= {
      calendar = {
        format = { today = "<span foreground='${colors.base0D}'><b>{}</b></span>"; };
      };
        format = "<span foreground='${colors.base0D}'> </span>{:%H:%M}";
        tooltip= "true";
        tooltip-format= "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        format-alt= "  {:%d/%m}";
    };

    "sway/workspaces" = {
      all-outputs = false;
   #   format = "<span size='larger'>{name}</span> {windows}";
  format-window-separator = "<span color='${colors.base04}'> | </span>";
  window-rewrite-default = "{name}";
  window-format = "<span color='${colors.base05}'size='smaller'>{name}</span>";

  format = " {icon} <span size='smaller'>{windows} </span>";
   window-rewrite = {
      "class<.blueman-manager-wrapped>" = "";
      "class<.devede_ng.py-wrapped>" = "";
      "class<.pitivi-wrapped>" = "󱄢";
      "class<.xemu-wrapped>" = "";
      "class<1Password>" = "󰢁";
      "class<org.keepassxc.KeePassXC>" = "󰢁";
      "class<Alacritty>" = "";
      "class<Ardour-.*>" = "";
      "class<Bitwarden>" = "󰞀";
      "class<Caprine>" = "󰈎";
      "class<DBeaver>" = "";
      "class<emacs>" = "";
      "class<signal" = "󰭹";
      "class<Element>" = "󰭹";
      "class<Darktable>" = "󰄄";
      "class<Github Desktop>" = "󰊤";
      "class<Godot>" = "";
      "class<Mysql-workbench-bin>" = "";
      "class<Nestopia>" = "";
      "class<Postman>" = "󰛮";
      "class<Ryujinx>" = "󰟡";
      "class<Slack>" = "󰒱";
      "class<Spotify>" = "";
      "class<Youtube Music>" = "";
      "class<bleachbit>" = "";
      "class<code>" = "󰨞";
      "class<com.obsproject.Studio" = "󱜠";
      "class<com.usebottles.bottles>" = "󰡔";
      "class<discord>" = "󰙯";
      "class<dropbox>" = "";
      "class<dupeGuru>" = "";
      "class<firefox.*> title<.*github.*>" = "";
      "class<firefox.*> title<.*twitch|youtube|plex|jellyfin|tntdrama|bally sports.*>" = "";
      "class<firefox.*>" = "";
      "class<foot>" = "";
      "class<terminal>" = "";
      "class<fr.handbrake.ghb" = "󱁆";
      "class<heroic>" = "󱢾";
      "class<info.cemu.Cemu>" = "󰜭";
      "class<io.github.celluloid_player.Celluloid>" = "";
      "class<kitty>" = "";
      "class<libreoffice-calc>" = "󱎏";
      "class<libreoffice-draw>" = "󰽉";
      "class<libreoffice-impress>" = "󱎐";
      "class<libreoffice-writer>" = "";
      "class<mGBA>" = "󱎓";
      "class<mediainfo-gui>" = "󱂷";
      "class<melonDS>" = "󱁇";
      "class<minecraft-launcher>" = "󰍳";
      "class<mpv>" = "";
      "class<org.gnome.Nautilus>" = "󰉋";
      "class<org.kde.digikam>" = "󰄄";
      "class<org.kde.filelight>" = "";
      "class<org.prismlauncher.PrismLauncher>" = "󰍳";
      "class<org.qt-project.qtcreator>" = "";
      "class<org.shotcut.Shotcut>" = "󰈰";
      "class<org.telegram.desktop>" = "";
      "class<org.wezfurlong.wezterm>" = "";
      "class<pavucontrol>" = "";
      "class<pcsx2-qt>" = "";
      "class<pcsxr>" = "";
      "class<shotwell>" = "";
      "class<steam>" = "";
      "class<tageditor>" = "󱩺";
      "class<teams-for-linux>" = "󰊻";
      "class<thunar>" = "󰉋";
      "class<thunderbird>" = "";
      "class<unityhub>" = "󰚯";
      "class<virt-manager>" = "󰢹";
      "class<vlc>" = "󱍼";
      "class<VLC media player>" = "󱍼";
      "class<wlroots> title<.*WL-1.*>" = "";
      "class<com.github.th_ch.youtube_music>" = "󰎆";
      "code-url-handler" = "󰨞";
      "title<RPCS3.*>" = "";
      "title<Spotify Free>" = "";
      "title<Steam>" = "";
      "title<World of Warcraft" = "󰰮";

    };


    format-icons = {
      "1" = "󰎤";
      "2" = "󰎧";
      "3" = "󰎪";
      "4" = "󰎭";
      "5" = "󰮂";
      "6" = "󰎳";
      "7" = "󰎶";
      "8" = "󰎹";
      "9" = "󰎼";
      "10" = "󰽽";
      "urgent" = "";
      "default" = "";
      "empty" = "󱓼";
      "high-priority-named" = ["1" "2" "5"];
      };
    };

    "sway/window" = {
      format = "<span size='smaller'>{}</span>";
      seperate-outputs = false;
    max-length = 125;
    rewrite = {
       "(.*) - Mozilla Firefox" = "🌎 $1";
       "(.*) - vim" = " $1";
       "(.*) - zsh" = " [$1]";
      };
    };

    /*"hyprland/workspaces"= {
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
        };*/

mpd = {
    format = "{stateIcon} {consumeIcon}{randomIcon}{repeatIcon}{singleIcon}{artist} - {album} - {title} ({elapsedTime:%M:%S}/{totalTime:%M:%S}) ";
    format-disconnected = "Disconnected ";
    format-stopped = "{consumeIcon}{randomIcon}{repeatIcon}{singleIcon}Stopped ";
    interval = 10;
    consume-icons = {
        on = " "; # Icon shows only when "consume" is on
    };
    random-icons = {
        off = "<span color=\"#f53c3c\"></span> "; # Icon grayed out when "random" is off
        on = " ";
    };
    repeat-icons = {
       on = " ";
    };
    single-icons = {
        on = "1 ";
    };
    state-icons = {
        paused = "";
        playing = "";
    };
    tooltip-format = "MPD (connected)";
    tooltip-format-disconnected = "MPD (disconnected)";
};
    cpu = {
        format = "<span foreground='${colors.base0E}'></span><span size='smaller' color='${colors.base04}'>{usage}%</span>";
        format-alt = "<span foreground='${colors.base0E}'></span>{avg_frequency} <span size='smaller'>GHz</span>";
        interval = 2;
        on-click-right = "kitty zenith";
        tooltip = false;
    };
    memory = {
        format= "<span color='${colors.base0A}'>󰟜 </span><span size='smaller' color='${colors.base04}'>{used:0.1f}G/{total:0.1f}G</span>";
        interval= 2;
        on-click-right = "kitty zenith";
        tooltip = false;
    };
    disk = {
        # path = "/";
        format = "<span foreground='${colors.base0C}'>󰋊 </span><span size='smaller' color='${colors.base04}'>{percentage_used}%</span>";
        interval= 60;
        on-click-right = "kitty zenith";
        tooltip = false;
      };
    network = {
        format = "<span color='${colors.base0B}'>󰀂</span> <span size='smaller' color='${colors.base04}'>{ipaddr}/{cidr}</span>";
        format-ethernet = "<span color='${colors.base0B}'>󰀂</span> <span size='smaller' color='${colors.base04}'>{ipaddr}/{cidr}</span>";
        format-wifi = "<span color='${colors.base0B}'></span> {essid} ({signalStrength}%)";
        format-linked = "{ifname} (No IP)";
        format-disconnected = "<span color='${colors.base08}'>󰖪 </span>Disconnected";
        tooltip = false;
    };
    tray = {
        icon-size= 16;
        spacing= 10;
      };
    pulseaudio= {
      format = "<span color='${colors.base07}' size='larger'>{icon:2}</span><span size='smaller'>{volume}%</span>";
      format-bluetooth = "<span color='${colors.base07}' size='larger'>{icon:2}</span><span color='${colors.base0D}'></span><span size='smaller'>{volume}%</span>";
        format-muted = "<span color='${colors.base08}'>  </span> {volume}%";
        scroll-step = 2;
        max-volume = 125;
        on-click= "pwvucontrol";

        format-icons= {
          #default= [""];
          speakers = ["󰓃"];
          hdmi = ["󰓃"];
          phone = ["󰋋"];
          headphone = ["󰋋"];
          headset = ["󰋋"];
          hands-free = ["󰋋"];
        };
        states = {
          low = 39;
          normal = 65;
          loud = 95;
          overamplified = 130;
        };
    };
    temperature = {
        hwmon-path = "/sys/class/hwmon/hwmon2/temp1_input";
        critical-threshold = 75;
        interval = 5;
        format = "<span color='${colors.base08}'>{icon} </span><span size='smaller' color='${colors.base04}'>{temperatureC}°</span>";
        tooltip = false;
        format-icons = [ "" "" "" "" "" ];
      };
      "custom/recorder" = {
		  format = "!";
		return-type = "json";
		interval = 3;
		exec = "echo '{\"class\": \"recording\"}'";
		exec-if = "pgrep wf-recorder";
    tooltip = false;
    on-click = "killall -s SIGINT wf-recorder";
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
    "custom/vpn"  = {
      interval = 3;
      format = "{}";
      exec = "mullvad status | rg -qF 'Disconnected' && echo   || echo ";
      max-length = "100";
      on-click = "mullvad connect";
      on-click-right = "mullvad disconnect";
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

    #custom-launcher {
      font-size: 20px;
      font-weight: bold;
      padding-left: 25px;
      padding-right: 25px;
      color: ${colors.base0D};

      }
    #window {
      font-family: Iosekva Term Nerd Font;
      font-weight: unset;
      padding-left: 10px;
      color: ${colors.base0D};
    }

    #workspaces button {
      padding-left:  10px;
      padding-right: 10px;

      background-color: ${colors.base01};
      border-color: ${colors.base03};
      color: ${colors.base04};
    }
    #workspaces button:nth-child(2n) {
      background-color: ${colors.base00};
    }
    #workspaces button.focused, #workspaces button.active {
      color: ${colors.base05};
      border-bottom: 3px solid ${colors.base0D};
      border-color: ${colors.base0D};
      }
    #workspaces button.urgent {
      border-top: 2px solid ${colors.base0E};
      border-bottom: 3px solid ${colors.base0E};
      }
    #workspaces button.empty {
      color: ${colors.base03};
      }

    #workspaces button:hover {
    box-shadow: inherit;
    border-color: ${colors.base0E};
    color: ${colors.base0E};
}
    #tray, #custom-vpn, #custom-notification {
    background-color: ${colors.base01};
      }

    #tray menuitem {
      padding: 1px;
    }

    #pulseaudio, #network, #cpu, #memory, #disk, #battery, #custom-notification, #custom-vpn, #tray {
      padding-left: 10px;
      padding-right: 10px;


    }

     #pulseaudio.low {
      color: ${colors.base04};
      }

    #pulseaudio.normal {
      color: ${colors.base0B};
      }
    #pulseaudio.loud {
      color: ${colors.base09};
      }
    #pulseaudio.overamplified {
      color: ${colors.base08};
      }




    #pulseaudio.muted, #pulseaudio.source-muted {
      color: ${colors.base08};
    }
    #custom-vpn {
      padding-left: 20px;
      color: ${colors.base04};
    }
    #custom-notification {
      padding-right: 20px;
    }


  '';


  package = pkgs.waybar.overrideAttrs (oa: {
    mesonFlags = (oa.mesonFlags or [ ]) ++ [ "-Dexperimental=true" ];
  });
};
}

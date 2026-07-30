{
  config,
  osConfig,
  lib,
  inputs,
  pkgs,
  ...
}: let
  terminal = config.modules.terminal.command;
  wallpaper = "${config.home.homeDirectory}/pictures/wallpaper/5120x2160-Monstera.png";
  noctaliaSettings = {
    appLauncher = {
      autoPasteClipboard = false;
      clipboardWatchImageCommand = "wl-paste --type image --watch cliphist store";
      clipboardWatchTextCommand = "wl-paste --type text --watch cliphist store";
      clipboardWrapText = true;
      customLaunchPrefix = "uwsm app --";
      customLaunchPrefixEnabled = true;
      density = "default";
      enableClipPreview = true;
      enableClipboardChips = true;
      enableClipboardHistory = true;
      enableClipboardSmartIcons = true;
      enableSessionSearch = true;
      enableSettingsSearch = true;
      enableWindowsSearch = true;
      iconMode = "tabler";
      ignoreMouseInput = false;
      overviewLayer = false;
      pinnedApps = [];
      position = "center";
      screenshotAnnotationTool = "";
      showCategories = true;
      showIconBackground = false;
      sortByMostUsed = true;
      terminalCommand = "uwsm app -- ${terminal} -e";
      viewMode = "list";
    };
    audio = {
      enable_overdrive = true;
      enable_sounds = true;
      mprisBlacklist = [];
      preferredPlayer = "";
      spectrumFrameRate = 30;
      spectrumMirrored = true;
      visualizerType = "linear";
      volumeFeedback = false;
      volumeFeedbackSoundFile = "";
      volumeOverdrive = true;
      volumeStep = 5;
    };
    bar = {
      autoHideDelay = 500;
      autoShowDelay = 150;
      barType = "simple";
      capsuleColorKey = "primary";
      contentPadding = 2;
      density = "spacious";
      displayMode = "always_visible";
      enableExclusionZoneInset = true;
      fontScale = 1.25;
      frameRadius = 12;
      frameThickness = 8;
      hideOnOverview = false;
      marginHorizontal = 4;
      marginVertical = 4;
      middleClickAction = "settings";
      middleClickCommand = "";
      middleClickFollowMouse = false;
      monitors = ["DP-2"];
      mouseWheelAction = "none";
      mouseWheelWrap = true;
      order = ["widgets"];
      outerCorners = false;
      position = "left";
      reverseScroll = false;
      rightClickAction = "controlCenter";
      rightClickCommand = "";
      rightClickFollowMouse = true;
      screenOverrides = [];
      showCapsule = false;
      showOnWorkspaceSwitch = true;
      showOutline = false;
      widgetSpacing = 6;
      widgets = {
        border = "primary";
        center = ["audio_visualizer"];
        contact_shadow = true;
        end = [
          "tray"
          "notifications"
          "bluetooth"
          "volume"
          "brightness"
          "clock"
        ];
        font_weight = 600;
        layer = "overlay";
        left = [
          {id = "Launcher";}
          {id = "Clock";}
          {id = "SystemMonitor";}
          {id = "ActiveWindow";}
          {id = "MediaMini";}
        ];
        margin_edge = 0;
        margin_ends = 0;
        padding = 30;
        panel_overlap = 0;
        position = "left";
        radius = 0;
        radius_bottom_left = 0;
        radius_bottom_right = 0;
        radius_top_left = 0;
        right = [
          {id = "Tray";}
          {id = "plugin:privacy-indicator";}
          {id = "plugin:special-workspaces";}
          {id = "NotificationHistory";}
          {id = "Battery";}
          {id = "Volume";}
          {id = "Brightness";}
          {id = "ControlCenter";}
        ];
        scale = 1.2;
        start = [
          "workspaces"
          "launcher"
        ];
        thickness = 60;
      };
    };
    brightness = {
      backlightDeviceMappings = [];
      brightnessStep = 5;
      enableDdcSupport = false;
      enforceMinimum = true;
    };
    calendar = {
      cards = [
        {
          enabled = true;
          id = "calendar-header-card";
        }
        {
          enabled = true;
          id = "calendar-month-card";
        }
        {
          enabled = true;
          id = "weather-card";
        }
      ];
    };
    controlCenter = {
      cards = [
        {
          enabled = true;
          id = "profile-card";
        }
        {
          enabled = true;
          id = "shortcuts-card";
        }
        {
          enabled = true;
          id = "audio-card";
        }
        {
          enabled = false;
          id = "brightness-card";
        }
        {
          enabled = true;
          id = "weather-card";
        }
        {
          enabled = true;
          id = "media-sysmon-card";
        }
      ];
      diskPath = "/";
      position = "close_to_bar_button";
      shortcuts = {
        left = [
          {id = "Network";}
          {id = "Bluetooth";}
          {id = "WallpaperSelector";}
          {id = "NoctaliaPerformance";}
        ];
        right = [
          {id = "Notifications";}
          {id = "PowerProfile";}
          {id = "KeepAwake";}
          {id = "NightLight";}
        ];
      };
    };
    desktopWidgets = {
      enabled = true;
      gridSnap = false;
      gridSnapScale = false;
      monitorWidgets = [];
      overviewEnabled = true;
    };
    desktop_widgets = {
      enabled = false;
      grid = {
        cell_size = 16;
        major_interval = 4;
        visible = true;
      };
      schema_version = 2;
      widget = {
        desktop-widget-0000000000000001 = {
          box_height = 176;
          box_width = 416;
          cx = 752;
          cy = 504;
          output = "DP-2";
          rotation = 0;
          settings = {
            layout = "horizontal";
          };
          type = "media_player";
        };
      };
      widget_order = ["desktop-widget-0000000000000001"];
    };
    dock = {
      animationSpeed = 1;
      colorizeIcons = false;
      displayMode = "auto_hide";
      dockType = "floating";
      enabled = false;
      floatingRatio = 1;
      groupApps = false;
      groupClickAction = "cycle";
      groupContextMenuMode = "extended";
      groupIndicatorStyle = "dots";
      inactiveIndicators = false;
      indicatorColor = "primary";
      indicatorThickness = 3;
      launcherIcon = "";
      launcherIconColor = "none";
      launcherPosition = "end";
      launcherUseDistroLogo = false;
      monitors = [];
      onlySameOutput = true;
      pinnedApps = [];
      pinnedStatic = false;
      position = "bottom";
      showDockIndicator = false;
      showLauncherIcon = false;
      sitOnFrame = false;
      size = 1;
    };
    general = {
      allowPanelsOnScreenWithoutBar = true;
      allowPasswordWithFprintd = false;
      animationDisabled = false;
      animationSpeed = 1;
      autoStartAuth = false;
      avatarImage = "";
      boxRadiusRatio = 1;
      clockFormat = "hh\nmm";
      clockStyle = "custom";
      compactLockScreen = false;
      enableBlurBehind = true;
      enableLockScreenCountdown = true;
      enableLockScreenMediaControls = false;
      enableShadows = true;
      forceBlackScreenCorners = false;
      iRadiusRatio = 1;
      keybinds = {
        keyDown = ["Down"];
        keyEnter = [
          "Return"
          "Enter"
        ];
        keyEscape = ["Esc"];
        keyLeft = ["Left"];
        keyRemove = ["Del"];
        keyRight = ["Right"];
        keyUp = ["Up"];
      };
      language = "";
      lockOnSuspend = true;
      lockScreenAnimations = false;
      lockScreenBlur = 0;
      lockScreenCountdownDuration = 10000;
      lockScreenMonitors = [];
      lockScreenTint = 0;
      passwordChars = false;
      radiusRatio = 1;
      reverseScroll = false;
      scaleRatio = 1;
      screenRadiusRatio = 1;
      shadowDirection = "bottom_right";
      shadowOffsetX = 2;
      shadowOffsetY = 3;
      showChangelogOnStartup = true;
      showHibernateOnLockScreen = false;
      showScreenCorners = false;
      showSessionButtonsOnLockScreen = true;
      smoothScrollEnabled = true;
      telemetryEnabled = false;
    };
    hooks = {
      battery_charging = [];
      battery_discharging = [];
      battery_percentage_changed = [];
      battery_plugged = [];
      bluetooth_disabled = [];
      bluetooth_enabled = [];
      colors_changed = [];
      logging_out = [];
      power_profile_changed = [];
      rebooting = [];
      session_locked = [];
      session_unlocked = [];
      shutting_down = [];
      started = [];
      theme_mode_changed = [];
      wallpaper_changed = [];
      wifi_disabled = [];
      wifi_enabled = [];
    };
    idle = {
      behavior = {};
      pre_action_fade_seconds = 0;
    };
    location = {
      analogClockInCalendar = false;
      auto_locate = true;
      firstDayOfWeek = -1;
      hideWeatherCityName = false;
      hideWeatherTimezone = false;
      name = "Gold Coast";
      showCalendarEvents = true;
      showCalendarWeather = true;
      showWeekNumberInCalendar = false;
      use12hourFormat = true;
      useFahrenheit = false;
      weatherEnabled = true;
      weatherShowEffects = true;
    };
    lockscreen_widgets = {
      enabled = false;
      grid = {
        cell_size = 16;
        major_interval = 4;
        visible = true;
      };
      schema_version = 2;
      widget = {
        "lockscreen-login-box@DP-2" = {
          box_height = 0;
          box_width = 0;
          cx = 1680;
          cy = 1317;
          output = "DP-2";
          rotation = 0;
          settings = {
            background_color = "surface_variant";
            background_radius = 12;
            input_radius = 6;
            show_login_button = true;
          };
          type = "login_box";
        };
      };
      widget_order = ["lockscreen-login-box@DP-2"];
    };
    network = {
      airplaneModeEnabled = false;
      bluetoothAutoConnect = true;
      bluetoothDetailsViewMode = "grid";
      bluetoothHideUnnamedDevices = false;
      bluetoothRssiPollIntervalMs = 60000;
      bluetoothRssiPollingEnabled = false;
      disableDiscoverability = false;
      networkPanelView = "wifi";
      wifiDetailsViewMode = "grid";
    };
    nightLight = {
      autoSchedule = true;
      dayTemp = "6500";
      enabled = true;
      forced = false;
      manualSunrise = "06:30";
      manualSunset = "18:30";
      nightTemp = "3500";
    };
    noctaliaPerformance = {
      disableDesktopWidgets = true;
      disableWallpaper = true;
    };
    notification = {
      allowed_urgencies = [
        "normal"
        "critical"
      ];
      layer = "overlay";
      offset_y = 16;
      position = "top_center";
    };
    notifications = {
      clearDismissed = true;
      criticalUrgencyDuration = 15;
      density = "compact";
      enableBatteryToast = true;
      enableKeyboardLayoutToast = true;
      enableMarkdown = false;
      enableMediaToast = false;
      enabled = true;
      location = "top_center";
      lowUrgencyDuration = 3;
      monitors = [];
      normalUrgencyDuration = 8;
      overlayLayer = true;
      respectExpireTimeout = false;
      saveToHistory = {
        critical = true;
        low = false;
        normal = false;
      };
      sounds = {
        criticalSoundFile = "";
        enabled = true;
        excludedApps = "discord,firefox,chrome,chromium,edge";
        lowSoundFile = "";
        normalSoundFile = "";
        separateSounds = false;
        volume = 0.5;
      };
    };
    osd = {
      autoHideMs = 2000;
      enabled = true;
      enabledTypes = [
        0
        1
        2
      ];
      location = "bottom_center";
      monitors = [];
      offset_y = 24;
      overlayLayer = true;
      position = "bottom_center";
      scale = 1.2;
    };
    plugins = {
      autoUpdate = false;
      enabled = ["noctalia/bongocat"];
      notifyUpdates = true;
    };
    sessionMenu = {
      countdownDuration = 10000;
      enableCountdown = true;
      largeButtonsLayout = "single-row";
      largeButtonsStyle = true;
      position = "center";
      powerOptions = [
        {
          action = "lock";
          enabled = true;
          keybind = "1";
        }
        {
          action = "reboot";
          enabled = true;
          keybind = "4";
        }
        {
          action = "logout";
          enabled = true;
          keybind = "5";
        }
        {
          action = "shutdown";
          enabled = true;
          keybind = "6";
        }
        {
          action = "rebootToUefi";
          enabled = true;
          keybind = "7";
        }
      ];
      showHeader = true;
      showKeybinds = true;
    };
    settingsVersion = 59;
    shell = {
      screenshot = {
        directory = "~/pictures/screenshots";
      };
      panel = {
        launcher_compact = true;
        open_near_click_control_center = true;
        transparency_mode = "glass";
      };
      polkit_agent = true;
      screen_time_enabled = true;
      settings_show_advanced = true;
      telemetry_enabled = true;
    };
    systemMonitor = {
      batteryCriticalThreshold = 5;
      batteryWarningThreshold = 20;
      cpuCriticalThreshold = 90;
      cpuWarningThreshold = 80;
      criticalColor = "";
      diskAvailCriticalThreshold = 10;
      diskAvailWarningThreshold = 20;
      diskCriticalThreshold = 90;
      diskWarningThreshold = 80;
      enableDgpuMonitoring = false;
      externalMonitor = "resources || missioncenter || jdsystemmonitor || corestats || system-monitoring-center || gnome-system-monitor || plasma-systemmonitor || mate-system-monitor || ukui-system-monitor || deepin-system-monitor || pantheon-system-monitor";
      gpuCriticalThreshold = 90;
      gpuWarningThreshold = 80;
      memCriticalThreshold = 90;
      memWarningThreshold = 80;
      swapCriticalThreshold = 90;
      swapWarningThreshold = 80;
      tempCriticalThreshold = 90;
      tempWarningThreshold = 80;
      useCustomColors = false;
      warningColor = "";
    };
    templates = {
      activeTemplates = [];
      enableUserTheming = false;
    };

    ui = {
      boxBorderEnabled = false;
      fontDefaultScale = 1.15;
      fontFixedScale = 1;
      panelsAttachedToBar = true;
      scrollbarAlwaysVisible = true;
      settingsPanelMode = "attached";
      settingsPanelSideBarCardStyle = false;
      tooltipsEnabled = true;
      translucentWidgets = false;
    };
    wallpaper = {
      automationEnabled = false;
      default = {
        # Conflicts with Stylix's Noctalia wallpaper injection; force the live user path for now.
        path = lib.mkForce wallpaper;
      };
      directory = "~/pictures/wallpaper";
      enableMultiMonitorDirectories = false;
      enabled = true;
      favorites = [];
      fillColor = "#000000";
      fillMode = "crop";
      fill_mode = "center";
      hideWallpaperFilenames = false;
      last = {
        # Keep in sync with the forced default path above until wallpaper ownership is revisited.
        path = lib.mkForce wallpaper;
      };
      linkLightAndDarkWallpapers = true;
      monitor = {
        DP-2 = {
          fill_color = "primary";
        };
      };
      monitorDirectories = [];
      monitors = {
        DP-2 = {
          # Keep the explicit monitor wallpaper on the same user-owned file as the default.
          path = lib.mkForce wallpaper;
        };
      };
      overviewBlur = 0.4;
      overviewEnabled = false;
      overviewTint = 0.6;
      panelPosition = "follow_bar";
      randomIntervalSec = 300;
      setWallpaperOnAllMonitors = true;
      showHiddenFiles = false;
      skipStartupTransition = false;
      solidColor = "#1a1a2e";
      sortOrder = "name";
      transitionDuration = 1500;
      transitionEdgeSmoothness = 0.05;
      transitionType = [
        "fade"
        "disc"
        "stripes"
        "wipe"
        "pixelate"
        "honeycomb"
      ];
      useOriginalImages = false;
      useSolidColor = false;
      viewMode = "single";
      wallpaperChangeMode = "random";
    };
    widget = {
      audio_visualizer = {
        anchor = true;
        bands = 20;
        color_2 = "secondary";
        scale = 1.05;
        width = 146;
      };
      bluetooth = {
        hide_when_no_connected_device = true;
        icon_color = "tertiary";
        scale = 1.2;
      };
      brightness = {
        capsule = true;
      };
      cat = {
        type = "noctalia/bongocat:cat";
      };
      clipboard = {
        scale = 1.3;
      };
      clock = {
        color = "outline";
        font_weight = 700;
        scale = 1.5;
      };
      launcher = {
        capsule_padding = 9;
        icon_color = "outline";
        scale = 1.3;
      };
      network = {
        icon_color = "primary";
        scale = 1.2;
        show_label = false;
      };
      tray = {
        capsule_padding = 2;
        drawer = true;
        match_adjacent_spacing = true;
        scale = 1.15;
      };
      volume = {
        capsule = true;
        capsule_padding = 3;
        capsule_radius = 14;
        font_weight = 700;
        icon_color = "primary";
        scale = 1.15;
      };
      workspaces = {
        capsule_radius = 8;
        empty_color = "outline";
        font_weight = 800;
        max_label_chars = 5;
        minimal = true;
        occupied_color = "outline";
        scale = 1.25;
      };
    };
  };
in {
  imports = [inputs.noctalia.homeModules.default];

  config = lib.optionalAttrs osConfig.programs.hyprland.enable {
    home.packages = [pkgs.ddcutil];

    programs.noctalia = {
      enable = true;
      settings = noctaliaSettings;
    };

    stylix.targets.noctalia-shell.enable = true;
  };
}

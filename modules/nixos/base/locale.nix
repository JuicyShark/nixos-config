# Locale and Time Configuration
#
# Manages timezone, locale, and system state version.
# Extracted from system.nix for better modularity.
_: {
  config = {
    time.timeZone = "Australia/Brisbane";

    i18n = {
      defaultLocale = "en_AU.UTF-8";
      supportedLocales = [
        "en_AU.UTF-8/UTF-8"
        "en_US.UTF-8/UTF-8"
      ];
    };

    system.stateVersion = "25.11";
  };
}

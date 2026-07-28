# Locale and Time Configuration
#
# Manages timezone and locale. Each host owns its immutable state version.
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
  };
}

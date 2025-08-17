{ pkgs, ... }:
let
  hostsBlocklist = pkgs.stdenv.mkDerivation {
    name = "unbound-blocklist";
    src = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
      sha256 = "1ap8dm1lbgvhkh0wf8ahagi2r4iipg6yz1yzdhsl63j6fs8nlgwd"; # fill with actual
    };

    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out
      grep "^0.0.0.0" $src \
        | cut -d ' ' -f2 \
        | sed 's/\r//' \
        | grep -v "^localhost$" \
        | awk '{ print "local-zone: \"" $1 "\" redirect\nlocal-data: \"" $1 " A 0.0.0.0\"" }' > $out/blocklist.conf
    '';

  };

  ports = {
    unbound = 53;
    unbound-metrics = 9167;
  };
in
{

  services.prometheus.exporters.unbound = {
    enable = true;
    port = 9167;
    openFirewall = true;

  };

  services.unbound = {
    enable = true;
    localControlSocketPath = "/run/unbound/unbound.ctl";

    settings = {
      include = "${hostsBlocklist}/blocklist.conf";
      server = {
        interface = [
          "192.168.1.99"
          "127.0.0.1"
          "::1"
        ]; # Bind to all interfaces including br0
        access-control = [
          "127.0.0.0/8 allow"
          "192.168.1.0/24 allow"
          "::1/128 allow"
        ];
        hide-identity = true;
        hide-version = true;

        verbosity = 3;
        log-queries = true;
        log-replies = true;
        prefetch = true;
        cache-min-ttl = 300;
        cache-max-ttl = 86400;
        rrset-roundrobin = true;
        harden-glue = true;
        harden-dnssec-stripped = true;
        use-caps-for-id = false;

        # Tell Unbound .lan is a static local zone (only answer what we define)
        local-zone = [
          "lan. static"
          "twitch.tv nodefault"
          "twitchcdn.net nodefault"
          "ttvnw.net nodefault"
          "jtvnw.net nodefault"
        ];

        # Optional: log local resolution hits
        log-local-actions = true;
        local-data = [
          "'router.lan. IN A 192.168.1.1'"
          "'zues.lan. IN A 192.168.1.99'"
          "'leo.lan. IN A 192.168.1.54'"
          "'nas.lan. IN A 192.168.1.54'"
          "'imp.lan. IN A 192.168.1.53'"
          "'rpi.lan. IN A 192.168.1.59'"
          "'emerald.lan. IN A 192.168.1.150'"
          "'kunzite.lan. IN A 192.168.1.160'"
          "'home-assist.lan. IN A 192.168.1.50'"

          "'99.1.168.192.in-addr.arpa. IN PTR zues.lan.'"
          "'59.1.168.192.in-addr.arpa. IN PTR rpi.lan.'"
          "'53.1.168.192.in-addr.arpa. IN PTR imp.lan.'"
          "'54.1.168.192.in-addr.arpa. IN PTR leo.lan.'"
          "'1.1.168.192.in-addr.arpa. IN PTR router.lan.'"
        ];
      };
      # Define A records

      # root-hints = pkgs.unbound.rootHints;

      # Enable DNSSEC validation
      #  auto-trust-anchor-file = "/var/lib/unbound/root.key";
    };
  };
}

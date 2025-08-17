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
        verbosity = 1;
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
        ];

        # Optional: log local resolution hits
        log-local-actions = true;
        local-data = [
          "'router.lan. IN A 192.168.1.1'"
          "'zues.lan. IN A 192.168.1.99'"
          "'leo.lan. IN A 192.168.1.54'"
          "'nas.lan. IN A 192.168.1.54'"
          "'99.1.168.192.in-addr.arpa. IN PTR zues.lan.'"
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

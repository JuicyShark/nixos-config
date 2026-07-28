# Network Hardening
#
# Shared sysctl tuning applied to all Linux hosts.
# Role-gated server settings activate on homelab hosts.
#
# Covers:
#  - BBR congestion control (strictly better than cubic for all workloads)
#  - TCP keepalive (faster dead-connection detection)
#  - TCP Fast Open (reduces handshake RTT for returning connections)
#  - Security: disable ICMP redirects, enable SYN cookies
#  - Server: higher connection limits, conntrack table, TCP buffer tuning
{
  config,
  lib,
  pkgs,
  ...
}: let
  isServer = config.modules.monitoring.enable;
in
  lib.mkIf pkgs.stdenv.isLinux {
    # Shared firewall snippets use nftables syntax. Keep every Linux host on
    # the same backend so those rules cannot silently disappear.
    networking = {
      nftables.enable = true;
      firewall.enable = true;
    };

    boot.kernel.sysctl = lib.mkMerge [
      {
        # ── Congestion control ────────────────────────────────────────────────
        # BBR is strictly better than cubic: lower latency, higher throughput,
        # especially under shallow buffers or lossy links.
        "net.core.default_qdisc" = "fq";
        "net.ipv4.tcp_congestion_control" = "bbr";

        # ── TCP Fast Open ─────────────────────────────────────────────────────
        # 1 = client, 2 = server, 3 = both
        "net.ipv4.tcp_fastopen" = 3;

        # ── TCP keepalive ─────────────────────────────────────────────────────
        # Detect dead connections faster than the 2h default.
        "net.ipv4.tcp_keepalive_time" = 120;
        "net.ipv4.tcp_keepalive_intvl" = 30;
        "net.ipv4.tcp_keepalive_probes" = 5;

        # ── Security ──────────────────────────────────────────────────────────
        "net.ipv4.conf.all.accept_redirects" = 0;
        "net.ipv4.conf.default.accept_redirects" = 0;
        "net.ipv4.conf.all.send_redirects" = 0;
        "net.ipv4.conf.default.send_redirects" = 0;
        "net.ipv4.tcp_syncookies" = 1;
      }

      # ── Server tuning (homelab / monitoring only) ─────────────────────────
      (lib.mkIf isServer {
        # Higher connection backlog for nginx + monitoring ingest
        "net.core.somaxconn" = 4096;
        "net.core.netdev_max_backlog" = 4096;
        "net.ipv4.tcp_max_syn_backlog" = 4096;

        # Conntrack — prevent exhaustion under media streaming + many LAN clients
        "net.netfilter.nf_conntrack_max" = 131072;
        "net.netfilter.nf_conntrack_tcp_timeout_established" = 86400;
        "net.netfilter.nf_conntrack_tcp_timeout_time_wait" = 30;

        # TCP buffers for high-throughput media streaming
        "net.core.rmem_max" = 134217728; # 128 MiB
        "net.core.wmem_max" = 134217728;
        "net.ipv4.tcp_rmem" = "4096 87380 134217728";
        "net.ipv4.tcp_wmem" = "4096 65536 134217728";
      })
    ];

    # Load nf_conntrack on server hosts so the sysctl tuning above takes effect
    boot.kernelModules = lib.mkIf isServer ["nf_conntrack"];
  }

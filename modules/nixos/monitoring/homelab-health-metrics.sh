#!/usr/bin/env bash
set -euo pipefail

output_dir="${HOMELAB_METRICS_OUTPUT_DIR:?HOMELAB_METRICS_OUTPUT_DIR is required}"
mounts="${HOMELAB_BTRFS_MOUNTS:-}"
writable_paths="${HOMELAB_WRITABLE_PATHS:-}"
vpn_service="${HOMELAB_VPN_SERVICE:-}"
vpn_namespace="${HOMELAB_VPN_NAMESPACE:-}"
output="${output_dir}/homelab-health.prom"
temporary="$(mktemp "${output}.XXXXXX")"
trap 'rm -f "$temporary"' EXIT

{
  printf '# HELP homelab_btrfs_probe_success Whether Btrfs health collection succeeded.\n'
  printf '# TYPE homelab_btrfs_probe_success gauge\n'
  printf '# HELP homelab_btrfs_device_size_bytes Total device space in the Btrfs filesystem.\n'
  printf '# TYPE homelab_btrfs_device_size_bytes gauge\n'
  printf '# HELP homelab_btrfs_device_allocated_bytes Device space allocated to Btrfs chunks.\n'
  printf '# TYPE homelab_btrfs_device_allocated_bytes gauge\n'
  printf '# HELP homelab_btrfs_device_unallocated_bytes Device space not yet allocated to Btrfs chunks.\n'
  printf '# TYPE homelab_btrfs_device_unallocated_bytes gauge\n'
  printf '# HELP homelab_btrfs_device_allocated_ratio Ratio of device space allocated to Btrfs chunks.\n'
  printf '# TYPE homelab_btrfs_device_allocated_ratio gauge\n'
  printf '# HELP homelab_btrfs_data_used_ratio Ratio of allocated Btrfs data chunks in use.\n'
  printf '# TYPE homelab_btrfs_data_used_ratio gauge\n'
  printf '# HELP homelab_btrfs_metadata_used_ratio Ratio of allocated Btrfs metadata chunks in use.\n'
  printf '# TYPE homelab_btrfs_metadata_used_ratio gauge\n'
  printf '# HELP homelab_btrfs_device_errors_total Persistent Btrfs device error count.\n'
  printf '# TYPE homelab_btrfs_device_errors_total counter\n'
} >"$temporary"

IFS=: read -r -a mount_list <<<"$mounts"
for mount_path in "${mount_list[@]}"; do
  [[ -n "$mount_path" ]] || continue

  if ! mountpoint --quiet "$mount_path"; then
    printf 'homelab_btrfs_probe_success{mountpoint="%s"} 0\n' "$mount_path" >>"$temporary"
    continue
  fi

  usage="$(btrfs filesystem usage --raw "$mount_path" 2>/dev/null || true)"
  if [[ -z "$usage" ]]; then
    printf 'homelab_btrfs_probe_success{mountpoint="%s"} 0\n' "$mount_path" >>"$temporary"
    continue
  fi

  printf 'homelab_btrfs_probe_success{mountpoint="%s"} 1\n' "$mount_path" >>"$temporary"
  awk -v mountpoint="$mount_path" '
    /^[[:space:]]*Device size:/ { device_size = $3 }
    /^[[:space:]]*Device allocated:/ { device_allocated = $3 }
    /^[[:space:]]*Device unallocated:/ { device_unallocated = $3 }
    /^[[:space:]]*Data,/ {
      if (match($0, /Size:([0-9]+)/, size) && match($0, /Used:([0-9]+)/, used)) {
        data_size += size[1]
        data_used += used[1]
      }
    }
    /^[[:space:]]*Metadata,/ {
      if (match($0, /Size:([0-9]+)/, size) && match($0, /Used:([0-9]+)/, used)) {
        metadata_size += size[1]
        metadata_used += used[1]
      }
    }
    END {
      printf "homelab_btrfs_device_size_bytes{mountpoint=\"%s\"} %.0f\n", mountpoint, device_size
      printf "homelab_btrfs_device_allocated_bytes{mountpoint=\"%s\"} %.0f\n", mountpoint, device_allocated
      printf "homelab_btrfs_device_unallocated_bytes{mountpoint=\"%s\"} %.0f\n", mountpoint, device_unallocated
      if (device_size > 0) {
        printf "homelab_btrfs_device_allocated_ratio{mountpoint=\"%s\"} %.9f\n", mountpoint, device_allocated / device_size
      }
      if (data_size > 0) {
        printf "homelab_btrfs_data_used_ratio{mountpoint=\"%s\"} %.9f\n", mountpoint, data_used / data_size
      }
      if (metadata_size > 0) {
        printf "homelab_btrfs_metadata_used_ratio{mountpoint=\"%s\"} %.9f\n", mountpoint, metadata_used / metadata_size
      }
    }
  ' <<<"$usage" >>"$temporary"

  btrfs device stats "$mount_path" 2>/dev/null |
    awk -v mountpoint="$mount_path" '
      match($0, /^\[(.*)\]\.([a-z_]+)[[:space:]]+([0-9]+)/, value) {
        printf "homelab_btrfs_device_errors_total{mountpoint=\"%s\",device=\"%s\",type=\"%s\"} %s\n",
          mountpoint, value[1], value[2], value[3]
      }
    ' >>"$temporary" || true
done

printf '# HELP homelab_path_writable Whether a critical path exists and accepted a temporary write.\n' >>"$temporary"
printf '# TYPE homelab_path_writable gauge\n' >>"$temporary"
IFS=: read -r -a writable_path_list <<<"$writable_paths"
for path in "${writable_path_list[@]}"; do
  [[ -n "$path" ]] || continue

  write_test=""
  if [[ -d "$path" ]] &&
    write_test="$(mktemp "${path}/.monitoring-write-test.XXXXXX" 2>/dev/null)"; then
    printf 'homelab_path_writable{path="%s"} 1\n' "$path" >>"$temporary"
    rm -f "$write_test"
  else
    printf 'homelab_path_writable{path="%s"} 0\n' "$path" >>"$temporary"
  fi
done

if [[ -n "$vpn_service" && -n "$vpn_namespace" ]]; then
  {
    printf '# HELP homelab_vpn_guard_service_active Whether the VPN-guarded service is active.\n'
    printf '# TYPE homelab_vpn_guard_service_active gauge\n'
    printf '# HELP homelab_vpn_guard_namespace_match Whether the guarded process is in its expected network namespace.\n'
    printf '# TYPE homelab_vpn_guard_namespace_match gauge\n'
  } >>"$temporary"

  if systemctl is-active --quiet "$vpn_service"; then
    printf 'homelab_vpn_guard_service_active{service="%s",namespace="%s"} 1\n' \
      "$vpn_service" "$vpn_namespace" >>"$temporary"
    main_pid="$(systemctl show "$vpn_service" --property MainPID --value)"
    if [[ "$main_pid" =~ ^[1-9][0-9]*$ ]] &&
      ip netns identify "$main_pid" | grep --fixed-strings --line-regexp --quiet "$vpn_namespace"; then
      printf 'homelab_vpn_guard_namespace_match{service="%s",namespace="%s"} 1\n' \
        "$vpn_service" "$vpn_namespace" >>"$temporary"
    else
      printf 'homelab_vpn_guard_namespace_match{service="%s",namespace="%s"} 0\n' \
        "$vpn_service" "$vpn_namespace" >>"$temporary"
    fi
  else
    printf 'homelab_vpn_guard_service_active{service="%s",namespace="%s"} 0\n' \
      "$vpn_service" "$vpn_namespace" >>"$temporary"
    printf 'homelab_vpn_guard_namespace_match{service="%s",namespace="%s"} 1\n' \
      "$vpn_service" "$vpn_namespace" >>"$temporary"
  fi
fi

chmod 0644 "$temporary"
mv "$temporary" "$output"
trap - EXIT

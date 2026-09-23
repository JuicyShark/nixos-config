let
  juicy = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILYBI2qD4EEmV6Niz44ej+AZ3AKVaxL6iicepBSHtwnV juicy@leo";
  users = [juicy];

  host_leo = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA8/IHW71dfwPEt2AxzwpyuZnFihjN2r9d8QPxrqvpAu";
  host_pallet = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM639k+f23mcmJX8Q0UuU5W7FF0fGgF3yjfKSKOoi5df";
  host_fallarbor = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHPsx9Mg7qBNYwHsyECMf1h6xFRxcrxBLuS0GSPxmk8A";
  host_zues = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOQOb2XaMyLNZNRKvrfcwxVgeIF3rqsSNyY3Kldv735z";
  host_mac = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGRb3ffUy38yem/rXxEn1cLHDGajmU7roZ5V3Uv3QaT4";
  systems = [
    host_leo
    host_fallarbor
    host_zues
    host_mac
  ];
in {
  "login-password-hash.age".publicKeys = [host_leo host_pallet host_fallarbor host_zues] ++ users;
  "juicy-password.age".publicKeys = users ++ systems;
  "initrd-recovery-password.age".publicKeys = users;
  "cloudflared-credentials.age".publicKeys = [host_zues] ++ users;
  "grafana-secret-key.age".publicKeys = [host_zues] ++ users;
  "ha-mqtt-pass.age".publicKeys = [host_leo] ++ users;

  "qbit.age".publicKeys = [host_zues] ++ users;
  "alertmanager-smtp-password.age".publicKeys = [host_zues] ++ users;
  "vaultwarden.env.age".publicKeys = [host_zues] ++ users;
  "jellyfin-api.age".publicKeys = [host_zues] ++ users;
  "jellyfin-admin-password.age".publicKeys = [host_zues] ++ users;
  "jellystat-db-password.age".publicKeys = [host_zues] ++ users;
  "jellystat-jwt-secret.age".publicKeys = [host_zues] ++ users;
  "seerr-api.age".publicKeys = [host_zues] ++ users;
  "prowlarr-api.age".publicKeys = [host_zues] ++ users;
  "sonarr-api.age".publicKeys = [host_zues] ++ users;
  "radarr-api.age".publicKeys = [host_zues] ++ users;
  "lidarr-api.age".publicKeys = [host_zues] ++ users;
  "pirates-cookie.age".publicKeys = [host_zues] ++ users;
  "pirates-agent.age".publicKeys = [host_zues] ++ users;
  "zues-wg.age".publicKeys = [host_zues] ++ users;
  "coturn-key.age".publicKeys = [host_fallarbor] ++ users;
}

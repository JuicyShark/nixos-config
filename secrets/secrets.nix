let
  juicy = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILYBI2qD4EEmV6Niz44ej+AZ3AKVaxL6iicepBSHtwnV juicy@leo";
  users = [juicy];

  host_leo = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA8/IHW71dfwPEt2AxzwpyuZnFihjN2r9d8QPxrqvpAu";
  host_fallarbor = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHPsx9Mg7qBNYwHsyECMf1h6xFRxcrxBLuS0GSPxmk8A";
  host_zues = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOQOb2XaMyLNZNRKvrfcwxVgeIF3rqsSNyY3Kldv735z";
  systems = [
    host_leo
    host_fallarbor
    host_zues
  ];
in {
  "juicy-password.age".publicKeys = users ++ systems;
  "cloudflare-token.env.age".publicKeys = systems;
  "cloudflared-cert.age".publicKeys = [host_zues] ++ users;
  "cloudflared-credentials.age".publicKeys = [host_zues] ++ users;
  "grafana-secret-key.age".publicKeys = [host_zues] ++ users;

  "deluge-auth.age".publicKeys = systems;
  "deluge-pass.age".publicKeys = systems;

  "vaultwarden.env.age".publicKeys = systems;
  "jellyfin-api.age".publicKeys = systems;
  "jellyfin-admin-password.age".publicKeys = systems;
  "seerr-api.age".publicKeys = systems;
  "prowlarr-api.age".publicKeys = systems;
  "sonarr-api.age".publicKeys = systems;
  "radarr-api.age".publicKeys = systems;
  "lidarr-api.age".publicKeys = systems;
  "bazarr-api.age".publicKeys = systems;

  "coturn-key.age".publicKeys = systems;
  "wifi-pass.age".publicKeys = systems ++ users;
}

let

  juicy = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILYBI2qD4EEmV6Niz44ej+AZ3AKVaxL6iicepBSHtwnV juicy@leo";
  users = [ juicy ];

  host_leo = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDAIkyPtZHQP4je70NBTAnJtKEMRC9c2KYCH9htoahVj root@nixos";
  host_fallarbor = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHPsx9Mg7qBNYwHsyECMf1h6xFRxcrxBLuS0GSPxmk8A";
  host_zues = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOQOb2XaMyLNZNRKvrfcwxVgeIF3rqsSNyY3Kldv735z";
  systems = [
    host_leo
    host_fallarbor
    host_zues
  ];
in
{
  "juicy-password.age".publicKeys = users ++ systems;

  "nas-auth.age".publicKeys = users ++ systems;
  # "mullvad.age".publicKeys = [ juicy ];
  "deluge-auth.age".publicKeys = systems;

  "vaultwarden-push-id.age".publicKeys = systems;
  "vaultwarden-push-key.age".publicKeys = systems;
  "prowlarr-api.age".publicKeys = systems;
  "sonarr-api.age".publicKeys = systems;
  "radarr-api.age".publicKeys = systems;
  "lidarr-api.age".publicKeys = systems;
  "bazarr-api.age".publicKeys = systems;
  "matrix-shared-key.age".publicKeys = systems;
  "coturn-key.age".publicKeys = systems;
  "deploy-key.age".publicKeys = systems ++ users;
  "wifi-pass.age".publicKeys = systems ++ users;

}

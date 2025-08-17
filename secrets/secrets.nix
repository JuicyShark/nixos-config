let

  juicy = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILYBI2qD4EEmV6Niz44ej+AZ3AKVaxL6iicepBSHtwnV";
  users = [ juicy ];

  host_leo = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDAIkyPtZHQP4je70NBTAnJtKEMRC9c2KYCH9htoahVj";
  host_fallarbor = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHPsx9Mg7qBNYwHsyECMf1h6xFRxcrxBLuS0GSPxmk8A root@fallarbor";
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
  "mullvad.age".publicKeys = [ juicy ];
  "deluge-auth.age".publicKeys = [
    juicy
    host_leo
  ];

  "vaultwarden-push-id.age".publicKeys = [
    juicy
    host_zues
  ];
  "vaultwarden-push-key.age".publicKeys = [
    juicy
    host_zues
  ];
  "prowlarr-api.age".publicKeys = [
    juicy
    host_leo
    host_zues
  ];
  "sonarr-api.age".publicKeys = [
    juicy
    host_leo
    host_zues
  ];
  "radarr-api.age".publicKeys = [
    juicy
    host_leo
    host_zues
  ];
  "lidarr-api.age".publicKeys = [
    juicy
    host_leo
    host_zues
  ];
  "bazarr-api.age".publicKeys = [
    juicy
    host_leo
    host_zues
  ];
  "matrix-shared-key.age".publicKeys = [
    host_zues
  ];
  "coturn-key.age".publicKeys = [
    host_zues
  ];
  "deploy-key.age".publicKeys = systems;

  "wifi-pass.age".publicKeys = systems ++ users;

}

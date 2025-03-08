let

  juicy = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILYBI2qD4EEmV6Niz44ej+AZ3AKVaxL6iicepBSHtwnV";
  users = [ juicy ];

  host_leo = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDAIkyPtZHQP4je70NBTAnJtKEMRC9c2KYCH9htoahVj";
  host_dante = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICB0LrsbzqhFVx8Hm19kiVTNccH6Rhszx+AejA6LPOOI";
  host_zues = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOQOb2XaMyLNZNRKvrfcwxVgeIF3rqsSNyY3Kldv735z";
  systems = [ host_leo host_dante host_zues ];
in
{
  "juicy-password.age".publicKeys = users ++ systems;
  "juicy-keepass-master.age".publicKeys = [ juicy host_leo];
  "mullvad-account.age".publicKeys = systems;
}

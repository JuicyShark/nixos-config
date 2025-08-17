job "vaultwarden" {
  datacenters = ["home"]
  type = "service"

  group "vaultwarden" {
    count = 1

    network {
      port "http" {
        to = 8521
      }
    }

    service {
      name = "vaultwarden"
      port = "http"
      tags = ["traefik.enable=true"]
    }

    task "vaultwarden" {
      driver = "docker"

      config {
        image = "vaultwarden/server:latest"
        ports = ["http"]
        volumes = [
          "/mnt/chonk/vaultwarden:/data"
        ]
        }
        env = {
          DOMAIN = "https://pass.nixlab.au"
        }


      resources {
        cpu    = 200
        memory = 256
      }
    }
  }
}


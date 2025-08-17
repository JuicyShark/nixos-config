job "traefik" {
  datacenters = ["home"]
  type = "service"

  group "proxy" {
    count = 1

    network {
      port "http" {
        static = 8521
        to     = 8521
      }
    }

    service {
      name = "traefik"
      port = "http"
      tags = ["traefik", "urlprefix-/"]
    }

    task "traefik" {
      driver = "docker"

      config {
        image = "traefik:v2.11"
        ports = ["http"]
        args = [
          "--entrypoints.web.address=:8521",
          "--api.dashboard=true",
          "--providers.consulcatalog=true",
          "--providers.consulcatalog.endpoint.address=127.0.0.1:8500",
          "--providers.consulcatalog.defaultRule=Host(`{{ .Name }}.nixlab.au`)"
        ]
      }

      resources {
        cpu    = 200
        memory = 128
      }
    }
  }
}


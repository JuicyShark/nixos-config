job "consul-server" {
  datacenters = ["home"]
  type = "system"

  group "consul" {
    task "server" {
      driver = "docker"

      config {
        image = "hashicorp/consul:1.16"
        args = [
          "agent",
          "-server",
          "-bootstrap-expect=1",
          "-ui",
          "-client=0.0.0.0",
          "-bind=0.0.0.0",
          "-node=consul-server",
          "-datacenter=home",
          "-data-dir=/consul/data"
        ]

        volumes = [
          "consul_data:/consul/data"
        ]

        port_map = {
          "http" = 8500
          "serf" = 8301
          "server" = 8300
        }
      }

      resources {
        cpu    = 100
        memory = 128
        network {
          port "http" {
            static = 8500
          }
          port "serf" {
            static = 8301
          }
          port "server" {
            static = 8300
          }
        }
      }

      service {
        name = "consul"
        port = "http"
      }
    }

    volume "consul_data" {
      type      = "host"
      source    = "consul_data"
      read_only = false
    }
  }
}


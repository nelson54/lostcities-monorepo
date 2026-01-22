job "traefik" {
  datacenters = ["tower-datacenter"]
  type        = "service"

  group "traefik" {
    count = 1

    network {
      port  "http"{
        to = 80
      }
      port  "admin"{
        to = 8080
      }
    }

    service {
      name = "traefik-http"
      provider = "nomad"
      port = "http"
    }

    task "server" {
      driver = "podman"
      config {
        image = "docker.io/amd64/traefik:latest"
        ports = ["admin", "http"]
        args = [
          "--api.dashboard=true",
          "--api.insecure=true", ### For Test only, please do not use that in production
          "--entrypoints.web.address=:${NOMAD_PORT_http}",
          "--entrypoints.traefik.address=:${NOMAD_PORT_admin}",
          "--providers.nomad=true",
          "--providers.nomad.endpoint.address=https://192.168.1.233:443", ### IP to your nomad server

        ]
      }
    }
  }
}

variable "cpu" {
  type    = number
  default = 512
}

variable "memory" {
  type    = number
  default = 256
}

variable "memory_max" {
  type    = number
  default = 1028
}

variable "memory_reservation_mb" {
  type    = number
  default = 128
}

variable "memory_swap_mb" {
  type = number
  default = 512
}

variable "memory_swappiness" {
  type = number
  default = 0
}

job "uptime-kuma" {
  datacenters = [ "tower-datacenter"]
  type   = "service"

  update {
    max_parallel = 1
  }

  constraint {
    attribute = "${node.unique.name}"
    value = "nomad-tower-red"
  }

  group "uptime-kuma" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    network {
      mode = "bridge"

      port "http" {
        static = 3001
        to = 3001
      }
    }

    service {
      name = "uptime-kuma"
      port = "http"

      tags = [
        "urlprefix-uptime.lostcities.dev",
        "prometheus"
      ]

    }

    task "dashboard" {
      driver = "podman"

      resources {
        cpu      = var.cpu
        memory     = var.memory
        memory_max = var.memory_max
      }


      env {
        WORKING_DIR = "local"

      }

      config {
        image = "docker.io/louislam/uptime-kuma:1"
        #memory_swap = "${var.memory_swap_mb}m"
        #memory_swappiness = var.memory_swappiness
        memory_reservation = "${var.memory_reservation_mb}m"

        ports = ["http"]

        volumes = [
          "/shares/lostcities/uptime-kuma:/app/data",

        ]

        args = [

        ]

        logging {
          driver = "journald"
          options = [
            {
              "tag" = "uptime-kuma"
            }
          ]
        }
      }
    }
  }
}

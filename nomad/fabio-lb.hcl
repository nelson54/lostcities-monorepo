variable "priority" {
  type = number
  default = 10
}

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
  default = 512
}

variable "memory_reservation_mb" {
  type    = number
  default = 64
}

variable "memory_swap_mb" {
  type = number
  default = 800
}

variable "memory_swappiness" {
  type = number
  default = 0
}

job "fabio-lb" {
  datacenters = [ "tower-datacenter"]
  type = "system"

  priority = var.priority

  group "fabio-lb" {

    network {
      mode = "bridge"

      port "ui" {
        to = 9998
      }

      port "http" {
        to = 9999
      }
    }

    service {
      name = "fabio-lb-ui"
      port = "ui"

      tags = [
        "urlprefix-fabio.lostcities.app",
        "traefik.enable=true"
      ]


      check {
        type                     = "http"
        protocol = "http"
        port                     = "ui"
        path                     = "/health"
        interval                 = "30s"
        timeout                  = "10s"
        failures_before_critical = 20
        failures_before_warning  = 10
      }
    }

    service {
      name = "fabio-lb"
      port = "http"

    }

    task "fabio-lb" {
      driver = "podman"

      resources {
        cpu      = var.cpu
        memory     = var.memory
        memory_max = var.memory_max
      }

      config {
        image = "docker.io/fabiolb/fabio"
        memory_swap = "${var.memory_swap_mb}m"
        memory_swappiness = var.memory_swappiness
        memory_reservation = "${var.memory_reservation_mb}m"


        ports = ["ui", "http"]
        args = [
          "-insecure",
          "-registry.consul.addr", "192.168.1.233:8500"
        ]

        logging {
          driver = "journald"
          options = [
            {
              "tag" = "redis"
            }
          ]
        }
      }
    }

    update {
      max_parallel     = 2
      min_healthy_time = "5s"
      healthy_deadline = "3m"
      auto_revert      = true
      canary           = 1
      auto_promote     = true
    }
  }
}

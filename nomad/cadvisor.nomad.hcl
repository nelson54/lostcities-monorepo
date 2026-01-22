variable "priority" {
  type = number
  default = 60
}

variable cpu {
  type    = number
  default = 100
}

variable memory {
  type    = number
  default = 256
}

variable memory_max {
  type    = number
  default = 512
}

variable memory_reservation_mb {
  type    = number
  default = 128
}

variable memory_swap_mb {
  type = number
  default = 512
}

variable memory_swappiness {
  type = number
  default = 0
}

job "cadvisor" {
  region = "global"
  datacenters = ["tower-datacenter"]
  type = "system"
  priority = var.priority

  group "infra" {
    network {
      port "cadvisor" {
        to = 8080
      }
    }

    service {
      name = "cadvisor"
      tags = ["prometheus"]
      port = "cadvisor"
      check {
        type = "http"
        path = "/"
        interval = "10s"
        timeout = "2s"
      }
    }

    task "cadvisor" {
      driver = "podman"

      resources {
        cpu      = var.cpu
        memory     = var.memory
        memory_max = var.memory_max
      }

      config {
        image = "gcr.io/cadvisor/cadvisor"
        memory_swap = "${var.memory_swap_mb}m"
        memory_swappiness = var.memory_swappiness
        memory_reservation = "${var.memory_reservation_mb}m"

        ports = ["cadvisor"]
        privileged = true

        args = [
          //"--podman=unix:///run/user/1000/podman/podman.sock"
        ]

        volumes = [
          "/:/rootfs:ro",
          "/var/run:/var/run:rw",
          "/etc/machine-id:/etc/machine-id:ro",
          "/sys:/sys:ro",
          "/sys/fs/cgroup:/sys/fs/cgroup:ro",
          "/dev/disk/:/dev/disk:ro",
          "/var/lib/containers:/var/lib/containers:ro",

        ]
      }

      env {
        DEMO_NAME = "nomad-intro"
      }
    }
  }
}

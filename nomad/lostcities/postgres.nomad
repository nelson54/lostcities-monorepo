variable "priority" {
  type = number
  default = 10
}

variable cpu {
  type    = number
  default = 1000
}

variable memory {
  type    = number
  default = 512
}

variable memory_max {
  type    = number
  default = 1024
}

variable memory_reservation_mb {
  type    = number
  default = 128
}

variable memory_swap_mb {
  type = number
  default = 256
}

variable memory_swappiness {
  type = number
  default = 0
}

job "postgres" {
  region = "global"
  namespace = "lostcities"
  datacenters = [ "tower-datacenter"]
  type   = "service"
  priority = var.priority

  constraint {
    attribute = "${node.unique.name}"
    value = "nomad-tower-red"
  }

  group "postgres" {
    count = 1



    network {
      mode = "bridge"

      port "service-port" {
        static=5432
        to=5432
      }
    }

    service {
      name = "postgres"
      tags = ["postgres for boundary"]
      port = "service-port"
      #address_mode = "alloc"

      check {
        name     = "alive"
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"
      }

      #check {
      #  type     = "script"
      #  name     = "postgres-health"
      #  command  = "/usr/local/bin/pg_isready"
      #  interval = "10s"
      #  timeout  = "5s"
      #  task = "postgres"
      #}
    }

    task "postgres" {

      driver = "podman"

      resources {
        cpu      = var.cpu
        memory     = var.memory
        memory_max = var.memory_max
      }

      config {
        image = "docker.io/library/postgres:16.4-alpine3.20"
        #memory_swap = "${var.memory_swap_mb}m"
        #memory_swappiness = var.memory_swappiness
        memory_reservation = "${var.memory_reservation_mb}m"


        ports = ["service-port"]

        volumes = [
          "/shares/lostcities/postgres:/usr/local/pgsql",
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

      env {
        POSTGRES_USER     = "root"
        POSTGRES_PASSWORD = "rootpassword"
        POSTGRES_DB       = "boundary"
        PGDATA="/usr/local/pgsql/data"
      }

      logs {
        max_files     = 5
        max_file_size = 15
      }

      restart {
        attempts = 10
        interval = "30s"
        mode     = "fail"
        delay    = "25s"
      }
    }

    update {
      max_parallel     = 1
      min_healthy_time = "5s"
      healthy_deadline = "3m"
      auto_revert      = true
      canary           = 1
      auto_promote     = true
    }
  }
}

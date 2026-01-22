variable "priority" {
  type = number
  default = 10
}

variable "cpu" {
  type    = number
  default = 300
}

variable "memory" {
  type    = number
  default = 512
}

variable "memory_max" {
  type    = number
  default = 2048
}

variable "memory_reservation_mb" {
  type    = number
  default = 256
}

variable "memory_swap_mb" {
  type = number
  default = 512
}

variable "memory_swappiness" {
  type = number
  default = 0
}

job "redis" {

  region = "global"
  namespace = "lostcities"
  datacenters = [ "tower-datacenter"]
  type   = "service"

  priority = var.priority

  constraint {
    attribute = "${node.unique.name}"
    value = "nomad-tower-red"
  }

  group "redis" {
    count = 1

    network {
      mode = "bridge"

      port "redis" {
        static = "6379"
      }

      port "metrics" {
        to = "6379"
      }
    }


    service {
      name = "redis"
      tags = ["redis for boundary"]
      port = "redis"
      # address_mode = "alloc"

      #check {
      #  name     = "redis-check"
      #  type     = "tcp"
      #  interval = "1m"
      #  timeout  = "5s"
      #  failures_before_critical = 20
      #  failures_before_warning = 10
      #}

      #check {
      #  type     = "script"
      #  name     = "redis-health"
      #  command  = "redis-cli PING"
      #  interval = "1m"
      #  timeout  = "10s"
      #  task = "redis"
      #}

    }

    service {
      name = "redis-metrics"
      tags = []
      port = "metrics"
    }

    task "redis" {

      driver = "podman"

      resources {
        cpu      = var.cpu
        memory     = var.memory
        memory_max = var.memory_max
      }

      config {
        image = "docker.io/library/redis:6-alpine3.17"
        ports = ["redis", "metrics"]
        volumes = [
          "/shares/lostcities/redis:/data",
        ]

        args = [
            "--save", "60", "1", "--loglevel", "warning"
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
        REDIS_DATA_DIR = "/redis/data"
      }

      logs {
        max_files     = 5
        max_file_size = 15
      }

      restart {
        attempts = 10
        interval = "30s"
        delay    = "25s"
        mode     = "delay"
      }
    }



    update {
      max_parallel     = 0
      min_healthy_time = "5s"
      healthy_deadline = "3m"
      auto_revert      = true
      canary           = 1
      auto_promote     = true
    }
  }
}

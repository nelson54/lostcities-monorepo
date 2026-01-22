variable "priority" {
  type = number
  default = 10
}

variable "cpu" {
  type    = number
  default = 100
}

variable "memory" {
  type    = number
  default = 2048
}

variable "memory_max" {
  type    = number
  default = 4096
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

job "rabbitmq" {
  region = "global"
  namespace = "lostcities"
  datacenters = [ "tower-datacenter"]
  type   = "service"
  priority = var.priority

  group "rabbitmq" {
    count = 1

    network {
      mode = "bridge"

      port "rabbitmq" {
        static = "5672"
      }

      port "metrics" {
        to = "15692"
      }

      port "ui" {
        to = "15672"
      }
    }


    service {
      name = "rabbitmq"

      port = "rabbitmq"

      #check {
      #  name     = "rabbitmq-tcp-check"
      #  type     = "tcp"
      #  interval = "5m"
      #  timeout  = "10s"
      #  failures_before_critical = 20
      #  failures_before_warning = 10
      #}

      #check {
      #  type     = "script"
      #  name     = "rabbitmq-diagnostic-check"
      #  command  = "rabbitmq-diagnostics -q ping"
      #  interval = "1m"
      #  timeout  = "10s"
      #  task = "rabbitmq"
      #  #failures_before_critical = 20
      #  #failures_before_warning = 10
      #}
    }

    service {
      name = "rabbitmq-ui"
      tags = [
        "urlprefix-rabbitmq.lostcities.app",
      ]
      port = "ui"
    }

    service {
      name = "rabbitmq-metrics"
      tags = ["prometheus"]
      port = "metrics"
    }


    task "rabbitmq" {

      driver = "podman"

      env {
        #RABBITMQ_MNESIA_DIR = "/rabbitmq-data/data"
      }

      config {
        image = "docker.io/library/rabbitmq:4.0-management-alpine"
        #memory_swap = "${var.memory_swap_mb}m"
        #memory_swappiness = var.memory_swappiness
        memory_reservation = "${var.memory_reservation_mb}m"

        volumes = [
          "/shares/lostcities/rabbitmq:/rabbitmq-data",
        ]
        ports = ["rabbitmq", "metrics", "ui"]

        logging {
          driver = "journald"
          options = [
            {
              "tag" = "redis"
            }
          ]
        }
      }

      logs {
        max_files     = 5
        max_file_size = 15
      }

      resources {
        cpu    = 1000
        memory = 1024
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

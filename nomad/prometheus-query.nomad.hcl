variable "priority" {
  type = number
  default = 5
}

variable "cpu" {
  type    = number
  default = 2000
}

variable "memory" {
  type    = number
  default = 4096
}

variable "memory_max" {
  type    = number
  default = 10240
}

variable "memory_reservation_mb" {
  type    = number
  default = 512
}

variable "memory_swap_mb" {
  type = number
  default = 2048
}

variable "memory_swappiness" {
  type = number
  default = 0
}


job "prometheus-query" {
  region = "global"
  datacenters = ["tower-datacenter"]
  priority = var.priority

  constraint {
    attribute = "${node.unique.name}"
    value     = "nomad-tower-red"
  }

  update {
    max_parallel = 1
  }

  group "prometheus-query" {
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
        to     = "9090"
      }

    }

    service {
      name = "prometheus-query"
      port = "http"

      tags = [
        "urlprefix-prometheus.lostcities.dev",
        "prometheus"
      ]
      check {
        type                     = "http"
        port                     = "http"
        path                     = "/status"
        interval                 = "30s"
        timeout                  = "10s"
        failures_before_critical = 20
        failures_before_warning  = 10
      }
    }

    task "prometheus" {
      driver = "podman"
      config {
        image = "docker.io/prom/prometheus:latest"

        #memory_swap = "${var.memory_swap_mb}m"
        #memory_swappiness = var.memory_swappiness
        memory_reservation = "${var.memory_reservation_mb}m"


        ports = ["http"]

        args = [
          "--enable-feature=exemplar-storage",
          "--enable-feature=enable-otlp-receiver",
          "--web.enable-remote-write-receiver",
          "--config.file=/etc/prometheus/prometheus.yml",
          "--log.level=info",
        ]

        volumes = [
          "/shares/lostcities/prometheus-storage:/prometheus",
          "local/prometheus.yml:/etc/prometheus/prometheus.yml",
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

      resources {
        cpu      = var.cpu
        memory     = var.memory
        memory_max = var.memory_max
      }

      template {
        data = <<EOF
global:

storage:
  tsdb:
    out_of_order_time_window: 30m

EOF

        destination = "local/prometheus.yml"
        //change_mode   = "signal"
        //change_signal = "SIGHUP"
      }
    }

    update {
      max_parallel     = 0
      min_healthy_time = "5s"
      healthy_deadline = "5m"
      auto_revert      = true
      canary           = 1
      auto_promote     = true
    }
  }
}

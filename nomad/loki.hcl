variable "priority" {
  type = number
  default = 10
}

variable "cpu" {
  type    = number
  default = 1000
}

variable "memory" {
  type    = number
  default = 512
}

variable "memory_max" {
  type    = number
  default = 1024
}

variable "memory_reservation_mb" {
  type    = number
  default = 400
}

variable "memory_swap_mb" {
  type = number
  default = 600
}

variable "memory_swappiness" {
  type = number
  default = 0
}


job "loki" {
  datacenters = ["tower-datacenter"]
  priority = var.priority

  constraint {
    attribute = "${node.unique.name}"
    value = "nomad-tower-red"
  }

  update {
    max_parallel      = 1
    health_check      = "checks"
    min_healthy_time  = "10s"
    healthy_deadline  = "3m"
    progress_deadline = "5m"
  }



  group "loki" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    network {
      port "loki" {
        to = 3100
      }
    }

    //volume "loki" {
    //  type      = "host"
    //  read_only = false
    //  source    = "loki"
    //}

    service {
      name = "loki"
      port = "loki"
      check {
        name     = "Loki healthcheck"
        port     = "loki"
        type     = "http"
        path     = "/ready"
        interval = "20s"
        timeout  = "5s"
        check_restart {
          limit           = 3
          grace           = "60s"
          ignore_warnings = false
        }
      }
      tags = [

      ]
    }

    task "loki" {
      driver = "podman"

      resources {
        cpu      = var.cpu
        memory     = var.memory
        memory_max = var.memory_max
      }

      config {
        image = "docker.io/grafana/loki"
        #memory_swap = "${var.memory_swap_mb}m"
        #memory_swappiness = var.memory_swappiness
        memory_reservation = "${var.memory_reservation_mb}m"


        args = [
          "-config.file",
          "local/loki/local-config.yaml",
        ]

        volumes = [
          "/shares/lostcities/loki:/loki:rw"
        ]

        ports = ["loki"]

        logging {
          driver = "journald"
          options = [
            {
              "tag" = "redis"
            }
          ]
        }
      }

      template {
        data = <<EOH
auth_enabled: false

limits_config:
  max_label_value_length: 4096
  volume_enabled: true
  ingestion_rate_mb: 10
  retention_period: 24h
server:
  http_listen_port: 3100
  grpc_listen_port: 9096

common:
  instance_addr: 127.0.0.1
  path_prefix: /loki
  storage:
    filesystem:
      chunks_directory: /loki/chunks
      rules_directory: /loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

query_range:
  results_cache:
    cache:
      embedded_cache:
        enabled: true
        max_size_mb: 100

schema_config:
  configs:
    - from: 2020-10-24
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h


ruler:
  alertmanager_url: http://localhost:9093

# By default, Loki will send anonymous, but uniquely-identifiable usage and configuration
# analytics to Grafana Labs. These statistics are sent to https://stats.grafana.org/
#
# Statistics help us better understand how Loki is used, and they show us performance
# levels for most users. This helps us prioritize features and documentation.
# For more information on what's sent, look at
# https://github.com/grafana/loki/blob/main/pkg/analytics/stats.go
# Refer to the buildReport method to see what goes into a report.
#
# If you would like to disable reporting, uncomment the following lines:
#analytics:
#  reporting_enabled: false



EOH
        destination = "local/loki/local-config.yaml"
      }

    }
  }
}

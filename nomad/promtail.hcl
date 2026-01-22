variable "priority" {
  type = number
  default = 30
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

job "promtail" {
  datacenters = ["tower-datacenter"]
  type = "system"
  priority = var.priority

  group "promtail" {

    network {
      port "promtail_port" {
        to = 9080
      }
    }

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    service {
      name = "promtail"
      port = "promtail_port"

      check {
        type     = "http"
        path     = "/"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "promtail" {
      driver = "podman"

      resources {
        cpu      = var.cpu
        memory     = var.memory
        memory_max = var.memory_max
      }

      config {
        image = "docker.io/grafana/promtail:3.1.0"
        #memory_swap = "${var.memory_swap_mb}m"
        #memory_swappiness = var.memory_swappiness
        memory_reservation = "${var.memory_reservation_mb}m"

        args = [
          "-config.file",
          "local/config.yaml",
        ]

        volumes = [
          "/var/log/journal:/var/log/journal"
        ]
        ports = ["promtail_port"]

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
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml



clients:
{{- range service "loki" }}
  - url: 'http://{{ .Address }}:{{ .Port }}/api/prom/push'
{{- end }}


scrape_configs:
- job_name: journal
  journal:
    json: false
    max_age: 12h
    path: /var/log/journal
    labels:
      job: systemd-journal
  pipeline_stages:
    - match:
        selector: '{job="systemd-journal"}'
        stages:
          - regex:
              expression: '^(?P<timestamp>.+T.+?)'
          - timestamp:
              source: timestamp
              format: "2006-01-02T15:04:05"
    - match:
        selector: '{job="systemd-journal"}'
        stages:
          - regex:
              expression: '^(?P<timestamp>.+T.+?),[0-9]+?\sapplication=(?P<application>.+?)\sprofiles=(?P<profiles>.+?)\s(?P<level>[A-Z]*?)\s(\[(?P<thread>[a-z0-9\-]+?)\]\s)?(?P<class>.+?)\s:\s(?P<message>.+)'
          - labels:
              application:
              profiles:
              level:
              thread:
              class:
              message:


EOH
        env = false
        destination = "local/config.yaml"
      }
    }
  }
}

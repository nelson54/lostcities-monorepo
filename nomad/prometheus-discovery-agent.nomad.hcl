variable "priority" {
  type = number
  default = 10
}

variable "cpu" {
  type    = number
  default = 500
}

variable "memory" {
  type    = number
  default = 700
}

variable "memory_max" {
  type    = number
  default = 1024
}

variable "memory_reservation_mb" {
  type    = number
  default = 256
}

variable "memory_swap_mb" {
  type = number
  default = 1024
}

variable "memory_swappiness" {
  type = number
  default = 0
}


job "prometheus-discovery-agent" {
  region = "global"
  datacenters = ["tower-datacenter"]
  type = "service"
  priority = var.priority

  group "prometheus-discovery-agent" {
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
      name = "prometheus-discovery-agent"
      port = "http"

      tags = [
        "prometheus",
        "urlprefix-prometheus-agent.lostcities.app"
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

    task "prometheus-discovery-agent" {
      driver = "podman"

      resources {
        cpu      = var.cpu
        memory     = var.memory
        memory_max = var.memory_max
      }


      config {
        image = "docker.io/prom/prometheus:latest"
        #memory_swap = "${var.memory_swap_mb}m"
        #memory_swappiness = var.memory_swappiness
        memory_reservation = "${var.memory_reservation_mb}m"


        ports = ["http"]

        args = [
          //"--enable-feature=agent",
          "--enable-feature=exemplar-storage",
          "--enable-feature=extra-scrape-metrics",
          "--config.file=/etc/prometheus/prometheus.yml",
          "--log.level=info",
        ]

        volumes = [
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

      template {
        data = <<EOF
global:
  scrape_interval: 15s
  evaluation_interval: 30s

{{ range service "prometheus-query" }}
remote_write:
  - url:  "http://{{ .Address }}:{{ .Port }}/api/v1/write"
{{ else }}
{{ end }}

scrape_configs:
  - job_name: "consul"
    consul_sd_configs:
      - server: '192.168.1.233:8500'
    relabel_configs:
      - source_labels: [__meta_consul_tags]
        regex: .*,prometheus,.*
        action: keep
      - source_labels: [__meta_consul_tags]
        regex: .*,metricspath-(.+),.*
        replacement: $1
        target_label: __metrics_path__
      - source_labels: [__meta_consul_service]
        target_label: job
  - job_name: nomad_metrics
    honor_labels: true
    metrics_path: /v1/metrics
    params:
      format: [ "prometheus" ]
    static_configs:
      - targets: [ "192.168.1.231:4646", "192.168.1.232:4646", "192.168.1.233:4646", ]



EOF

        destination = "local/prometheus.yml"
        #change_mode   = "signal"
        #change_signal = "SIGHUP"
      }
    }

    update {
      max_parallel     = 1
      min_healthy_time = "5s"
      healthy_deadline = "3m"
      auto_revert      = true
      canary           = 0
      //auto_promote     = true
    }
  }
}

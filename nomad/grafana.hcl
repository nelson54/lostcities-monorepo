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
  default = 512
}

variable "memory_max" {
  type    = number
  default = 1024
}

variable "memory_reservation_mb" {
  type    = number
  default = 512
}

variable "memory_swap_mb" {
  type = number
  default = 512
}

variable "memory_swappiness" {
  type = number
  default = 0
}

job "grafana" {
  datacenters = [ "tower-datacenter"]
  type   = "service"
  priority = var.priority

  update {
    max_parallel = 1
  }

  constraint {
    attribute = "${node.unique.name}"
    value = "nomad-tower-red"
  }

  group "grafana" {
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
        static = 3000
        to = 3000
      }
    }

    service {
      name = "grafana"
      tags = [
        "urlprefix-grafana.lostcities.app",
        "prometheus"
      ]
      port = "http"
      check {
        type                     = "http"
        path                     = "/api/health"
        interval                 = "30s"
        timeout                  = "10s"
        failures_before_critical = 20
        failures_before_warning  = 10
      }
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
        GF_PATHS_DATA = "/var/lib/grafana"
        GF_PATHS_PROVISIONING = "/var/lib/grafana/provisioning"
        GF_SERVER_ROOT_URL = "http://grafana.lostcities.dev:80"
        GF_SERVER_DOMAIN = "grafana.lostcities.dev"
      }

      config {
        image = "docker.io/grafana/grafana:latest"
        #memory_swap = "${var.memory_swap_mb}m"
        #memory_swappiness = var.memory_swappiness
        memory_reservation = "${var.memory_reservation_mb}m"

        ports = ["http"]

        volumes = [
          "/shares/lostcities/grafana:/var/lib/grafana",
          "local/provisioning:/var/lib/grafana/provisioning"
        ]

        args = [

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
apiVersion: 1

deleteDatasources:
  - name: Prometheus
    orgId: 1

datasources:
  - name: Prometheus
    type: prometheus
    # Access mode - proxy (server in the UI) or direct (browser in the UI).
    orgId: 1
    access: proxy
{{ range service "prometheus-query" }}
    url: http://{{ .Address }}:{{ .Port }}
{{ else }}
    url:
{{ end }}
    isDefault: true
    basicAuth: false
    jsonData:
      graphiteVersion: "1.1"
      tlsAuth: false
      tlsAuthWithCACert: false
    version: 1
    editable: false

EOF

        env = false
        destination   = "local/provisioning/datasources/datasource.yml"
        # change_mode   = "signal"
        # change_signal = "SIGHUP"
      }
    }
  }
}

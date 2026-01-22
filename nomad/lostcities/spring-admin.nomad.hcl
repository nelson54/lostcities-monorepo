variable "cpu" {
  type    = number
  default = 100
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
  default = 128
}

variable "memory_swap_mb" {
  type = number
  default = 512
}

variable "memory_swappiness" {
  type = number
  default = 0
}

job "spring-boot-admin" {
  region = "global"
  namespace = "lostcities"
  datacenters = ["tower-datacenter"]

  update {
    max_parallel = 1
  }

  group "spring-boot-admin" {
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
        to     = "8080"
      }

    }

    service {
      name = "spring-boot-admin"
      port = "http"
      tags = []

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

    task "spring-boot-admin" {
      driver = "podman"

      resources {
        cpu      = var.cpu
        memory     = var.memory
        memory_max = var.memory_max
      }


      config {
        image = "docker.io/codecentric/spring-boot-admin:3.3.4"
        #memory_swap = "${var.memory_swap_mb}m"
        #memory_swappiness = var.memory_swappiness
        memory_reservation = "${var.memory_reservation_mb}m"


        ports = ["http"]

        args = [
          //"--enable-feature=agent",

        ]

        volumes = [
          "local/:/usr/share/codecentric/conf/",
        ]

        logging {
          driver = "journald"
          options = [
            {
              "tag" = "spring-boot-admin"
            }
          ]
        }
      }

      template {
        data = <<EOF
{{ range service "accounts-management" }}
spring.boot.admin.client.url={{ .Address }}:{{ .Port }};
{{ else }}

{{ end }}
spring.boot.admin.client.instance.management-base-url=/management/accounts/actuator
spring.boot.admin.client.enabled=true
spring.boot.admin.client.auto-registration=true
spring.boot.admin.routes.endpoints=env, metrics, *

EOF

        destination = "local/application.properties"
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
      auto_promote     = false
    }
  }
}

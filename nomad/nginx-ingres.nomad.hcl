variable "priority" {
  type = number
  default = 10
}

variable "cpu" {
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
  default = 31
}

variable memory_swap_mb {
  type    = number
  default = 1028
}

variable memory_swappiness {
  type    = number
  default = 0
}

variable count {
  type    = number
  default = 1
}

job "nginx-ingress" {
  region = "global"
  datacenters = ["tower-datacenter"]
  priority = var.priority

  update {
    max_parallel      = 1
    health_check      = "checks"
    min_healthy_time  = "10s"
    healthy_deadline  = "3m"
    progress_deadline = "5m"
  }

  meta {
    #allow_ipv4 = var.allow_ipv4
  }

  constraint {
    attribute = "${node.unique.name}"
    value     = "nomad-tower-red"
  }

  group "nginx-ingress" {
    count = var.count

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    network {
      port "metrics" {
        to = 9145
      }

      port "https" {
        static = 443
        to = 4433
      }

    }

    service {
      name = "nginx-ingress"
      port = "https"
    }

    service {
      name = "nginx-metrics"
      tags = ["prometheus"]
      port = "metrics"
    }

    task "nginx" {
      driver = "podman"

      resources {
        cpu      = var.cpu
        memory     = var.memory
        memory_max = var.memory_max
      }

      config {
        image              = "ghcr.io/lostcities-cloud/openresty-prometheus:latest"
        #memory_swap = "${var.memory_swap_mb}m"
        #memory_swappiness = var.memory_swappiness
        memory_reservation = "${var.memory_reservation_mb}m"

        ports = ["https", "metrics"]

        volumes = [
          "local/nginx.conf:/etc/nginx/nginx.conf",
          "/shares/lostcities/nginx/:/etc/nginx/keys"
          //"/var/opt/nginx:/var/opt/nginx"
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
user www-data;
worker_processes auto;
worker_rlimit_nofile 8192;
pid /run/nginx.pid;

load_module /usr/lib/nginx/modules/ngx_stream_module.so;

events {
        worker_connections 4096;
}

stream{

  # register the backend services, the node apps, with this nginx instance
  upstream allbackend {
{{- range service "nginx-secure" }}
    server {{ .Address }}:{{ .Port }}
{{- end }}
  }

  server{
    listen 443;
      proxy_pass http://allbackend/;
    }
  }
}

http {
  lua_shared_dict prometheus_metrics 10M;
  lua_package_path "/usr/local/openresty/luajit/lib/luarocks/rocks-5.1/nginx-lua-prometheus/?.lua;;";

  init_worker_by_lua_block {
    prometheus = require("prometheus").init("prometheus_metrics")

    metric_requests = prometheus:counter(
      "nginx_http_requests_total", "Number of HTTP requests", {"host", "status"})
    metric_latency = prometheus:histogram(
      "nginx_http_request_duration_seconds", "HTTP request latency", {"host"})
    metric_connections = prometheus:gauge(
      "nginx_http_connections", "Number of HTTP connections", {"state"})
  }

  log_by_lua_block {
    metric_requests:inc(1, {ngx.var.server_name, ngx.var.status})
    metric_latency:observe(tonumber(ngx.var.request_time), {ngx.var.server_name})
  }

  server {
    listen 9145;
    location /metrics {
      content_by_lua_block {
        metric_connections:set(ngx.var.connections_reading, {"reading"})
        metric_connections:set(ngx.var.connections_waiting, {"waiting"})
        metric_connections:set(ngx.var.connections_writing, {"writing"})
        prometheus:collect()
      }
    }
  }
}





EOF

        destination   = "local/nginx.conf"
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }
    }
  }
}


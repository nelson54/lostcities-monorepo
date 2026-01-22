variables {
  frontendVersion = "0.1.14"
}

variable "priority" {
  type = number
  default = 30
}

variable count {
  type    = number
  default = 2
}

variable cpu {
  type    = number
  default = 200
}

variable memory {
  type    = number
  default = 512
}

variable memory_max {
  type    = number
  default = 1028
}

variable memory_reservation_mb {
  type    = number
  default = 31
}

variable memory_swap_mb {
  type    = number
  default = 256
}

variable memory_swappiness {
  type    = number
  default = 0
}

job "nginx-frontend" {
  region = "global"
  namespace = "lostcities"
  datacenters = ["tower-datacenter"]

  constraint {
    attribute = "${node.unique.name}"
    value     = "nomad-tower-red"
  }

  update {
    max_parallel      = 1
    health_check      = "checks"
    min_healthy_time  = "10s"
    healthy_deadline  = "3m"
    progress_deadline = "5m"
  }

  group "nginx" {
    count = 1

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

      port "http" {
        to = 80
      }

    }

    service {
      name = "nginx-frontend"
      port = "http"

      tags = [
        "prometheus",
        "urlprefix-lostcities.app",
      ]

      check {
        type                     = "http"
        path                     = "/health"
        port                     = "metrics"
        interval                 = "30s"
        timeout                  = "10s"
        failures_before_critical = 20
        failures_before_warning  = 10
      }
    }

    service {
      name = "nginx-secure"
      tags = ["default"]
      port = "http"
    }

    service {
      name = "nginx-metrics"
      tags = ["prometheus"]

      port = "metrics"
    }

    task "nginx" {
      driver = "podman"

      resources {
        cpu        = var.cpu
        memory     = var.memory
        memory_max = var.memory_max
      }

      config {
        image              = "ghcr.io/lostcities-cloud/openresty-prometheus:latest"
        #memory_swap = "${var.memory_swap_mb}m"
        #memory_swappiness = var.memory_swappiness
        memory_reservation = "${var.memory_reservation_mb}m"

        ports = ["http", "metrics"]

        volumes = [
          "local:/etc/nginx/conf.d",
          "local/frontend/package:/opt/lostcities/frontend",
          //"/var/opt/nginx:/var/opt/nginx"
        ]

        logging {
          driver = "journald"
          options = [
            {
              "tag" = "nginx"
            }
          ]
        }
      }

      artifact {
        source      = "https://github.com/lostcities-cloud/lostcities-frontend/releases/download/${var.frontendVersion}/lostcities-frontend.tgz"
        destination = "local/frontend"
      }

      template {
        data = <<EOF
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

  location = /health {
    access_log off;
    add_header 'Content-Type' 'application/json';
    return 200 '{"status":"UP"}';
  }
}

server {
    listen 80 ;

    root  /opt/lostcities/frontend;

    #include /etc/nginx/mime.types;

    location / {
        try_files $uri /index.html;
        add_header Strict-Transport-Security "max-age=1000; includeSubDomains" always;
    }
}


EOF

        destination   = "local/load-balancer.conf"
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }
    }
  }
}


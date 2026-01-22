variable "priority" {
  type = number
  default = 5
}

variable "count" {
  type    = number
  default = 2
}

variable "cpu" {
  type    = number
  default = 300
}

variable memory {
  type    = number
  default = 1028
}

variable memory_max {
  type    = number
  default = 2046
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

job "nginx-router" {
  region = "global"
  datacenters = ["tower-datacenter"]
  priority = var.priority
  meta {
    #allow_ipv4 = var.allow_ipv4
  }

  group "nginx-router" {
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
      port "http" {
        to = 80
      }

    }

    service {
      name = "nginx-router"
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
        cpu      = var.cpu
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

upstream consul-red {
  server 192.168.1.233:8500;
}

upstream nomad-red {
  server 192.168.1.233:4646;
}

upstream fabio-lb-ui {
{{ range service "fabio-lb-ui" }}
  server {{ .Address }}:{{ .Port }};
{{ else }}
  server 127.0.0.1:65535; # force a 502
{{ end }}
}

upstream prometheus-agent {
{{ range service "prometheus-discovery-agent" }}
  server {{ .Address }}:{{ .Port }};
{{ else }}
  server 127.0.0.1:65535; # force a 502
{{ end }}
}

upstream prometheus-query {
{{ range service "prometheus-query" }}
  server {{ .Address }}:{{ .Port }};
{{ else }}
  server 127.0.0.1:65535; # force a 502
{{ end }}
}

upstream grafana {
{{ range service "grafana" }}
  server {{ .Address }}:{{ .Port }};
{{ else }}
  server 127.0.0.1:65535; # force a 502
{{ end }}
}

upstream rabbitmq-ui {
{{ range service "rabbitmq-ui" }}
  server {{ .Address }}:{{ .Port }};
{{ else }}
  server 127.0.0.1:65535; # force a 502
{{ end }}
}

upstream homepage {
{{ range service "homepage" }}
  server {{ .Address }}:{{ .Port }};
{{ else }}
  server 127.0.0.1:65535; # force a 502
{{ end }}
}

upstream uptime-kuma {
{{ range service "uptime-kuma" }}
  server {{ .Address }}:{{ .Port }};
{{ else }}
  server 127.0.0.1:65535; # force a 502
{{ end }}
}

server {
    server_name uptime.lostcities.app;
    listen 80;

    #gzip            on;
    #gzip_min_length 1000;
    #gzip_types      text/plain application/json;

    location / {

        allow 192.168.1.201;
        allow 192.168.1.1;
        #allow 192.168.1.0/24;
        allow 68.49.57.165;
        allow 192.168.1.231;
        allow 192.168.1.232;
        allow 192.168.1.233;
        #allow 10.88.0.1;
        deny all;

        proxy_pass http://uptime-kuma;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Port $server_port;
        proxy_set_header X-Forwarded-Host $host;
        proxy_redirect off;
        proxy_connect_timeout 90s;
        proxy_read_timeout 90s;
        proxy_send_timeout 90s;
    }

}

#server {
#    server_name dashboard.lostcities.app;
#    listen 80;
#
#    #gzip            on;
#    #gzip_min_length 1000;
#    #gzip_types      text/plain application/json;
#
#    allow 192.168.1.0/24;
#    allow 68.49.57.165;
#    deny all;
#
#    location / {
#        proxy_pass http://homepage;
#        proxy_http_version 1.1;
#        proxy_set_header Upgrade $http_upgrade;
#        proxy_set_header Connection "Upgrade";
#        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
#        proxy_set_header X-Forwarded-Proto $scheme;
#        proxy_set_header X-Forwarded-Port $server_port;
#        proxy_set_header X-Forwarded-Host $host;
#        proxy_redirect off;
#        proxy_connect_timeout 90s;
#        proxy_read_timeout 90s;
#        proxy_send_timeout 90s;
#    }
#
#}
#
#server {
#    server_name grafana.lostcities.app;
#    listen 80;
#
#    allow 192.168.1.0/24;
#    allow 68.49.57.165;
#    deny all;
#
#    location / {
#        proxy_set_header Host $host;
#        proxy_pass http://grafana;
#    }
#
#    # Proxy Grafana Live WebSocket connections.
#    location /api/live/ {
#        proxy_http_version 1.1;
#        proxy_set_header Upgrade $http_upgrade;
#        proxy_set_header Connection "Upgrade";
#        proxy_set_header Host $host;
#        proxy_pass http://grafana;
#    }
#
#}
#
#server {
#    server_name prometheus.lostcities.app;
#    listen 80;
#
#    allow 192.168.1.0/24;
#    allow 68.49.57.165;
#    deny all;
#
#
#    location / {
#        proxy_pass http://prometheus-query;
#        proxy_http_version 1.1;
#        proxy_set_header Upgrade $http_upgrade;
#        proxy_set_header Connection "Upgrade";
#        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
#        proxy_set_header X-Forwarded-Proto $scheme;
#        proxy_set_header X-Forwarded-Port $server_port;
#        proxy_set_header X-Forwarded-Host $host;
#        proxy_redirect off;
#        proxy_connect_timeout 90s;
#        proxy_read_timeout 90s;
#        proxy_send_timeout 90s;
#    }
#
#}
#
#server {
#    server_name prometheus-agent.lostcities.app;
#    listen 80;
#
#    allow 192.168.1.0/24;
#    allow 68.49.57.165;
#    deny all;
#
#    location / {
#        proxy_pass http://prometheus-agent;
#        proxy_http_version 1.1;
#        proxy_set_header Upgrade $http_upgrade;
#        proxy_set_header Connection "Upgrade";
#        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
#        proxy_set_header X-Forwarded-Proto $scheme;
#        proxy_set_header X-Forwarded-Port $server_port;
#        proxy_set_header X-Forwarded-Host $host;
#        proxy_redirect off;
#        proxy_connect_timeout 90s;
#        proxy_read_timeout 90s;
#        proxy_send_timeout 90s;
#    }
#
#}
#
#
#
#server {
#    server_name rabbitmq.lostcities.app;
#    listen 80;
#
#    allow 192.168.1.0/24;
#    allow 68.49.57.165;
#    deny all;
#
#    location / {
#        proxy_pass http://rabbitmq-ui;
#        proxy_http_version 1.1;
#        proxy_set_header Upgrade $http_upgrade;
#        proxy_set_header Connection "Upgrade";
#        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
#        proxy_set_header X-Forwarded-Proto $scheme;
#        proxy_set_header X-Forwarded-Port $server_port;
#        proxy_set_header X-Forwarded-Host $host;
#        proxy_redirect off;
#        proxy_connect_timeout 90s;
#        proxy_read_timeout 90s;
#        proxy_send_timeout 90s;
#    }
#
#}
#
#server {
#    server_name fabiolb.lostcities.app;
#    listen 80;
#
#    allow 192.168.1.0/24;
#    allow 68.49.57.165;
#    deny all;
#
#    location / {
#        proxy_pass http://fabio-lb-ui;
#        proxy_http_version 1.1;
#        proxy_set_header Upgrade $http_upgrade;
#        proxy_set_header Connection "Upgrade";
#        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
#        proxy_set_header X-Forwarded-Proto $scheme;
#        proxy_set_header X-Forwarded-Port $server_port;
#        proxy_set_header X-Forwarded-Host $host;
#        proxy_redirect off;
#        proxy_connect_timeout 90s;
#        proxy_read_timeout 90s;
#        proxy_send_timeout 90s;
#    }
#
#}
#
#server {
#    server_name nomad-red.lostcities.app;
#    listen 80;
#    allow 192.168.1.0/24;
#    allow 68.49.57.165;
#    deny all;
#
#    location / {
#        proxy_pass http://nomad-red;
#        proxy_http_version 1.1;
#        proxy_set_header Upgrade $http_upgrade;
#        proxy_set_header Connection "Upgrade";
#        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
#        proxy_set_header X-Forwarded-Proto $scheme;
#        proxy_set_header X-Forwarded-Port $server_port;
#        proxy_set_header X-Forwarded-Host $host;
#        proxy_redirect off;
#        proxy_connect_timeout 90s;
#        proxy_read_timeout 90s;
#        proxy_send_timeout 90s;
#    }
#
#}

#server {
#    server_name consul-red.lostcities.app;
#    listen 80;
#
#    allow 192.168.1.0/24;
#    allow 68.49.57.165;
#    deny all;
#
#    location / {
#        proxy_pass http://consul-red;
#        proxy_http_version 1.1;
#        proxy_set_header Upgrade $http_upgrade;
#        proxy_set_header Connection "Upgrade";
#        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
#        proxy_set_header X-Forwarded-Proto $scheme;
#        proxy_set_header X-Forwarded-Port $server_port;
#        proxy_set_header X-Forwarded-Host $host;
#        proxy_redirect off;
#        proxy_connect_timeout 90s;
#        proxy_read_timeout 90s;
#        proxy_send_timeout 90s;
#    }
#
#}

upstream fabio-lb {
{{ range service "fabio-lb" }}
  server {{ .Address }}:{{ .Port }};
{{ else }}
  server 127.0.0.1:65535; # force a 502
{{ end }}
}

upstream nginx-frontend {
{{ range service "nginx-frontend" }}
  server {{ .Address }}:{{ .Port }};
{{ else }}
  server 127.0.0.1:65535; # force a 502
{{ end }}
}

server {
    server_name lostcities.app www.lostcities.app;
    listen 80;
    root  /opt/lostcities/frontend;

    #include /etc/nginx/mime.types;

    location /api {
        proxy_pass http://fabio-lb;
        proxy_http_version 1.1;

        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Port $server_port;
        proxy_set_header X-Forwarded-Host $host;
        proxy_redirect off;
        proxy_connect_timeout 90s;
        proxy_read_timeout 90s;
        proxy_send_timeout 90s;
    }

    location /management {
        proxy_pass http://fabio-lb;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Port $server_port;
        proxy_set_header X-Forwarded-Host $host;
        proxy_redirect off;
        proxy_connect_timeout 90s;
        proxy_read_timeout 90s;
        proxy_send_timeout 90s;
    }

    location / {
        proxy_pass http://nginx-frontend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Port $server_port;
        proxy_set_header X-Forwarded-Host $host;
        proxy_redirect off;
        proxy_connect_timeout 90s;
        proxy_read_timeout 90s;
        proxy_send_timeout 90s;
    }
}

EOF

        destination   = "local/load-balancer.conf"
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }
    }
  }

  update {
    max_parallel     = 2
    min_healthy_time = "5s"
    healthy_deadline = "3m"
    auto_revert      = true
    canary           = 1
    auto_promote     = true
  }
}


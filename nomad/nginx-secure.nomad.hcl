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

job "nginx-secure" {
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

  group "nginx-secure" {
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
        to = 443
      }

    }

    service {
      name = "nginx-secure"
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
          "local:/etc/nginx/conf.d",
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

upstream loadbalancer {
{{ range service "fabio-lb" }}
  server {{ .Address }}:{{ .Port }};
{{ else }}
  server 127.0.0.1:65535; # force a 502
{{ end }}
}

server {
    server_name lostcities.app www.lostcities.app;

    location /management {
        allow 192.168.1.0/24;
        allow 68.49.57.165;
        deny all;

        proxy_pass http://loadbalancer;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        #proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Port $server_port;
        proxy_set_header X-Forwarded-Host $host;
        proxy_redirect off;
        proxy_connect_timeout 90s;
        proxy_read_timeout 90s;
        proxy_send_timeout 90s;
        #proxy_timeout 3s;
    }

    location / {
        proxy_pass http://loadbalancer;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        #proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Port $server_port;
        proxy_set_header X-Forwarded-Host $host;
        proxy_redirect off;
        proxy_connect_timeout 90s;
        proxy_read_timeout 90s;
        proxy_send_timeout 90s;
        #proxy_timeout 3s;
    }

    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/nginx/keys/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/nginx/keys/privkey.pem; # managed by Certbot
    include /etc/nginx/keys/ssl.conf; # managed by Certbot
    ssl_dhparam /etc/nginx/keys/ssl-dhparams.pem; # managed by Certbot
}

server {
    if ($host = www.lostcities.app) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


    if ($host = lostcities.app) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


    listen 80 ;
    server_name lostcities.app www.lostcities.app;
    return 404; # managed by Certbot




}

server {
    if ($host = consul-blue.lostcities.app) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


    listen 80;
    server_name consul-blue.lostcities.app;
    return 404; # managed by Certbot


}

server {
    if ($host = consul-green.lostcities.app) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


    listen 80;
    server_name consul-green.lostcities.app;
    return 404; # managed by Certbot


}

server {
    if ($host = consul-red.lostcities.app) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


    listen 80;
    server_name consul-red.lostcities.app;
    return 404; # managed by Certbot


}

server {
    if ($host = dashboard.lostcities.app) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


    listen 80;
    server_name dashboard.lostcities.app;
    return 404; # managed by Certbot


}

server {
    if ($host = grafana.lostcities.app) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


    listen 80;
    server_name grafana.lostcities.app;
    return 404; # managed by Certbot


}

server {
    if ($host = nomad-blue.lostcities.app) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


    listen 80;
    server_name nomad-blue.lostcities.app;
    return 404; # managed by Certbot


}

server {
    if ($host = nomad-green.lostcities.app) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


    listen 80;
    server_name nomad-green.lostcities.app;
    return 404; # managed by Certbot


}

server {
    if ($host = prometheus.lostcities.app) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


    listen 80;
    server_name prometheus.lostcities.app;
    return 404; # managed by Certbot


}

server {
    if ($host = prometheus-agent.lostcities.app) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


    listen 80;
    server_name prometheus-agent.lostcities.app;
    return 404; # managed by Certbot


}



server {
    if ($host = rabbitmq.lostcities.app) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


    listen 80;
    server_name rabbitmq.lostcities.app;
    return 404; # managed by Certbot


}

server {
    if ($host = uptime.lostcities.app) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


    listen 80;
    server_name uptime.lostcities.app;
    return 404; # managed by Certbot


}

EOF

        destination   = "local/load-balancer.conf"
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }
    }
  }
}


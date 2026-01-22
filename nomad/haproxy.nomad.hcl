job "haproxy" {
  region      = "global"
  datacenters = [ "tower-datacenter" ]
  type        = "service"

  group "haproxy" {
    count = 1

    constraint {
      attribute = "${node.unique.name}"
      value     = "nomad-tower-red"
    }

    network {
      port "https" {
        static = 443
        to = 4433
      }

      port "haproxy-ui" {
        static = 1936
      }
    }
    service {
      name = "haproxy"
      port     = "haproxy-ui"
      check {
        name     = "alive"
        type     = "tcp"
        port     = "https"
        interval = "10s"
        timeout  = "2s"
      }
    }

    service {
      name = "haproxy"
      port     = "https"
    }

    task "haproxy" {
      driver = "podman"

      config {
        image        = "docker.io/library/haproxy:3.1.0-alpine"
        network_mode = "host"
        ports = ["haproxy-ui", "https"]
        sysctl = {
          //"net.ipv4.ip_unprivileged_port_start" = "443"
        }
        volumes = [
          "local/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg",
        ]
      }

      template {
        data = <<EOF
defaults
   mode tcp
   timeout connect 5s
   timeout client 1m
   timeout server 1m

frontend stats
   mode http
   bind *:1936
   stats uri /
   stats show-legends
   no log

frontend lb
    # receives traffic from clients
    bind :4433
    mode tcp
    option tcplog
    default_backend nginx

backend nginx
    mode tcp
    retries 3
{{- range service "nginx-ingress-secure" }}
    server {{.Name}}-{{ .Port }} {{ .Address }}:{{ .Port }}
{{- end }}


EOF

        destination = "local/haproxy.cfg"
      }

      resources {
        cpu    = 200
        memory = 128
      }
    }

    update {
      max_parallel     = 1
      min_healthy_time = "5s"
      healthy_deadline = "3m"
      auto_revert      = true
      canary           = 1
      auto_promote     = true
    }
  }
}

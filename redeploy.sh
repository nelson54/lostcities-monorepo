nomad job run -address=http://192.168.1.233:4646 "./nomad/lostcities/postgres.nomad" &
nomad job run -address=http://192.168.1.233:4646 "./nomad/lostcities/rabbitmq.nomad" &
nomad job run -address=http://192.168.1.233:4646 "./nomad/lostcities/redis.nomad" &
nomad job run -address=http://192.168.1.233:4646 "./nomad/fabio-lb.hcl" &
nomad job run -address=http://192.168.1.233:4646 "./nomad/loki.hcl" &
nomad job run -address=http://192.168.1.233:4646 "./nomad/prometheus-query.nomad.hcl" &
nomad job run -address=http://192.168.1.233:4646 "./nomad/prometheus-discovery-agent.nomad.hcl"  &
nomad job run -address=http://192.168.1.233:4646 "./nomad/grafana.hcl" &
nomad job run -address=http://192.168.1.233:4646 "../lostcities-accounts/nomad.hcl" &
nomad job run -address=http://192.168.1.233:4646 "../lostcities-matches/nomad.hcl" &
nomad job run -address=http://192.168.1.233:4646 "../lostcities-gamestate/nomad.hcl" &
nomad job run -address=http://192.168.1.233:4646 "../lostcities-player-events/nomad.hcl" &
nomad job run -address=http://192.168.1.233:4646 "./nomad/lostcities/nginx-frontend.nomad.hcl" &
nomad job run -address=http://192.168.1.233:4646 "./nomad/otel-collector.nomad.hcl" &

nomad job run -address=http://192.168.1.233:4646 "./nomad/nginx-router.nomad.hcl" &
nomad job run -address=http://192.168.1.233:4646 "./nomad/nginx-ingress.nomad.hcl" &
nomad job run -address=http://192.168.1.233:4646 "./nomad/promtail.hcl" &
nomad job run -address=http://192.168.1.233:4646 "./nomad/uptime-kuma.nomad.hcl" &
nomad job run -address=http://192.168.1.233:4646 "./nomad/dashboard.nomad.hcl" &
nomad job run -address=http://192.168.1.233:4646 "./nomad/cadvisor.nomad.hcl" &


nomad job inspect -address=http://192.168.1.233:4646 -t '{{range services "*"}}{{if eq .Namespace ""}}{{ println .Name}}{{end}}{{end}}'

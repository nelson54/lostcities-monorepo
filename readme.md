Future changes:
- JWT token needs a public key
- Load test ai matches
- User game history page
- Store completed games
-

etcd commands
```bash
etcdctl put /services/example-service/random-id-1  localhost:8080

```

# Internal links
Applications:

- http://localhost:8080/api/accounts/swagger-ui/api-docs.html
- http://localhost:8081/api/matches
- http://localhost:8082/api/gamestate
- http://localhost:8083/api/player-events

- Management:

- http://localhost:4450/management/accounts
- http://localhost:4453/management/matches
- http://localhost:4454/management/gamestate
- http://localhost:4455/management/player-events

- Swagger
  - http://localhost:4450/management/accounts/actuator/swagger-ui/index.html
  - http://localhost:4453/management/matches/actuator/swagger-ui/index.html
  - http://localhost:4454/management/gamestate/actuator/swagger-ui/index.html
  - http://localhost:4455/management/player-events/actuator/swagger-ui/index.html


```
192.168.1.233 lostcities.dev www.lostcities.dev

192.168.1.233 dashboard.lostcities.dev
192.168.1.233 grafana.lostcities.dev fabio.lostcities.dev rabbitmq.lostcities.dev
192.168.1.233 prometheus-agent.lostcities.dev promethues-query.lostcities.dev
192.168.1.233 nomad-blue.lostcities.dev nomad-green.lostcities.dev nomad-red.lostcities.dev
192.168.1.233 consul-blue.lostcities.dev consul-green.lostcities.dev consul-red.lostcities.dev

```

```bash
# finding disk usage issue
cd /
sudo apt install ncdu
ncdu

```

```bash
sudo podman volume prune --force
sudo podman container prune --force
sudo podman image prune --force
```


```bash
#/etc/logrotate.conf
/var/log/consul/* {
        su consul consul
        daily
        rotate 2
        compress
        missingok
}
```


```bash
# To enable memory oversubscription


export NOMAD_ADDR=http://127.0.0.1:4646
sudo apt -y install jq
curl -s $NOMAD_ADDR/v1/operator/scheduler/configuration | \
jq '.SchedulerConfig | .MemoryOversubscriptionEnabled=true' | \
curl -X PUT $NOMAD_ADDR/v1/operator/scheduler/configuration -d @-
```

```bash
sudo systemctl stop nomad
sudo rm -rf /opt/nomad/**
sudo apt-get update && sudo apt-get -y upgrade && sudo apt-get install --reinstall -y nomad-driver-podman

nomad namespace apply -description "Lost-Cities jobs" lostcities

```

```bash
# Determine docker image size

function imagesize () {
  docker pull $1
  docker inspect -f "{{ .Size }}" $1 | numfmt --to=si
}

docker.io/fabiolb/fabio
```

Reset nomad and consul
```bash
sudo systemctl stop nomad
sudo systemctl stop consul

sudo rm -rf /opt/nomad/** /opt/consul/**

sudo apt-get update && sudo apt-get -y upgrade

sudo apt-get install --reinstall -y nomad-driver-podman
sudo apt -y install jq

sudo systemctl start consul
sudo systemctl start nomad

sleep 15
export NOMAD_ADDR=http://127.0.0.1:4646

curl -s $NOMAD_ADDR/v1/operator/scheduler/configuration | \
jq '.SchedulerConfig | .MemoryOversubscriptionEnabled=true' | \


curl -X PUT $NOMAD_ADDR/v1/operator/scheduler/configuration -d @-



nomad namespace apply -description "Lost-Cities jobs" lostcities

```



# Lostcities Monorepo

Type:
- 🔒 - Auth
- 🎨 - Experience
- 👾 - Gameplay
- 🌱 - Reduce resources
- 🏎️ - Performance
- 🚧 - Maintenance
- 🧪 - Testing 
- 🔬 - Investigation
- 📄 - Documentation

Priority: 
🔴 - High
🟠 - Medium
🟢 - Low

Todo:
- [ ] 📄: 🟠 Update dashboard to include links to actuator
- [ ] 🔒: 🔴 Accounts - Public key must be persisted
- [ ] 🔒: 🔴 Accounts - Auth public and private keys should expire
- [ ] 🔒: 🟠 Accounts - Create method to refresh expiring token
- [ ] 🌱: 🟠 Gamestate - remove actuator, add push gateway
- [ ] 🧪: 🔴 Unit test Jackson serialization for PlayerView Dtos
- [ ] 🌱: 🔴 Matches - Create a rabbit queue for Matchmaking
- [ ] 🚧: 🔴 Matches - Create rabbit exchanges and migrate to new queues with routing key
- [ ] 🚧: 🔴 UserEvents - Create rabbit fan out exchange and new queues per service
- [ ] 🎨: 🟠 Matches - Send matchmaking event to Player Events
- [ ] 🚧: 🟠 Spring upgrade
  - [ ] 🚧: 🟠 3.2 to 3.3
  - [ ] 🚧: 🟢 3.3 to 3.4
  - [ ] 🚧: 🟢 3.5 to 4
- [ ] 🔒: 🟢 Front end - Should be able to view token and check for expiration
- [ ] 🔒: 🟢 Front end - Should periodically check for key to expire
- [ ] 🔬: 🟢 Investigate native builds
- [ ] 🚧: 🟢 Remove Hibernate and use JPA exclusively
- [ ] 🚧: 🟢 Create Docker images and new dev environment that runs docker images
- [x] 🔒: 🔴 Accounts - Expose public key over http
- [x] 🔒: 🔴 Services should get public key from Accounts http endpoint
- [x] 🌱: 🔴 Gamestate - Move to a cloud function
- [x] 🏎️: 🟠 Gamestate - Move messages from json to protobuf
- [x] 🏎️: 🟠 Gamestate - Move to a Postgres
- [x] 🚧: 🟢 UserEvents - Rename from PlayerEvents

 
- Load test ai matches
- Use constants in authorization dsl annotation values
- User game history page
- Store completed games

Remove hibernate for creating database:
```
spring.jpa.properties.jakarta.persistence.schema-generation.scripts.action=create
spring.jpa.properties.jakarta.persistence.schema-generation.scripts.create-target=create.sql
spring.jpa.properties.jakarta.persistence.schema-generation.scripts.create-source=metadata
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



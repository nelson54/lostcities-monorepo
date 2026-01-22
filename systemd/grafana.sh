mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor > /etc/apt/keyrings/grafana.gpg
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | tee /etc/apt/sources.list.d/grafana.list
apt update
apt install promtail

useradd --system promtail
usermod -a -G adm promtail

mkdir -p /etc/promtail

vim /etc/systemd/system/promtail.service
vim /etc/promtail/promtail.yaml

chown promtail:promtail /etc/promtail
chown promtail:promtail /etc/promtail/promtail.yaml

service promtail start
service promtail status

systemctl enable promtail.service

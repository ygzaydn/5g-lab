#!/bin/bash

fuser -k 3868/tcp 8080/tcp || true
pkill -9 python3 || true
redis-server --daemonize yes
pip install gunicorn gevent --quiet
sysctl -w net.core.somaxconn=4096
sysctl -w net.ipv4.tcp_max_syn_backlog=4096
sysctl -w net.ipv4.ip_local_port_range="1024 65535"
sysctl -w net.ipv4.tcp_slow_start_after_idle=0

cd services

gunicorn --worker-class gevent --workers 4 --threads 100 --bind ${PYHSS_IP}:8080 apiService:apiService &

sleep 5

python3 diameterService.py &
sleep 5

echo "PyHSS HSS servisi yüksek performans modunda ba�~_latılıyor..."

python3 hssService.py $@


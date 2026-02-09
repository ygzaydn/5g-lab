#!/bin/bash

while ! mysqladmin ping -h ${MYSQL_IP} -u root -p${MYSQL_ROOT_PASSWORD} --silent; do
    sleep 5
done

mysql -u root -p${MYSQL_ROOT_PASSWORD} -h ${MYSQL_IP} -e "CREATE USER IF NOT EXISTS 'pyhss'@'%' IDENTIFIED WITH mysql_native_password BY 'ims_db_pass';"
mysql -u root -p${MYSQL_ROOT_PASSWORD} -h ${MYSQL_IP} -e "GRANT ALL PRIVILEGES ON *.* TO 'pyhss'@'%' WITH GRANT OPTION;"
mysql -u root -p${MYSQL_ROOT_PASSWORD} -h ${MYSQL_IP} -e "FLUSH PRIVILEGES;"

[ ${#MNC} == 3 ] && EPC_DOMAIN="epc.mnc${MNC}.mcc${MCC}.3gppnetwork.org" || EPC_DOMAIN="epc.mnc0${MNC}.mcc${MCC}.3gppnetwork.org"
[ ${#MNC} == 3 ] && IMS_DOMAIN="ims.mnc${MNC}.mcc${MCC}.3gppnetwork.org" || IMS_DOMAIN="ims.mnc0${MNC}.mcc${MCC}.3gppnetwork.org"

cp /mnt/pyhss/config.yaml /pyhss/config.yaml
cp /mnt/pyhss/default_ifc.xml /pyhss/default_ifc.xml
cp /mnt/pyhss/default_sh_user_data.xml /pyhss/default_sh_user_data.xml

sed -i "s|PYHSS_IP|$PYHSS_IP|g" /pyhss/config.yaml
sed -i "s|PYHSS_BIND_PORT|$PYHSS_BIND_PORT|g" /pyhss/config.yaml
sed -i "s|IMS_DOMAIN|$IMS_DOMAIN|g" /pyhss/config.yaml
sed -i "s|OP_MCC|$MCC|g" /pyhss/config.yaml
sed -i "s|OP_MNC|$MNC|g" /pyhss/config.yaml
sed -i "s|MYSQL_IP|$MYSQL_IP|g" /pyhss/config.yaml
sed -i "s|INSTALL_PREFIX|/pyhss|g" /pyhss/config.yaml

pkill -9 python3 || true
pkill -9 redis-server || true
sleep 2

mkdir -p /var/run/redis && chmod 777 /var/run/redis
redis-server --unixsocket /var/run/redis/redis-server.sock --unixsocketperm 777 --daemonize yes

until [ -S /var/run/redis/redis-server.sock ]; do
  sleep 1
done

export PYHSS_CONFIG=/pyhss/config.yaml

cd /pyhss/services

python3 apiService.py --host=$PYHSS_IP --port=8080 &
sleep 2
python3 diameterService.py &
sleep 2

exec python3 hssService.py $@

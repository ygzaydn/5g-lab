#!/bin/bash

[ ${#MNC} == 3 ] && IMS_DOMAIN="ims.mnc${MNC}.mcc${MCC}.3gppnetwork.org" || IMS_DOMAIN="ims.mnc0${MNC}.mcc${MCC}.3gppnetwork.org"
IMS_SLASH_DOMAIN=$(echo $IMS_DOMAIN | sed 's/\./\\./g')

mkdir -p /etc/kamailio_scscf
cp /mnt/scscf/* /etc/kamailio_scscf/
cd /etc/kamailio_scscf/

sed -i "s|SCSCF_IP|$SCSCF_IP|g" *.cfg *.xml
sed -i "s|MYSQL_IP|$MYSQL_IP|g" *.cfg *.xml
sed -i "s|IMS_DOMAIN|$IMS_DOMAIN|g" *.cfg *.xml
sed -i "s|IMS_SLASH_DOMAIN|$IMS_SLASH_DOMAIN|g" *.cfg *.xml
sed -i "s|PYHSS_BIND_PORT|3868|g" scscf.xml
sed -i "s|SCSCF_BIND_PORT|3868|g" scscf.xml

sed -i 's|#!define DB_URL .*|#!define DB_URL "mysql://scscf:imspass@'$MYSQL_IP'/scscf"|' scscf.cfg

echo "MySQL Bekleniyor..."
while ! mysqladmin ping -h ${MYSQL_IP} -uroot -p$MYSQL_PWD --silent; do sleep 2; done

echo "Veritabanı ve Tablolar hazırlanıyor..."
mysql -u root -p$MYSQL_PWD -h ${MYSQL_IP} -e "CREATE DATABASE IF NOT EXISTS scscf;"
mysql -u root -p$MYSQL_PWD -h ${MYSQL_IP} -e "CREATE USER IF NOT EXISTS 'scscf'@'%' IDENTIFIED BY 'imspass';"
mysql -u root -p$MYSQL_PWD -h ${MYSQL_IP} -e "GRANT ALL PRIVILEGES ON scscf.* TO 'scscf'@'%'; FLUSH PRIVILEGES;"

mysql -u root -p$MYSQL_PWD -h ${MYSQL_IP} scscf < /etc/kamailio_scscf/standard-create.sql
mysql -u root -p$MYSQL_PWD -h ${MYSQL_IP} scscf < /etc/kamailio_scscf/presence-create.sql
mysql -u root -p$MYSQL_PWD -h ${MYSQL_IP} scscf < /etc/kamailio_scscf/ims_usrloc_scscf-create.sql

if [ -f /usr/local/src/kamailio/utils/kamctl/mysql/ims_dialog-create.sql ]; then
    mysql -u root -p$MYSQL_PWD -h ${MYSQL_IP} scscf < /usr/local/src/kamailio/utils/kamctl/mysql/ims_dialog-create.sql
fi

echo "$PYHSS_IP hss.$IMS_DOMAIN" >> /etc/hosts
echo "$ICSCF_IP icscf.$IMS_DOMAIN" >> /etc/hosts
echo "$SCSCF_IP scscf.$IMS_DOMAIN" >> /etc/hosts
echo "$PCSCF_IP pcscf.$IMS_DOMAIN" >> /etc/hosts


mkdir -p /var/run/kamailio
exec kamailio -f /etc/kamailio_scscf/kamailio_scscf.cfg -P /var/run/kamailio/scscf.pid -DD -E -e $@

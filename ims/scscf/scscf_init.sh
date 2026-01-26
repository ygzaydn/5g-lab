#!/bin/bash

[ ${#MNC} == 3 ] && IMS_DOMAIN="ims.mnc${MNC}.mcc${MCC}.3gppnetwork.org" || IMS_DOMAIN="ims.mnc0${MNC}.mcc${MCC}.3gppnetwork.org"
IMS_SLASH_DOMAIN=$(echo $IMS_DOMAIN | sed 's/\./\\./g')

mkdir -p /etc/kamailio_scscf
cp /mnt/scscf/* /etc/kamailio_scscf/

cd /etc/kamailio_scscf/
# Yer tutucuları değiştir
sed -i "s|SCSCF_IP|$SCSCF_IP|g" *.cfg *.xml
sed -i "s|MYSQL_IP|$MYSQL_IP|g" *.cfg *.xml
sed -i "s|IMS_DOMAIN|$IMS_DOMAIN|g" *.cfg *.xml
sed -i "s|IMS_SLASH_DOMAIN|$IMS_SLASH_DOMAIN|g" *.cfg *.xml

# Senin belirlediğin portları XML'e yaz (Diameter Standart: 3868)
sed -i "s|PYHSS_BIND_PORT|3868|g" scscf.xml
sed -i "s|SCSCF_BIND_PORT|3868|g" scscf.xml

# DB URL'i Secret ve MySQL Init ile eşitle
sed -i 's|#!define DB_URL .*|#!define DB_URL "mysql://scscf:imspass@'$MYSQL_IP'/scscf"|' scscf.cfg

echo "MySQL Bekleniyor..."
while ! mysqladmin ping -h ${MYSQL_IP} -uroot -p${MYSQL_PWD} --silent; do sleep 2; done

echo "SCSCF Tabloları yükleniyor..."
mysql -u root -h ${MYSQL_IP} -p${MYSQL_PWD} scscf < /usr/local/src/kamailio/utils/kamctl/mysql/standard-create.sql 2>/dev/null || true
mysql -u root -h ${MYSQL_IP} -p${MYSQL_PWD} scscf < /usr/local/src/kamailio/utils/kamctl/mysql/ims_usrloc_scscf-create.sql 2>/dev/null || true

mkdir -p /var/run/kamailio
exec kamailio -f /etc/kamailio_scscf/kamailio_scscf.cfg -P /var/run/kamailio/scscf.pid -DD -E

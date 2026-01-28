#!/bin/bash

[ ${#MNC} == 3 ] && IMS_DOMAIN="ims.mnc${MNC}.mcc${MCC}.3gppnetwork.org" || IMS_DOMAIN="ims.mnc0${MNC}.mcc${MCC}.3gppnetwork.org"

mkdir -p /etc/kamailio_icscf
cp /mnt/icscf/icscf.cfg /etc/kamailio_icscf
cp /mnt/icscf/icscf.xml /etc/kamailio_icscf
cp /mnt/icscf/kamailio_icscf.cfg /etc/kamailio_icscf

echo "MySQL'e bağlanmaya çalışılıyor: ${MYSQL_IP}..."
while ! mysqladmin ping -h ${MYSQL_IP} -u root -p"${MYSQL_PWD}" --silent; do
    sleep 5
done

if [[ -z "$(mysql -u root -p${MYSQL_PWD} -h ${MYSQL_IP} -qfsBe "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME='icscf'" 2>&1)" ]]; then
    echo "ICSCF veritabanı oluşturuluyor..."
    mysql -u root -p${MYSQL_PWD} -h ${MYSQL_IP} -e "CREATE DATABASE icscf;"
    
    if [ -f /mnt/icscf/icscf.sql ]; then
        echo "Tablolar /mnt/icscf/icscf.sql üzerinden yükleniyor..."
        mysql -u root -p${MYSQL_PWD} -h ${MYSQL_IP} icscf < /mnt/icscf/icscf.sql
    fi

    mysql -u root -p${MYSQL_PWD} -h ${MYSQL_IP} -e "CREATE USER IF NOT EXISTS 'icscf'@'%' IDENTIFIED BY 'imspass';"
    mysql -u root -p${MYSQL_PWD} -h ${MYSQL_IP} -e "GRANT ALL ON icscf.* TO 'icscf'@'%';"
    mysql -u root -p${MYSQL_PWD} -h ${MYSQL_IP} -e "FLUSH PRIVILEGES;"
fi

SUBSCRIPTION_EXPIRES_ENV=603600

sed -i "s|UE_SUBSCRIPTION_EXPIRES|3600|g" /etc/kamailio_icscf/kamailio_icscf.cfg
sed -i "s|ICSCF_IP|$ICSCF_IP|g" /etc/kamailio_icscf/*.cfg /etc/kamailio_icscf/*.xml
sed -i "s|IMS_DOMAIN|$IMS_DOMAIN|g" /etc/kamailio_icscf/*.cfg /etc/kamailio_icscf/*.xml
sed -i "s|MYSQL_IP|$MYSQL_IP|g" /etc/kamailio_icscf/*.cfg /etc/kamailio_icscf/*.xml
sed -i "s|PYHSS_BIND_PORT|$PYHSS_BIND_PORT|g" /etc/kamailio_icscf/*.xml
sed -i "s|ICSCF_BIND_PORT|$ICSCF_BIND_PORT|g" /etc/kamailio_icscf/*.xml

echo "${PYHSS_IP} hss.${IMS_DOMAIN}" >> /etc/hosts
echo "${SCSCF_IP} scscf.${IMS_DOMAIN}" >> /etc/hosts
echo "${PCSCF_IP} pcscf.${IMS_DOMAIN}" >> /etc/hosts
echo "${ICSCF_IP} icscf.${IMS_DOMAIN}" >> /etc/hosts


mkdir -p /var/run/kamailio_icscf
rm -f /kamailio_icscf.pid
exec kamailio -f /etc/kamailio_icscf/kamailio_icscf.cfg -P /kamailio_icscf.pid -DD -E -e $@

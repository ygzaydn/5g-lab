#!/bin/bash

sh -c "echo 1 > /proc/sys/net/ipv4/ip_nonlocal_bind"
sh -c "echo 1 > /proc/sys/net/ipv6/ip_nonlocal_bind"

apt-get update && apt-get install -y iproute2 mysql-client

[ ${#MNC} == 3 ] && IMS_DOMAIN="ims.mnc${MNC}.mcc${MCC}.3gppnetwork.org" || IMS_DOMAIN="ims.mnc0${MNC}.mcc${MCC}.3gppnetwork.org"
[ ${#MNC} == 3 ] && EPC_DOMAIN="epc.mnc${MNC}.mcc${MCC}.3gppnetwork.org" || EPC_DOMAIN="epc.mnc0${MNC}.mcc${MCC}.3gppnetwork.org"

mkdir -p /etc/kamailio_pcscf/route
mkdir -p /etc/kamailio_pcscf/sems/etc

cp /mnt/pcscf/pcscf.cfg /etc/kamailio_pcscf/
cp /mnt/pcscf/pcscf.xml /etc/kamailio_pcscf/
cp /mnt/pcscf/kamailio_pcscf.cfg /etc/kamailio_pcscf/
cp /mnt/pcscf/tls.cfg /etc/kamailio_pcscf/
cp /mnt/pcscf/dispatcher.list /etc/kamailio_pcscf/

cp /mnt/pcscf/route_mo.cfg /etc/kamailio_pcscf/route/mo.cfg
cp /mnt/pcscf/route_mt.cfg /etc/kamailio_pcscf/route/mt.cfg
cp /mnt/pcscf/route_register.cfg /etc/kamailio_pcscf/route/register.cfg
cp /mnt/pcscf/route_rtp.cfg /etc/kamailio_pcscf/route/rtp.cfg
cp /mnt/pcscf/route_websocket.cfg /etc/kamailio_pcscf/route/websocket.cfg
cp /mnt/pcscf/route_xmlrpc.cfg /etc/kamailio_pcscf/route/xmlrpc.cfg

cp /mnt/pcscf/sems.conf /etc/kamailio_pcscf/sems/sems.conf
cp /mnt/pcscf/sems_etc_methodmap.conf /etc/kamailio_pcscf/sems/etc/methodmap.conf
cp /mnt/pcscf/sems_etc_monitoring.conf /etc/kamailio_pcscf/sems/etc/monitoring.conf
cp /mnt/pcscf/sems_etc_mo.sbcprofile.conf /etc/kamailio_pcscf/sems/etc/mo.sbcprofile.conf
cp /mnt/pcscf/sems_etc_mt.sbcprofile.conf /etc/kamailio_pcscf/sems/etc/mt.sbcprofile.conf
cp /mnt/pcscf/sems_etc_nocache.sbcprofile.conf /etc/kamailio_pcscf/sems/etc/nocache.sbcprofile.conf
cp /mnt/pcscf/sems_etc_refuse.sbcprofile.conf /etc/kamailio_pcscf/sems/etc/refuse.sbcprofile.conf
cp /mnt/pcscf/sems_etc_refuse_with_200.sbcprofile.conf /etc/kamailio_pcscf/sems/etc/refuse_with_200.sbcprofile.conf
cp /mnt/pcscf/sems_etc_register.sbcprofile.conf /etc/kamailio_pcscf/sems/etc/register.sbcprofile.conf
cp /mnt/pcscf/sems_etc_rurimap.conf /etc/kamailio_pcscf/sems/etc/rurimap.conf
cp /mnt/pcscf/sems_etc_sbc.conf /etc/kamailio_pcscf/sems/etc/sbc.conf
cp /mnt/pcscf/sems_etc_stats.conf /etc/kamailio_pcscf/sems/etc/stats.conf
cp /mnt/pcscf/sems_etc_xmlrpc2di.conf /etc/kamailio_pcscf/sems/etc/xmlrpc2di.conf

while ! mysqladmin ping -h ${MYSQL_IP} -u root -p"${MYSQL_ROOT_PASSWORD}" --silent; do
    sleep 5;
done
sleep 10;

if [[ -z "`mysql -u root -h ${MYSQL_IP} -qfsBe "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME='pcscf'" 2>&1`" ]];
then
    mysql -u root -h ${MYSQL_IP} -e "create database pcscf;"
    mysql -u root -h ${MYSQL_IP} pcscf < /usr/local/src/kamailio/utils/kamctl/mysql/standard-create.sql
    mysql -u root -h ${MYSQL_IP} pcscf < /usr/local/src/kamailio/utils/kamctl/mysql/presence-create.sql
    mysql -u root -h ${MYSQL_IP} pcscf < /usr/local/src/kamailio/utils/kamctl/mysql/ims_usrloc_pcscf-create.sql
    mysql -u root -h ${MYSQL_IP} pcscf < /usr/local/src/kamailio/utils/kamctl/mysql/ims_dialog-create.sql
    PCSCF_USER_EXISTS=`mysql -u root -h ${MYSQL_IP} -s -N -e "SELECT EXISTS(SELECT 1 FROM mysql.user WHERE User = 'pcscf' AND Host = '%')"`
    if [[ "$PCSCF_USER_EXISTS" == 0 ]]
    then
        mysql -u root -h ${MYSQL_IP} -e "CREATE USER 'pcscf'@'%' IDENTIFIED WITH mysql_native_password BY 'heslo'";
        mysql -u root -h ${MYSQL_IP} -e "GRANT ALL ON pcscf.* TO 'pcscf'@'%'";
        mysql -u root -h ${MYSQL_IP} -e "FLUSH PRIVILEGES;"
    fi
fi

if [[ ${DEPLOY_MODE} == 5G ]];
then
    sed -i 's|#!define WITH_RX\b|##!define WITH_RX|g' /etc/kamailio_pcscf/pcscf.cfg
fi

SUBSCRIPTION_EXPIRES_ENV=603600

sed -i "s|PCSCF_IP|$PCSCF_IP|g" /etc/kamailio_pcscf/pcscf.cfg
sed -i "s|SUBSCRIPTION_EXPIRES_ENV|$SUBSCRIPTION_EXPIRES_ENV|g" /etc/kamailio_pcscf/pcscf.cfg
sed -i "s|SCP_IP|$SCP_IP|g" /etc/kamailio_pcscf/pcscf.cfg
sed -i "s|PCSCF_PUB_IP|$PCSCF_PUB_IP|g" /etc/kamailio_pcscf/pcscf.cfg
sed -i "s|IMS_DOMAIN|$IMS_DOMAIN|g" /etc/kamailio_pcscf/pcscf.cfg
sed -i "s|EPC_DOMAIN|$EPC_DOMAIN|g" /etc/kamailio_pcscf/pcscf.cfg
sed -i "s|MYSQL_IP|$MYSQL_IP|g" /etc/kamailio_pcscf/pcscf.cfg

sed -i "s|PCSCF_IP|$PCSCF_IP|g" /etc/kamailio_pcscf/pcscf.xml
sed -i "s|SUBSCRIPTION_EXPIRES_ENV|$SUBSCRIPTION_EXPIRES_ENV|g" /etc/kamailio_pcscf/pcscf.xml
sed -i "s|IMS_DOMAIN|$IMS_DOMAIN|g" /etc/kamailio_pcscf/pcscf.xml
sed -i "s|EPC_DOMAIN|$EPC_DOMAIN|g" /etc/kamailio_pcscf/pcscf.xml
sed -i "s|PCRF_BIND_PORT|$PCRF_BIND_PORT|g" /etc/kamailio_pcscf/pcscf.xml
sed -i "s|PCSCF_BIND_PORT|$PCSCF_BIND_PORT|g" /etc/kamailio_pcscf/pcscf.xml

sed -i "s|RTPENGINE_IP|$RTPENGINE_IP|g" /etc/kamailio_pcscf/kamailio_pcscf.cfg
sed -i "s|RTPENGINE_IP|$RTPENGINE_IP|g" /etc/kamailio_pcscf/route/rtp.cfg

ip r add ${UE_IPV4_IMS} via ${UPF_IP}
ip r add ${UE_IPV4_INTERNET} via ${UPF_IP}

echo "10.10.10.62 $IMS_DOMAIN" >> /etc/hosts
echo "10.10.10.62 icscf.$IMS_DOMAIN" >> /etc/hosts
echo "10.10.10.63 scscf.$IMS_DOMAIN" >> /etc/hosts

mkdir -p /var/run/kamailio_pcscf
rm -f /kamailio_pcscf.pid
exec kamailio -f /etc/kamailio_pcscf/kamailio_pcscf.cfg -P /kamailio_pcscf.pid -DD -E -e $@

#!/bin/bash

# MySQL'in hazır olmasını bekle (Root şifresiyle ping atar)
while ! mysqladmin ping -h ${MYSQL_IP} -u root -p${MYSQL_ROOT_PASSWORD} --silent; do
    echo "MySQL henüz hazır değil, bekleniyor..."
    sleep 5;
done

echo "MySQL hazır, yetkilendirme işlemleri başlıyor..."

# PyHSS kullanıcısını oluştur ve yetki ver (MySQL 8 uyumlu)
mysql -u root -p${MYSQL_ROOT_PASSWORD} -h ${MYSQL_IP} -e "CREATE USER IF NOT EXISTS 'pyhss'@'%' IDENTIFIED WITH mysql_native_password BY 'ims_db_pass';"
mysql -u root -p${MYSQL_ROOT_PASSWORD} -h ${MYSQL_IP} -e "GRANT ALL PRIVILEGES ON *.* TO 'pyhss'@'%' WITH GRANT OPTION;"
mysql -u root -p${MYSQL_ROOT_PASSWORD} -h ${MYSQL_IP} -e "FLUSH PRIVILEGES;"

# Domain ayarları
[ ${#MNC} == 3 ] && EPC_DOMAIN="epc.mnc${MNC}.mcc${MCC}.3gppnetwork.org" || EPC_DOMAIN="epc.mnc0${MNC}.mcc${MCC}.3gppnetwork.org"
[ ${#MNC} == 3 ] && IMS_DOMAIN="ims.mnc${MNC}.mcc${MCC}.3gppnetwork.org" || IMS_DOMAIN="ims.mnc0${MNC}.mcc${MCC}.3gppnetwork.org"

cp /mnt/pyhss/config.yaml ./
cp /mnt/pyhss/default_ifc.xml ./
cp /mnt/pyhss/default_sh_user_data.xml ./

INSTALL_PREFIX="/pyhss"

# Config.yaml içindeki değişkenleri değiştir
sed -i 's|PYHSS_IP|'$PYHSS_IP'|g' ./config.yaml
sed -i 's|PYHSS_BIND_PORT|'$PYHSS_BIND_PORT'|g' ./config.yaml
sed -i 's|IMS_DOMAIN|'$IMS_DOMAIN'|g' ./config.yaml
sed -i 's|OP_MCC|'$MCC'|g' ./config.yaml
sed -i 's|OP_MNC|'$MNC'|g' ./config.yaml
sed -i 's|MYSQL_IP|'$MYSQL_IP'|g' ./config.yaml
sed -i 's|INSTALL_PREFIX|'$INSTALL_PREFIX'|g' ./config.yaml

# Redis'i başlat (PyHSS bağımlılığı)
redis-server --daemonize yes

cd services
python3 apiService.py --host=$PYHSS_IP --port=8080 &
sleep 5
python3 diameterService.py &
sleep 5
echo "PyHSS HSS servisi başlatılıyor..."
exec python3 hssService.py --debug $@

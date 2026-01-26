#!/bin/bash

cp /mnt/dns/epc_zone /etc/bind
cp /mnt/dns/ims_zone /etc/bind
cp /mnt/dns/pub_3gpp_zone /etc/bind
cp /mnt/dns/e164.arpa /etc/bind
cp /mnt/dns/named.conf /etc/bind

[ ${#MNC} == 3 ] && EPC_DOMAIN="epc.mnc${MNC}.mcc${MCC}.3gppnetwork.org" || EPC_DOMAIN="epc.mnc0${MNC}.mcc${MCC}.3gppnetwork.org"
[ ${#MNC} == 3 ] && IMS_DOMAIN="ims.mnc${MNC}.mcc${MCC}.3gppnetwork.org" || IMS_DOMAIN="ims.mnc0${MNC}.mcc${MCC}.3gppnetwork.org"
[ ${#MNC} == 3 ] && PUB_3GPP_DOMAIN="mnc${MNC}.mcc${MCC}.pub.3gppnetwork.org" || PUB_3GPP_DOMAIN="mnc0${MNC}.mcc${MCC}.pub.3gppnetwork.org"

sed -i 's|EPC_DOMAIN|'$EPC_DOMAIN'|g' /etc/bind/epc_zone
sed -i 's|DNS_IP|'$DNS_IP'|g' /etc/bind/epc_zone
sed -i 's|OSMOEPDG_IP|'$OSMOEPDG_IP'|g' /etc/bind/epc_zone
[ -z "$PCRF_PUB_IP" ] && sed -i 's|PCRF_IP|'$PCRF_IP'|g' /etc/bind/epc_zone || sed -i 's|PCRF_IP|'$PCRF_PUB_IP'|g' /etc/bind/epc_zone

sed -i 's|IMS_DOMAIN|'$IMS_DOMAIN'|g' /etc/bind/ims_zone
sed -i 's|DNS_IP|'$DNS_IP'|g' /etc/bind/ims_zone
sed -i 's|PCSCF_IP|'$PCSCF_IP'|g' /etc/bind/ims_zone
sed -i 's|ICSCF_IP|'$ICSCF_IP'|g' /etc/bind/ims_zone
sed -i 's|SCSCF_IP|'$SCSCF_IP'|g' /etc/bind/ims_zone
sed -i 's|TAS_IP|'$TAS_IP'|g' /etc/bind/ims_zone
sed -i 's|PYHSS_IP|'$PYHSS_IP'|g' /etc/bind/ims_zone
sed -i 's|SMSC_IP|'$SMSC_IP'|g' /etc/bind/ims_zone
sed -i 's|IBCF_IP|'$IBCF_IP'|g' /etc/bind/ims_zone
# Open5GS için eklenenler
sed -i 's|NRF_IP|'$NRF_IP'|g' /etc/bind/ims_zone
sed -i 's|SCP_IP|'$SCP_IP'|g' /etc/bind/ims_zone

sed -i 's|PUB_3GPP_DOMAIN|'$PUB_3GPP_DOMAIN'|g' /etc/bind/pub_3gpp_zone
sed -i 's|DNS_IP|'$DNS_IP'|g' /etc/bind/pub_3gpp_zone
sed -i 's|ENTITLEMENT_SERVER_IP|'$ENTITLEMENT_SERVER_IP'|g' /etc/bind/pub_3gpp_zone
sed -i 's|DOCKER_HOST_IP|'$DOCKER_HOST_IP'|g' /etc/bind/pub_3gpp_zone

sed -i 's|IMS_DOMAIN|'$IMS_DOMAIN'|g' /etc/bind/e164.arpa
sed -i 's|DNS_IP|'$DNS_IP'|g' /etc/bind/e164.arpa

sed -i 's|EPC_DOMAIN|'$EPC_DOMAIN'|g' /etc/bind/named.conf
sed -i 's|IMS_DOMAIN|'$IMS_DOMAIN'|g' /etc/bind/named.conf
sed -i 's|PUB_3GPP_DOMAIN|'$PUB_3GPP_DOMAIN'|g' /etc/bind/named.conf

exec /usr/sbin/named -c /etc/bind/named.conf -g -u bind $@

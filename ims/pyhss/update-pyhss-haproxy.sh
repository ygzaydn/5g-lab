#!/usr/bin/env bash
set -euo pipefail

NS="open5gs"
LABEL="app=pyhss"
VIP="10.10.10.70"
DIAM_BACKEND_PORT="3868"   # Pod içi asıl dinlenen port
API_BACKEND_PORT="8080"

CFG="/etc/haproxy/haproxy.cfg"
TMP="$(mktemp)"

# Running pod IP'leri
IPS=$(
  kubectl -n "$NS" get pods -l "$LABEL" \
    --field-selector=status.phase=Running \
    -o jsonpath='{range .items[*]}{.status.podIP}{"\n"}{end}' \
  | awk 'NF' | sort -u
)

if [[ -z "${IPS// }" ]]; then
  echo "ERROR: Running pyhss pod IP bulunamadı." >&2
  exit 1
fi

BLK="### BEGIN PYHSS AUTOGEN
# managed by update-pyhss-haproxy.sh

frontend ft_pyhss_diameter_3868
  bind ${VIP}:3868
  mode tcp
  option tcplog
  default_backend bk_pyhss_diameter

frontend ft_pyhss_diameter_3870
  bind ${VIP}:3870
  mode tcp
  option tcplog
  default_backend bk_pyhss_diameter

frontend ft_pyhss_diameter_3872
  bind ${VIP}:3872
  mode tcp
  option tcplog
  default_backend bk_pyhss_diameter

backend bk_pyhss_diameter
  mode tcp
  balance leastconn
  option tcp-check
  tcp-check connect
"

i=1
while read -r ip; do
  BLK+="  server p${i} ${ip}:${DIAM_BACKEND_PORT} check
"
  i=$((i+1))
done <<< "$IPS"

BLK+="
frontend ft_pyhss_api_8080
  bind ${VIP}:8080
  mode tcp
  option tcplog
  default_backend bk_pyhss_api

backend bk_pyhss_api
  mode tcp
  balance leastconn
  option tcp-check
  tcp-check connect
"

i=1
while read -r ip; do
  BLK+="  server p${i} ${ip}:${API_BACKEND_PORT} check
"
  i=$((i+1))
done <<< "$IPS"

BLK+="
### END PYHSS AUTOGEN
"

awk -v repl="$BLK" '
BEGIN{inblk=0}
$0 ~ /### BEGIN PYHSS AUTOGEN/{print repl; inblk=1; next}
$0 ~ /### END PYHSS AUTOGEN/{inblk=0; next}
inblk==0{print}
' "$CFG" >"$TMP"

mv "$TMP" "$CFG"

haproxy -c -f "$CFG"
systemctl reload haproxy

echo "OK: updated backends:"
echo "$IPS"

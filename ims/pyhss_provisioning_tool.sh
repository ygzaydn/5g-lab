#!/bin/bash

# --- Configuration ---
NAMESPACE="open5gs"
DEPLOYMENT="deploy/ims-mysql"
DB_NAME="ims"
MYSQL_USER="root"
MYSQL_PASS="ims"

# --- Interactive Input ---
echo "=================================================="
echo "   PyHSS Fresh Provisioning (Delete & Re-add)"
echo "=================================================="
read -p "How many subscribers do you want to add? " COUNT

if ! [[ "$COUNT" =~ ^[0-9]+$ ]] ; then
   echo "Error: Please enter a valid number."
   exit 1
fi

# --- Static Parameters ---
K_VALUE="465B5CE8B199B49FAA5F0A2EE238A6BC"
OPC_VALUE="E8ED289DEBA952E4283B54E88E6183CA"
AMF_VALUE="8000"
PREFIX="9997"
START_ID=1000
MY_APN_ID=1
IFC_PATH="default_ifc.xml"
SH_TEMPLATE_PATH="default_sh_user_data.xml"

# --- K8s Connection String ---
EXEC_CMD="kubectl exec -i -n $NAMESPACE $DEPLOYMENT -- mysql -u$MYSQL_USER -p$MYSQL_PASS $DB_NAME"

# 1. CLEANUP PHASE (Delete existing data)
echo -e "\n[1/5] Cleaning up existing data (Truncating tables)..."
CLEANUP_SQL="SET FOREIGN_KEY_CHECKS = 0; 
TRUNCATE TABLE apn; 
TRUNCATE TABLE auc; 
TRUNCATE TABLE subscriber; 
TRUNCATE TABLE ims_subscriber; 
SET FOREIGN_KEY_CHECKS = 1;"

echo "$CLEANUP_SQL" | $EXEC_CMD

# 2. APN PREPARATION
echo "[2/5] Creating Default APN: 'ims'..."
APN_SQL="INSERT INTO apn (apn_id, apn, ip_version, apn_ambr_dl, apn_ambr_ul, qci, arp_priority) \
VALUES ($MY_APN_ID, 'ims', 4, 1000000000, 1000000000, 9, 15);"
echo "$APN_SQL" | $EXEC_CMD

# 3. BATCH DATA GENERATION
SQL_BATCH="SET AUTOCOMMIT=0; "

echo "[3/5] Generating data for $COUNT subscribers..."
for (( i=1; i<=$COUNT; i++ ))
do
    CURRENT_ID=$((START_ID + i))
    
    # 15-Digit Logic: 4-digit prefix + 11-digit suffix
    SUFFIX=$(printf "%011d" $i)
    IMSI_VAL="${PREFIX}${SUFFIX}"
    MSISDN_VAL=$IMSI_VAL 

    # A. AUC Table
    SQL_BATCH+="INSERT INTO auc (auc_id, imsi, ki, opc, amf, sqn) \
    VALUES ($CURRENT_ID, '$IMSI_VAL', '$K_VALUE', '$OPC_VALUE', '$AMF_VALUE', 0);"
    
    # B. Subscriber Table
    SQL_BATCH+="INSERT INTO subscriber (subscriber_id, imsi, enabled, auc_id, default_apn, apn_list, msisdn, ue_ambr_dl, ue_ambr_ul, nam) \
    VALUES ($CURRENT_ID, '$IMSI_VAL', 1, $CURRENT_ID, $MY_APN_ID, '$MY_APN_ID', '$MSISDN_VAL', 9999999, 9999999, 0);"

    # C. IMS Subscriber Table
    SQL_BATCH+="INSERT INTO ims_subscriber (ims_subscriber_id, msisdn, msisdn_list, imsi, ifc_path, sh_template_path) \
    VALUES ($CURRENT_ID, '$MSISDN_VAL', '$MSISDN_VAL', '$IMSI_VAL', '$IFC_PATH', '$SH_TEMPLATE_PATH');"
done

SQL_BATCH+="COMMIT;"

# 4. EXECUTION
echo "[4/5] Executing Batch Provisioning..."
echo "$SQL_BATCH" | $EXEC_CMD

if [ $? -eq 0 ]; then
    echo -e "\n[5/5] SUCCESS! Database refreshed and $COUNT subscribers added."
    echo "--------------------------------------------------"
    echo "IMSI Format   : ${PREFIX}00000000001 (15 digits)"
    echo "Cleanup       : Performed on all tables"
    echo "--------------------------------------------------"
else
    echo -e "\nError: The batch operation failed."
fi

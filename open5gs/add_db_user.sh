#!/bin/bash

COUNT=$1
if [ -z "$COUNT" ]; then
    echo "Usage: $0 <count>"
    exit 1
fi

MONGODB_POD=$(kubectl get pods -n open5gs -l app=mongodb -o jsonpath='{.items[0].metadata.name}')

kubectl exec -i $MONGODB_POD -n open5gs -- mongo <<EOF
use open5gs

db.subscribers.remove({});

for (var i = 1; i <= $COUNT; i++) {
    var suffix = i.toString().padStart(11, '0');
    var newIMSI = "9997" + suffix;

    db.subscribers.insert({
        "imsi": newIMSI,
        "subscribed_rau_tau_timer": 12,
        "network_access_mode": 0,
        "subscriber_status": 0,
        "access_restriction_data": 32,
        "slice": [
            {
                "sst": 1,
                "sd": "000001",
                "default_indicator": true,
                "session": [
                    {
                        "name": "internet",
                        "type": 3,
                        "qos": {
                            "index": 9,
                            "arp": {
                                "priority_level": 8,
                                "pre_emption_capability": 1,
                                "pre_emption_vulnerability": 1
                            }
                        },
                        "ambr": {
                            "downlink": { "value": 1, "unit": 3 },
                            "uplink": { "value": 1, "unit": 3 }
                        }
                    },
                    {
                        "name": "ims",
                        "type": 3,
                        "qos": {
                            "index": 5,
                            "arp": {
                                "priority_level": 1,
                                "pre_emption_capability": 1,
                                "pre_emption_vulnerability": 1
                            }
                        },
                        "ambr": {
                            "downlink": { "value": 1, "unit": 3 },
                            "uplink": { "value": 1, "unit": 3 }
                        }
                    }
                ]
            }
        ],
        "security": {
            "k": "465B5CE8B199B49FAA5F0A2EE238A6BC",
            "amf": "8000",
            "op": null,
            "opc": "E8ED289DEBA952E4283B54E88E6183CA",
            "sqn": NumberLong(129)
        },
        "ambr": {
            "downlink": { "value": 1, "unit": 3 },
            "uplink": { "value": 1, "unit": 3 }
        },
        "schema_version": 1,
        "msisdn": [],
        "imeisv": [],
        "mme_host": [],
        "mme_realm": [],
        "purge_flag": [],
        "operator_determined_barring": 0,
        "__v": 0
    });
}
print("Successfully created " + $COUNT + " new subscribers from scratch.");
EOF

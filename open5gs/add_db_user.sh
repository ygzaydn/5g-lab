#!/bin/bash

COUNT=$1
if [ -z "$COUNT" ]; then
    echo "Usage: $0 <count>"
    exit 1
fi

MONGODB_POD=$(kubectl get pods -n open5gs -l app=mongodb -o jsonpath='{.items[0].metadata.name}')

kubectl exec -i $MONGODB_POD -n open5gs -- mongo open5gs <<EOF
// Clear existing subscribers
db.subscribers.remove({});

for (var i = 1; i <= $COUNT; i++) {
    var msin = i.toString().padStart(10, '0');
    var newIMSI = "99970" + msin;

    db.subscribers.insert({
        "imsi": newIMSI,
        "subscribed_rau_tau_timer": NumberInt(12),
        "network_access_mode": NumberInt(0),
        "subscriber_status": NumberInt(0),
        "access_restriction_data": NumberInt(32),
        "slice": [
            {
                "sst": NumberInt(1),
                "sd": "000001",
                "default_indicator": true,
                "session": [
                    {
                        "name": "internet",
                        "type": NumberInt(3),
                        "qos": {
                            "index": NumberInt(9),
                            "arp": {
                                "priority_level": NumberInt(8),
                                "pre_emption_capability": NumberInt(1),
                                "pre_emption_vulnerability": NumberInt(1)
                            }
                        },
                        "ambr": {
                            "downlink": { "value": NumberInt(1), "unit": NumberInt(3) },
                            "uplink": { "value": NumberInt(1), "unit": NumberInt(3) }
                        }
                    },
                    {
                        "name": "ims",
                        "type": NumberInt(3),
                        "qos": {
                            "index": NumberInt(5),
                            "arp": {
                                "priority_level": NumberInt(1),
                                "pre_emption_capability": NumberInt(1),
                                "pre_emption_vulnerability": NumberInt(1)
                            }
                        },
                        "ambr": {
                            "downlink": { "value": NumberInt(1), "unit": NumberInt(3) },
                            "uplink": { "value": NumberInt(1), "unit": NumberInt(3) }
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
            "sqn": NumberLong(1000)
        },
        "ambr": {
            "downlink": { "value": NumberInt(1), "unit": NumberInt(3) },
            "uplink": { "value": NumberInt(1), "unit": NumberInt(3) }
        },
        "schema_version": NumberInt(1),
        "msisdn": [],
        "imeisv": [],
        "mme_host": [],
        "mme_realm": [],
        "purge_flag": [],
        "operator_determined_barring": NumberInt(0),
        "__v": NumberInt(0)
    });
}
print("Successfully added " + $COUNT + " subscribers with correct BSON types.");
EOF

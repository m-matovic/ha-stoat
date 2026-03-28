#!/bin/bash

# Force all output to the container's standard output so Docker captures it
exec > /proc/1/fd/1 2>&1

# Arguments passed by keepalived:
# $1 = "GROUP" or "INSTANCE"
# $2 = Name of the vrrp_instance (e.g., "VI_HETZNER")
# $3 = State ("MASTER", "BACKUP", or "FAULT")
STATE=$3

# Save the latest state to a file so that long-running operations can be aborted
echo "$STATE" > /tmp/keepalived.state

echo "=================================================="
echo "$(date): Keepalived triggered state: $STATE"
echo "=================================================="

if [ "$STATE" = "MASTER" ];
then
    echo "State transitioned to MASTER. Triggering Hetzner API..."

    if [ -z "$HETZNER_API_TOKEN" ] || [ -z "$FLOATING_IP_ID" ] || [ -z "$SERVER_ID" ];
    then
        echo "Error: Missing required Hetzner environment variables."
        exit 1
    fi

    # Infinite retry loop for the Hetzner API
    while true;
    do
        # Check if the state has changed since we started
        CURRENT_STATE=$(cat /tmp/keepalived.state)

        if [ "$CURRENT_STATE" != "MASTER" ];
        then
            echo "State changed to $CURRENT_STATE. Aborting Hetzner API reassignment."
            exit 0
        fi

        response=$(curl -sS -w "\n%{http_code}" -X POST \
            -H "Authorization: Bearer ${HETZNER_API_TOKEN}" \
            -H "Content-Type: application/json" \
            -d "{\"server\": ${SERVER_ID}}" \
            "https://api.hetzner.cloud/v1/floating_ips/${FLOATING_IP_ID}/actions/assign" \
            2>&1)

        http_code=$(echo "$response" | tail -n1)
        http_body=$(echo "$response" | head -n -1)

        if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ];
        then
            echo "Hetzner API request successful: $http_body"
            break
        else
            echo "Hetzner API request failed ($http_code): $http_body"
            echo "Retrying Hetzner API call in 2 seconds..."
            sleep 2
        fi
    done
else
    echo "State is $STATE. No API action required."
fi

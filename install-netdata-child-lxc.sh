#!/bin/bash
# ============================================================
# Script: install-netdata-child.sh
# Doel: Netdata child installeren in LXC container
#       Data wordt gestuurd naar centrale monitoring server
# ============================================================

PARENT_IP='10.24.39.15'   # Centrale monitoring server

CT_IDS=(200 201 202)

for i in $(seq 1 3); do
    CTID="${CT_IDS[$((i-1))]}"

    if [ -z "$CTID" ]; then
        echo 'Gebruik: bash install-netdata-child.sh CONTAINER_ID'
        exit 1
    fi

    echo "Netdata child installeren in container ${CTID}..."

    pct exec $CTID -- bash << NDINSTALL
    apt install -y -q wget curl
    wget -q -O /tmp/netdata-kickstart.sh https://my-netdata.io/kickstart.sh
    bash /tmp/netdata-kickstart.sh --non-interactive --stable-channel --disable-telemetry

    # Child instellen: stuur data naar centrale server
    cat >> /etc/netdata/stream.conf << EOF
    [stream]
        enabled = yes
        destination = ${PARENT_IP}:19999
        api key = 11111111-2222-3333-4444-555555555555
EOF

    systemctl restart netdata
    systemctl enable netdata
    echo 'Netdata child actief!'
NDINSTALL

    IP=$(pct exec $CTID -- hostname -I | awk '{print $1}')
    echo "Container ${CTID} (${IP}) koppelt nu aan monitoring op ${PARENT_IP}"

done
#!/bin/bash
# ============================================================
# Script: install-netdata-node.sh
# Doel: Netdata child installeren op een Proxmox node
#       Monitort: CPU, RAM, disk, netwerk, Ceph, VM/container status
# ============================================================

PARENT_IP='10.24.39.15'
API_KEY='11111111-2222-3333-4444-555555555555'

echo 'Netdata child installeren en koppelen aan centrale server...'

wget -q -O /tmp/netdata-kickstart.sh https://my-netdata.io/kickstart.sh
bash /tmp/netdata-kickstart.sh --non-interactive --stable-channel --disable-telemetry

cat > /etc/netdata/stream.conf << EOF
[stream]
    enabled = yes
    destination = ${PARENT_IP}:19999
    api key = ${API_KEY}
EOF

systemctl restart netdata
systemctl enable netdata

MY_IP=$(hostname -I | awk '{print $1}')
MY_HOST=$(hostname)
echo "Node ${MY_HOST} (${MY_IP}) koppelt nu aan monitoring op ${PARENT_IP}"

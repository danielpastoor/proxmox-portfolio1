#!/bin/bash
# Script: install-netdata-child-vm.sh

VM_IPS=("10.24.39.30" "10.24.39.31" "10.24.39.32")

PARENT_IP='10.24.39.15'   # Centrale monitoring server

for i in $(seq 1 3); do
  VM_IP="${VM_IPS[$((i-1))]}"

    echo "Netdata child installeren op VM ${VM_IP}..."

    ssh -o StrictHostKeyChecking=no root@${VM_IP} << NDINSTALL
    wget -q -O /tmp/netdata-kickstart.sh https://my-netdata.io/kickstart.sh
    bash /tmp/netdata-kickstart.sh --non-interactive --stable-channel --disable-telemetry
    cat >> /etc/netdata/stream.conf << EOF
    [stream]
        enabled = yes
        destination = ${PARENT_IP}:19999
        api key = 11111111-2222-3333-4444-555555555555
EOF
    systemctl restart netdata
    echo 'Netdata child actief op VM!'
NDINSTALL

    echo "VM ${VM_IP} koppelt nu aan monitoring op ${PARENT_IP}"
done
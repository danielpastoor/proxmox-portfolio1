#!/bin/bash
# ============================================================
# Script: setup-firewall.sh
# Doel: Proxmox firewall instellen voor alle WordPress containers
# ============================================================

CT_ID_START=200
AANTAL=3

echo 'Datacenter firewall inschakelen...'
cat > /etc/pve/firewall/cluster.fw << 'EOF'
[OPTIONS]
enable: 1

[RULES]
IN ACCEPT -p tcp --dport 8006 -log nolog
IN ACCEPT -p tcp --dport 22 -log nolog
EOF

echo 'Firewall instellen voor alle containers...'

for i in $(seq 1 $AANTAL); do
    CTID=$((CT_ID_START + i - 1))
    FW_FILE="/etc/pve/firewall/${CTID}.fw"

    echo "  Container ${CTID}: firewall instellen..."

    cat > /etc/pve/firewall/cluster.fw << 'EOF'
[OPTIONS]
enable: 1
policy_in: DROP
policy_out: ACCEPT

[RULES]
# Proxmox beheer
IN ACCEPT -p tcp --dport 8006 -log nolog
IN ACCEPT -p tcp --dport 22 -log nolog
IN ACCEPT -p tcp --dport 3128 -log nolog
IN ACCEPT -p tcp --dport 5900:5999 -log nolog

# Cluster communicatie
IN ACCEPT -p udp --dport 5404:5405 -log nolog
IN ACCEPT -p tcp --dport 60000:60050 -log nolog
EOF


cat > /etc/pve/firewall/200.fw << EOF
[OPTIONS]
enable: 1
dhcp: 1
macfilter: 0
ndp: 1
policy_in: DROP
policy_out: ACCEPT

[RULES]
IN ACCEPT -p tcp --dport 22 -log nolog
IN ACCEPT -p tcp --dport 80 -log nolog
IN ACCEPT -p tcp --dport 443 -log nolog
IN ACCEPT -p icmp -log nolog
EOF

    echo "  Container ${CTID}: firewall ingesteld (SSH/HTTP/HTTPS open, rest geblokkeerd)"
done

echo ''
echo '======================================'
echo ' Firewall voor alle containers klaar!'
echo '======================================'

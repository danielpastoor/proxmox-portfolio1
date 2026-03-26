#!/bin/bash
# ============================================================
# Script: setup-monitoring-server.sh
# Doel: Centrale Netdata parent server installeren in LXC 150
# ============================================================

MONITOR_CT=150
API_KEY='11111111-2222-3333-4444-555555555555'

echo '======================================'
echo ' Netdata parent server installeren'
echo '======================================'

pct exec $MONITOR_CT -- bash << INSTALL

apt update -q && apt install -y -q wget curl
wget -q -O /tmp/netdata-kickstart.sh https://my-netdata.io/kickstart.sh
bash /tmp/netdata-kickstart.sh --non-interactive --stable-channel --disable-telemetry

# Parent instellen: accepteer binnenkomende data van children
cat >> /etc/netdata/stream.conf << EOF
[${API_KEY}]
    enabled = yes
    default memory mode = ram
    health enabled by default = yes
EOF

# Luisteren op alle interfaces
sed -i 's/# bind to = .*/bind to = 0.0.0.0/' /etc/netdata/netdata.conf 2>/dev/null || true

systemctl restart netdata
systemctl enable netdata
echo 'Netdata parent server klaar!'
INSTALL

echo ''
echo '======================================'
echo ' Centrale monitoring server klaar!'
echo ' Dashboard: http://10.24.39.15:19999'
echo '======================================'
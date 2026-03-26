#!/bin/bash

# ============================================================
# Script: update-repos.sh
# Doel: Enterprise repo uitschakelen, no-subscription repo
#       inschakelen, en systeem updaten
# Versie: Proxmox VE 9.x
# ============================================================
echo '======================================'
echo ' Proxmox VE 9 repository instellen'
echo '======================================'

echo '[1/4] Enterprise repo uitschakelen...'

if [ -f /etc/apt/sources.list.d/pve-enterprise.sources ]; then
    if ! grep -q 'Enabled: no' /etc/apt/sources.list.d/pve-enterprise.sources; then
        sed -i '/^Types:/i Enabled: no' /etc/apt/sources.list.d/pve-enterprise.sources
    fi
    echo 'pve-enterprise.sources uitgeschakeld'
fi

if [ -f /etc/apt/sources.list.d/ceph.sources ]; then
    if ! grep -q 'Enabled: no' /etc/apt/sources.list.d/ceph.sources; then
        sed -i '/^Types:/i Enabled: no' /etc/apt/sources.list.d/ceph.sources
    fi
    echo 'ceph.sources uitgeschakeld'
fi

echo '[2/4] No-subscription PVE repo instellen...'

PROXMOX_SOURCES='/etc/apt/sources.list.d/proxmox.sources'

if ! grep -q 'pve-no-subscription' "$PROXMOX_SOURCES" 2>/dev/null; then
    cat > "$PROXMOX_SOURCES" << 'EOF'
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
    echo 'proxmox.sources aangemaakt'
else
    echo 'No-subscription PVE repo bestaat al'
fi

echo '[3/4] Ceph no-subscription repo instellen...'

CEPH_SOURCES='/etc/apt/sources.list.d/ceph-no-subscription.sources'

if ! grep -q 'ceph-squid' "$CEPH_SOURCES" 2>/dev/null; then
    cat > "$CEPH_SOURCES" << 'EOF'
Types: deb
URIs: http://download.proxmox.com/debian/ceph-squid
Suites: trixie
Components: no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
    echo 'ceph-no-subscription.sources aangemaakt'
else
    echo 'Ceph no-subscription repo bestaat al'
fi

echo '[4/4] Systeem updaten...'
apt update
apt upgrade -y
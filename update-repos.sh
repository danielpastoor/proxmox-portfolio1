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
    sed -i 's/^Types:/#Types:/g' /etc/apt/sources.list.d/pve-enterprise.sources
    echo 'pve-enterprise.sources uitgeschakeld'
elif [ -f /etc/apt/sources.list.d/pve-enterprise.list ]; then
    sed -i 's/^deb /#deb /' /etc/apt/sources.list.d/pve-enterprise.list
    echo 'pve-enterprise.list uitgeschakeld'
fi

if [ -f /etc/apt/sources.list.d/ceph.sources ]; then
    sed -i 's/^Types:/#Types:/g' /etc/apt/sources.list.d/ceph.sources
    echo 'ceph.sources uitgeschakeld'
elif [ -f /etc/apt/sources.list.d/ceph.list ]; then
    sed -i 's/^deb /#deb /' /etc/apt/sources.list.d/ceph.list
    echo 'ceph.list uitgeschakeld'
fi

echo '[2/4] No-subscription repo instellen...'

PROXMOX_SOURCES='/etc/apt/sources.list.d/proxmox.sources'

if ! grep -q 'pve-no-subscription' $PROXMOX_SOURCES 2>/dev/null; then
    cat > $PROXMOX_SOURCES << 'EOF'
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
    echo 'proxmox.sources aangemaakt met no-subscription repo'
else
    echo 'No-subscription repo bestaat al in proxmox.sources'
fi

echo '[3/4] Ceph no-subscription repo instellen...'

CEPH_SOURCES='/etc/apt/sources.list.d/ceph-no-subscription.sources'

if ! grep -q 'ceph-squid' $CEPH_SOURCES 2>/dev/null; then
    cat > $CEPH_SOURCES << 'EOF'
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
apt update 2>&1
apt upgrade -y 2>&1

echo ''
echo '======================================'
echo ' Klaar! Systeem is up-to-date.'
echo '======================================'
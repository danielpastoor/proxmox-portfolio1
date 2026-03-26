#!/bin/bash
# ============================================================
# Script: deploy-wordpress.sh
# Doel: 3x WordPress LXC containers aanmaken op Proxmox
# ============================================================

# === INSTELLINGEN — controleer deze waarden! ===
STORAGE='rbd'           # Naam van de Ceph pool
BRIDGE='vmbr0'          # Naam van de netwerk bridge
GATEWAY='10.24.39.1'    # Gateway van het netwerk
IP_BASE='10.24.39'      # Begin van het IP-adres
IP_START=20             # Eerste container krijgt IP .20
CT_ID_START=200         # Eerste container ID
AANTAL=3                # Aantal containers
WP_DB_PASS='iLn9!2dLRq8_eNhtMyLCcJ9xcy4cTq4eMKcUQifGuv6.!Xh-bT'  # Wachtwoord voor WordPress database

# Template van LXC
TEMPLATE='local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst'

echo '======================================'
echo " WordPress deployment - ${AANTAL} containers"
echo '======================================'

# === CONTAINERS AANMAKEN ===
for i in $(seq 1 $AANTAL); do
    CTID=$((CT_ID_START + i - 1))
    HOSTNAME="wordpress-${i}"
    IP="${IP_BASE}.$((IP_START + i - 1))/24"

    echo ""
    echo "--- Container ${CTID} aanmaken: ${HOSTNAME} (${IP}) ---"

    # Container aanmaken met de juiste specs
    pct create $CTID $TEMPLATE \
        --hostname $HOSTNAME \
        --storage $STORAGE \
        --rootfs ${STORAGE}:30 \
        --memory 1024 \
        --cores 1 \
        --net0 name=eth0,bridge=${BRIDGE},ip=${IP},gw=${GATEWAY},rate=50 \
        --unprivileged 1 \
        --features nesting=1 \
        --password 'TijdelijkWW123!'

    echo "  Container ${CTID} aangemaakt"

    # Container starten
    pct start $CTID
    echo "  Container ${CTID} gestart — even wachten..."
    sleep 8

done

echo ''
echo 'Alle containers aangemaakt!'
pct list

#!/bin/bash
# ============================================================
# Script: setup-ha.sh
# Doel: HA instellen voor WordPress VMs via ha-manager add
# ============================================================

echo '======================================'
echo ' HA instellen voor WordPress VMs'
echo '======================================'

echo ""
echo "--- VMs toevoegen aan HA ---"
for ID in 300 301 302; do
  ha-manager add vm:$ID --max_restart 3 --max_relocate 3 2>/dev/null || \
    echo " VM $ID bestaat al in HA, verder gaan..."
  echo " VM $ID toegevoegd"
done

echo ""
echo "--- HA Status ---"
ha-manager status

echo ""
echo '======================================'
echo ' HA instelling klaar!'
echo '======================================'
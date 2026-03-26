#!/bin/bash
# ============================================================
# Script: deploy-wordpress-vm.sh
# Doel: 3x WordPress VM aanmaken
# ============================================================

STORAGE='rbd'
BRIDGE='vmbr0'
GATEWAY='10.24.39.1'
IP_BASE='10.24.39'
IP_START=30
VM_ID_START=300
AANTAL=3
WP_DB_PASS='iLn9!2dLRq8_eNhtMyLCcJ9xcy4cTq4eMKcUQifGuv6.!Xh-bT'
VM_PASSWORD='iLn9!2dLRq8_eNhtMyLCcJ9xcy4cTq4eMKc'
CLOUD_IMAGE='/var/lib/vz/template/iso/debian-13-cloud.qcow2'
CLOUD_URL='https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2'
SNIPPET_DIR='/var/lib/vz/snippets'

echo '======================================'
echo ' WordPress VM deployment - Klant 2'
echo '======================================'

# Cloud image downloaden als die er nog niet is
if [ ! -f $CLOUD_IMAGE ]; then
    echo 'Cloud image downloaden...'
    wget -O $CLOUD_IMAGE $CLOUD_URL
fi

mkdir -p $SNIPPET_DIR

for i in $(seq 1 $AANTAL); do
    VMID=$((VM_ID_START + i - 1))
    VMNAME="wordpress-vm-${i}"
    VM_IP="${IP_BASE}.$((IP_START + i - 1))"
    IP="${VM_IP}/24"

    echo "--- VM ${VMID} aanmaken: ${VMNAME} (${VM_IP}) ---"

    # Cloud-init user-data snippet aanmaken
    cat > ${SNIPPET_DIR}/userdata-${VMID}.yaml << EOF
#cloud-config
ssh_pwauth: true
chpasswd:
  expire: false
  users:
    - name: root
      password: ${VM_PASSWORD}
      type: text
runcmd:
  - sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
  - sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
  - systemctl restart ssh
EOF

    # VM aanmaken
    qm create $VMID --name $VMNAME --memory 1024 --cores 1 \
        --net0 virtio,bridge=${BRIDGE},rate=50 \
        --serial0 socket --vga serial0 --agent enabled=1

    # Cloud image importeren als disk
    qm importdisk $VMID $CLOUD_IMAGE $STORAGE
    qm set $VMID --scsihw virtio-scsi-pci --scsi0 ${STORAGE}:vm-${VMID}-disk-0
    qm set $VMID --ide2 ${STORAGE}:cloudinit
    qm set $VMID --boot c --bootdisk scsi0
    qm resize $VMID scsi0 30G

    # Cloud-init netwerk + snippet instellen
    qm set $VMID --ipconfig0 ip=${IP},gw=${GATEWAY}
    qm set $VMID --ciuser root --cipassword ${VM_PASSWORD}
    qm set $VMID --nameserver 8.8.8.8
    qm set $VMID --cicustom "user=local:snippets/userdata-${VMID}.yaml"

    qm start $VMID
    echo "  VM ${VMID} gestart, wachten op SSH..."

    # Wacht tot SSH beschikbaar is
    until ssh -o StrictHostKeyChecking=no \
              -o ConnectTimeout=5 \
              root@${VM_IP} 'echo ok' 2>/dev/null; do
        echo "$(date) - Nog geen SSH verbinding met ${VM_IP}..."
        sleep 10
    done

    echo "SSH verbinding gelukt met ${VM_IP}"

    # WordPress installeren via SSH
    ssh -o StrictHostKeyChecking=no \
        root@${VM_IP} << WPINSTALL
        export DEBIAN_FRONTEND=noninteractive

        apt update -q
        apt install -y -q apache2 php php-mysql php-curl php-gd php-mbstring \
            php-xml php-xmlrpc php-zip mariadb-server wget unzip ufw

        ufw default deny incoming
        ufw default allow outgoing
        ufw allow 22/tcp
        ufw allow 80/tcp
        ufw allow 443/tcp
        ufw --force enable

        systemctl start mariadb
        mysql -e "CREATE DATABASE wordpress DEFAULT CHARACTER SET utf8mb4;"
        mysql -e "CREATE USER 'wpuser'@'localhost' IDENTIFIED BY '${WP_DB_PASS}';"
        mysql -e "GRANT ALL ON wordpress.* TO 'wpuser'@'localhost';"
        mysql -e "FLUSH PRIVILEGES;"

        wget -q -O /tmp/wp.tar.gz https://wordpress.org/latest.tar.gz
        tar -xzf /tmp/wp.tar.gz -C /var/www/html/
        chown -R www-data:www-data /var/www/html/wordpress

        cp /var/www/html/wordpress/wp-config-sample.php \
        /var/www/html/wordpress/wp-config.php

        sed -i 's/database_name_here/wordpress/' /var/www/html/wordpress/wp-config.php
        sed -i 's/username_here/wpuser/' /var/www/html/wordpress/wp-config.php
        sed -i "s/password_here/${WP_DB_PASS}/" /var/www/html/wordpress/wp-config.php

        cat > /etc/apache2/sites-available/wordpress.conf << 'EOF'
        <VirtualHost *:80>
            DocumentRoot /var/www/html/wordpress
            <Directory /var/www/html/wordpress>
                AllowOverride All
                Require all granted
            </Directory>
        </VirtualHost>
EOF

        a2ensite wordpress.conf
        a2enmod rewrite
        a2dissite 000-default.conf
        systemctl restart apache2
        systemctl enable apache2 mariadb

        echo 'WordPress klaar in VM!'
WPINSTALL

    echo "WordPress geinstalleerd op VM ${VMID}"
done

echo '======================================'
echo ' Alle VMs klaar!'
echo '======================================'
qm list
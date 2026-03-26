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
        --password 'iLn9!2dLRq8_eNhtMyLCcJ9xcy4cTq4eMKc'

    echo "  Container ${CTID} aangemaakt"

    # Container starten
    pct start $CTID
    echo "  Container ${CTID} gestart — even wachten..."
    
    sleep 8

    # === WORDPRESS INSTALLEREN ===
    echo "  WordPress installeren in container ${CTID}..."

    pct exec $CTID -- bash << WPINSTALL
        export DEBIAN_FRONTEND=noninteractive

        apt update -q
        apt install -y -q apache2 php php-mysql php-curl php-gd php-mbstring \
            php-xml php-xmlrpc php-zip mariadb-server wget unzip

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

        echo 'WordPress klaar in container!'
WPINSTALL

    echo "  WordPress geinstalleerd in ${CTID}"

done

echo ''
echo 'Alle containers aangemaakt!'
pct list

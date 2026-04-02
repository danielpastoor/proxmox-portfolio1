#!/bin/bash
# Doel: unieke SSH-gebruiker vmuser1/2/3 per VM

VM_IPS=("10.24.39.30" "10.24.39.31" "10.24.39.32")
KEY_DIR='/root/portfolio1/ssh-keys'
mkdir -p $KEY_DIR

for i in $(seq 1 3); do
  VM_IP="${VM_IPS[$((i-1))]}"
  USERNAME="vmuser${i}"
  KEY_FILE="${KEY_DIR}/${USERNAME}"

  echo "--- VM ${VM_IP}: gebruiker ${USERNAME} aanmaken ---"

  ssh-keygen -t ed25519 -f $KEY_FILE -N '' -C "${USERNAME}@wordpress-vm-${i}" -q

  ssh -o StrictHostKeyChecking=no root@${VM_IP} "
    useradd -m -s /bin/bash ${USERNAME} 2>/dev/null || true
    mkdir -p /home/${USERNAME}/.ssh
    chmod 700 /home/${USERNAME}/.ssh
    echo '$(cat ${KEY_FILE}.pub)' > /home/${USERNAME}/.ssh/authorized_keys
    chmod 600 /home/${USERNAME}/.ssh/authorized_keys
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.ssh
    sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    systemctl restart sshd
  "

  echo " Klaar: ssh -i ${KEY_FILE} ${USERNAME}@${VM_IP}"
done

echo '======================================'
echo ' Alle VM SSH gebruikers aangemaakt!'
echo '======================================'
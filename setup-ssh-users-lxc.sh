#!/bin/bash
# Doel: unieke SSH-gebruiker wpuser1/2/3 per LXC container

CT_IDS=(200 201 202)
KEY_DIR='/root/portfolio1/ssh-keys'
mkdir -p $KEY_DIR

for i in $(seq 1 3); do
  CTID="${CT_IDS[$((i-1))]}"
  USERNAME="wpuser${i}"
  KEY_FILE="${KEY_DIR}/${USERNAME}"

  echo "--- Container ${CTID}: gebruiker ${USERNAME} aanmaken ---"

  ssh-keygen -t ed25519 -f $KEY_FILE -N '' -C "${USERNAME}@wordpress-lxc-${i}" -q

  pct exec $CTID -- useradd -m -s /bin/bash $USERNAME 2>/dev/null || true
  pct exec $CTID -- mkdir -p /home/${USERNAME}/.ssh
  pct exec $CTID -- chmod 700 /home/${USERNAME}/.ssh
  pct exec $CTID -- bash -c "echo '$(cat ${KEY_FILE}.pub)' > /home/${USERNAME}/.ssh/authorized_keys"
  pct exec $CTID -- chmod 600 /home/${USERNAME}/.ssh/authorized_keys
  pct exec $CTID -- chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.ssh
  pct exec $CTID -- sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
  pct exec $CTID -- sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
  pct exec $CTID -- systemctl restart sshd

  echo " Klaar: ssh -i ${KEY_FILE} ${USERNAME}@10.24.39.$((19+i))"
done

echo '======================================'
echo ' Alle LXC SSH gebruikers aangemaakt!'
echo '======================================'
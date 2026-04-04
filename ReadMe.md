# Proxmox Portfolio 2425

Automatische uitrol van een WordPress-omgeving op Proxmox via Ansible en Bash.

## Projectoverzicht

| Onderdeel | Omschrijving |
|---|---|
| `ansible/` | Ansible playbooks en roles voor volledige automatische uitrol |
| `deploy-wordpress-lxc.sh` | WordPress deployen op een LXC container |
| `deploy-wordpress-vm.sh` | WordPress deployen op een VM |
| `install-HA-vm.sh` | High Availability instellen voor VMs |
| `install-netdata-*.sh` | Netdata monitoring installeren (node, child LXC/VM) |
| `setup-monitoring-server.sh` | Netdata parent/monitoring server opzetten |
| `setup-firewall-lxc.sh` | Proxmox firewall regels instellen voor LXC |
| `setup-ssh-users-*.sh` | Unieke SSH gebruikers aanmaken per host |
| `update-repos.sh` | APT repositories bijwerken op Proxmox |
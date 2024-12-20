#!/bin/bash
    sudo apt-get update
    sudo apt-get install nfs-kernel-server -y
    sudo mkdir -p /var/nfs/kubernetes
    sudo mkdir -p /export/users
    sudo chown nobody:nogroup /var/nfs/kubernetes
    sudo chown nobody:nogroup /export/users
    sudo chmod 666  /etc/exports
sudo cat > /etc/exports <<EOF
#/var/nfs/kubernetes    192.168.1.0/24(rw,sync,no_subtree_check)
/export/users    192.168.1.0/24(rw,sync,no_subtree_check)
EOF
    sudo chmod 644 /etc/exports
    sudo systemctl restart nfs-kernel-server
    #sudo systemctl disable ufw

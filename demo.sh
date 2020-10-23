#!/bin/bash
apt-get -y update && apt-get install -y apache2
echo ${MY_FQDN} >/var/www/html/whoami
sudo systemctl disable systemd-resolved.service
sudo systemctl stop systemd-resolved
rm -f /etc/resolv.conf
cat  >/etc/resolv.conf <<RESOLVCONF
nameserver 67.207.67.2
nameserver 67.207.67.3
domain bangkok.lol
RESOLVCONF
echo -e "1night\n1night" | passwd root
sed 's/^PasswordAuthentication no$/PasswordAuthentication yes/g' /etc/ssh/sshd_config > /etc/ssh/sshd_config.tmp
mv /etc/ssh/sshd_config.tmp /etc/ssh/sshd_config
service sshd restart


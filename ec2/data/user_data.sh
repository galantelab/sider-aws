#!/usr/bin/env bash
mkfs -t ext4 /dev/sdf
mkdir /home/workdir
mount /dev/sdf /home/workdir
chown nobody:nogroup /home/workdir
chmod 755 /home/workdir
echo "/dev/sdf /home/workdir ext4 defaults,nofail 0 2" >> /etc/fstab

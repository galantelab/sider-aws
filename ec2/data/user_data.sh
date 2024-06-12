#!/usr/bin/env bash
mkfs -t ext4 /dev/ebs
mkdir /home/workdir
mount /dev/ebs /home/workdir
chown nobody:nogroup /home/workdir
chmod 755 /home/workdir
echo "/dev/ebs /home/workdir ext4 defaults,nofail 0 2" >> /etc/fstab

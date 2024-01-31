#!/bin/bash
dnf -y install epel-release
dnf -y update
dnf -y install snapd
systemctl enable snapd
systemctl start snapd
snap install lxd
lxd init

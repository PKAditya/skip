#!/bin/bash

PASS=$1

# update the system
echo "updating the system."
echo "$PASS" | sudo -S yum update -y &> /dev/null

echo "Upgrading the system."
# upgrade the system
echo "$PASS" | sudo -S yum upgrade -y &> /dev/null

# installing dependencies
echo "Installing dwarves"
echo "$PASS" | sudo -S yum install dwarves -y &> /dev/null
echo "Installing rsync"
echo "$PASS" | sudo -S yum install rsync -y &> /dev/null
echo "Installing elfutils-libelf-devel"
echo "$PASS" | sudo -S dnf install elfutils-libelf-devel -y &> /dev/null
echo "Installing multiple dependencies required for kernel build"
echo "$PASS" | sudo -S yum install gcc gcc-c++ kernel-devel perl make numactl openssl openssl-devel libmpc mpfr libstdc++-devel libtool bison flex zlib zlib-devel ncurses-devel -y &> /dev/null

echo "$PASS" | sudo -S yum install createrepo rpm-build rpmdevtools -y &> /dev/null

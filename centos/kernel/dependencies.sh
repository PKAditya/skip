#!/bin/bash

# update the system
sudo yum update -y

# upgrade the system
sudo yum upgrade -y

# installing dependencies
sudo yum install dwarves -y
sudo yum install rsync -y
sudo dnf install elfutils-libelf-devel -y

sudo yum install gcc gcc-c++ kernel-devel perl make numactl openssl openssl-devel libmpc mpfr libstdc++-devel libtool bison flex zlib zlib-devel ncurses-devel -y

sudo yum install createrepo rpm-build rpmdevtools -y

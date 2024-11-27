#!/bin/bash

# Graphical Display
pip install pyfiglet &> /dev/null
python3 -m pyfiglet "LKP TESTS"

# capture current working directory
loc=$(pwd)

# capture type of distro.
distro=$(cat /etc/os-release | grep ^ID= | cut -d'=' -f2)
user=$(echo $USER)

echo "////////////--  STARTING WITH LKP RUNNING  --\\\\\\\\\\\\"
echo "Distro found: $distro"
echo "Current user: $user"
echo " "

echo ""
if [ "$distro" == "ubuntu" ]; then
  if [ "$user" == "amd" ]; then
          echo 'Amd$1234!' | sudo -S $loc/ubuntu/run.sh $user
  else
          sudo $loc/ubuntu/run.sh $user
  fi
else
  if [ "$user" == "amd" ]; then
          echo 'Amd$1234!' |  sudo -S $loc/centos/run.sh $user
  else
          sudo $loc/centos/run.sh $user
  fi
fi

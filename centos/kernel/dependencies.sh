#!/bin/bash

# update the system
sudo yum update -y

# upgrade the system
sudo yum upgrade -y

# installing dependencies
sudo yum install dwarves -y
sudo yum install rsync -y
sudo dnf install elfutils-libelf-devel -y

#!/bin/bash

aws ec2 run-instances --image-id ami-d05e75b8 --count $1 --instance-type t2.micro --key-name itmo-544-virtualbox --security-group-ids sg-77350e10 --subnet-id subnet-968ddcbd --associate-public-ip-address --user-data file://../itmo-544-444-env/install-env.sh 
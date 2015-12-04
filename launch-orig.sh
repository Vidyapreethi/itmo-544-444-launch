#!/bin/bash

mapfile -t instanceARR < <(aws ec2 run-instances --image-id ami-d05e75b8 --count $1 --instance-type t2.micro --key-name itmo-544-virtualbox --security-group-ids sg-77350e10 --subnet-id subnet-968ddcbd --associate-public-ip-address --iam-instance-profile Name=phpdeveloperRole --user-data file://../itmo-544-444-env/install-webserver.sh --output table| grep InstanceId| sed "s/|//g" | sed "s/   //g" | sed "s/ InstanceId //g")

echo ${instanceARR[@]}

aws rds create-db-subnet-group --db-subnet-group-name mp1 --db-subnet-group-description "group for mp1" --subnet-ids subnet-b737cd8a subnet-968ddcbd subnet-1d555d6a subnet-0c82a155

aws rds create-db-instance --db-instance-identifier pvp-db-mp --db-instance-class db.t1.micro --engine MySQL --master-username controller --master-user-password ilovebunnies --allocated-storage 5 --db-subnet-group-name mp1

aws rds wait db-instance-available --db-instance-identifier pvp-db-mp 

php ../itmo-544-444-fall2015/setup.php


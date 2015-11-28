#!/bin/bash

# Delete existing RDS  Databases
 
mapfile -t dbInstanceARR < <(aws rds describe-db-instances --output json | grep "\"DBInstanceIdentifier" | sed "s/[\"\:\, ]//g" | sed "s/DBInstanceIdentifier//g" )

if [ ${#dbInstanceARR[@]} -gt 0 ]
   then
   echo "Deleting existing RDS database-instances"
   LENGTH=${#dbInstanceARR[@]}  

   # http://docs.aws.amazon.com/cli/latest/reference/rds/wait/db-instance-deleted.html
      for (( i=0; i<${LENGTH}; i++));
      do 
      aws rds delete-db-instance --db-instance-identifier ${dbInstanceARR[i]} --skip-final-snapshot --output text
      aws rds wait db-instance-deleted --db-instance-identifier ${dbInstanceARR[i]} --output text
      sleep 1
   done
fi
    
aws rds create-db-subnet-group --db-subnet-group-name mp1 --db-subnet-group-description "group for mp1" --subnet-ids subnet-b737cd8a subnet-968ddcbd subnet-1d555d6a subnet-0c82a155

aws rds create-db-instance --db-instance-identifier pvp-db-mp --db-instance-class db.t1.micro --engine MySQL --master-username controller --master-user-password ilovebunnies --allocated-storage 5 --db-subnet-group-name mp1 --db-name customerrecords

aws rds wait db-instance-available --db-instance-identifier pvp-db-mp 
    
echo "Created database"
php ../itmo-544-444-fall2015/setup.php
 echo " Created tables successfully"



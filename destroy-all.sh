#!/bin/bash

declare -a cleanupARR
declare -a cleanupLBARR
declare -a dbInstanceARR

aws ec2 describe-instances --filter Name=instance-state-code,Values=16 --output table | grep InstanceId | sed "s/|//g" | tr -d ' ' | sed "s/InstanceId//g"

mapfile -t cleanupARR < <(aws ec2 describe-instances --filter Name=instance-state-code,Values=16 --output table | grep InstanceId | sed "s/|//g" | tr -d ' ' | sed "s/InstanceId//g")

echo "the output is ${cleanupARR[@]}"

aws ec2 terminate-instances --instance-ids ${cleanupARR[@]} 

echo "Cleaning up existing Load Balancers"
mapfile -t cleanupLBARR < <(aws elb describe-load-balancers --output json | grep LoadBalancerName | sed "s/[\"\:\, ]//g" | sed "s/LoadBalancerName//g")

echo "The LBs are ${cleanupLBARR[@]}"

LENGTH=${#cleanupLBARR[@]}
echo "ARRAY LENGTH IS $LENGTH"
for (( i=0; i<${LENGTH}; i++)); 
  do
  aws elb delete-load-balancer --load-balancer-name ${cleanupLBARR[i]} --output text
  sleep 1
done

# Delete existing RDS  Databases
# Note if deleting a read replica this is not your command 
#mapfile -t dbInstanceARR < <(aws rds describe-db-instances --output json | grep "\"DBInstanceIdentifier" | sed "s/[\"\:\, ]//g" | sed "s/DBInstanceIdentifier//g" )

#if [ ${#dbInstanceARR[@]} -gt 0 ]
 #  then
  # echo "Deleting existing RDS database-instances"
   #LENGTH=${#dbInstanceARR[@]}  

   # http://docs.aws.amazon.com/cli/latest/reference/rds/wait/db-instance-deleted.html
       #  for (( i=0; i<${LENGTH}; i++));
       #  do 
         #aws rds delete-db-instance --db-instance-identifier ${dbInstanceARR[i]} --skip-final-snapshot --output text
         #aws rds wait db-instance-deleted --db-instance-identifier ${dbInstanceARR[i]} --output text
         #sleep 1
      #done
   #fi


# Delete Launchconf and Autoscaling groups

declare -a LAUNCHCONF
LAUNCHCONF=(`aws autoscaling describe-launch-configurations --output json | grep LaunchConfigurationName | sed "s/[\"\:\, ]//g" | sed "s/LaunchConfigurationName//g"`)

echo "The launch configuration group is: " ${LAUNCHCONF[@]}


declare -a SCALENAME
SCALENAME=(`aws autoscaling describe-auto-scaling-groups --output table | grep AutoScalingGroupName | sed "s/|//g" | sed "s/   //g" | sed "s/ AutoScalingGroupName //g"`)

echo "The autoscaling group is: " ${SCALENAME[@]}

if [ ${#SCALENAME[@]} -gt 0 ]
  then
echo "SCALING GROUPS to delete..."

aws autoscaling delete-auto-scaling-group --auto-scaling-group-name ${SCALENAME[@]}
echo " Deleted auto scaling group"
aws autoscaling delete-launch-configuration --launch-configuration-name ${LAUNCHCONF[@]}
echo " Deleted launch configuration"

fi

# deleting s3 buckets

aws s3api list-buckets --query 'Buckets[].Name'

for i in ${bucketARR[@]}; do if [[ $i == *"php-pv"* ]]; then aws s3 rb s3://$i --force ; fi done 
echo "Deleted all s3 buckets"

echo "All done"


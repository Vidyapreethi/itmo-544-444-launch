#!/bin/bash

./destroy-all.sh

#declare an array in bash 
declare -a instanceARR

mapfile -t instanceARR < <(aws ec2 run-instances --image-id ami-d05e75b8 --count $1 --instance-type t2.micro --key-name itmo-544-virtualbox --security-group-ids sg-77350e10 --subnet-id subnet-968ddcbd --associate-public-ip-address --iam-instance-profile Name=phpdeveloperRole --user-data file://../itmo-544-444-env/install-webserver.sh --output table| grep InstanceId| sed "s/|//g" | sed "s/   //g" | sed "s/ InstanceId //g")

echo ${instanceARR[@]}

aws ec2 wait instance-running --instance-ids ${instanceARR[@]}

echo "Instances are running"

ELBURL=(`aws elb create-load-balancer --load-balancer-name $2 --listeners Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80 --subnets subnet-968ddcbd --security-groups sg-77350e10 --output text`); echo $ELBURL

echo -e "\nFinished creating ELB and sleeping 25 seconds"

for i in {0..25};do echo -ne '.';sleep 1;done

aws elb register-instances-with-load-balancer --load-balancer-name $2 --instances ${instanceARR[@]}

aws elb configure-health-check --load-balancer-name $2 --health-check Target=HTTP:80/index.html,Interval=30,UnhealthyThreshold=2,HealthyThreshold=2,Timeout=3

echo -e "\nWaiting an additinal 3 minutes before opening ELB in browser"

for i in {0..180};do echo -ne '.';sleep 1;done

aws elb create-lb-cookie-stickiness-policy --load-balancer-name $2 --policy-name my-cookie-policy
#create launch configuration

aws autoscaling create-launch-configuration --launch-configuration-name itmo544-launch-config --image-id ami-d05e75b8 --key-name itmo-544-virtualbox --security-groups sg-77350e10 --instance-type t2.micro --user-data file://../itmo-544-444-env/install-webserver.sh --iam-instance-profile phpdeveloperRole

echo "Created launch configuration"

#creating auto scaling

aws autoscaling create-auto-scaling-group --auto-scaling-group-name itmo-544-auto-scaling-group --launch-configuration-name itmo544-launch-config --load-balancer-names $2 --health-check-type ELB --min-size 1 --max-size 3 --desired-capacity 2 --default-cooldown 600 --health-check-grace-period 120 --vpc-zone-identifier subnet-968ddcbd 
echo "Created auto scaling group"

echo "Created auto scaling"

#updating auto scaling

aws autoscaling update-auto-scaling-group --auto-scaling-group-name itmo-544-auto-scaling-group --launch-configuration-name itmo544-launch-config --health-check-type ELB --min-size 3 --max-size 6 --desired-capacity 3 --health-check-grace-period 60 --vpc-zone-identifier subnet-968ddcbd --default-cooldown 600 

echo " Updated auto scaling"

#creating sns-topic 

ARN=(`aws sns create-topic --name pvp-cloud-watch`)

echo "This is the ARN : $ARN"

aws sns set-topic-attributes --topic-arn $ARN --attribute-name DisplayName --attribute-value cloud-watch
aws sns subscribe --topic-arn $ARN --protocol email --notification-endpoint vparthas@hawk.iit.edu

# creating cloud watch metrics

aws cloudwatch put-metric-alarm --alarm-name pvp-cloud-watch --alarm-description "Alarm when CPU exceeds 30" --metric-name Latency --namespace AWS/ELB --statistic Maximum --period 60 --threshold 30 --comparison-operator GreaterThanOrEqualToThreshold  --dimensions Name=LoadBalancerName,Value=$2 --evaluation-periods 6 --alarm-actions $ARN --unit Milliseconds

echo "Created Cloud watch metrics"

#Last Step

chromium-browser $ELBURL &

export ELBURL


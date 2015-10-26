#!/bin/bash

aws elb create-load-balancer --load-balancer-name itmo-544-pvp-lb --listeners Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80 --subnets subnet-968ddcbd --security-groups sg-77350e10

aws elb register-instances-with-load-balancer --load-balancer-name itmo-544-pvp-lb --instances i-28f9a697 i-27f9a698 i-26f9a699

aws elb configure-health-check --load-balancer-name itmo-544-pvp-lb --health-check Target=HTTP:80/index.php,Interval=30,UnhealthyThreshold=2,HealthyThreshold=2,Timeout=3

sleep 300
firefox http://itmo-544-pvp-lb-84744157.us-east-1.elb.amazonaws.com



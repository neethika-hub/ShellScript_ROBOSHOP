#!/bin/bash

AMI_ID="ami-0055977a6e828a4f4"
SecurityGroup_ID="sg-0338f2fe5c729ee11"
Instances=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")
HostedZone_ID="Z0234269167B6OYW6YW44"
DNS_Name="shynudevops.shop"
for instance in ${Instances[@]}
do
    Instance_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.micro --security-group-ids $SecurityGroup_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name, Value=$instance}]" --query "Instances[0].InstanceId" --output text)
    echo "The ID of $instance is $Instance_ID"
done
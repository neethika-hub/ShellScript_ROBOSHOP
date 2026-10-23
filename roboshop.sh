#!/bin/bash

AMI_ID="ami-0055977a6e828a4f4"
SecurityGroup_ID="sg-0338f2fe5c729ee11"
Instances=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")
HostedZone_ID="Z0234269167B6OYW6YW44"
DNS_Name="shynudevops.shop"
for instance in ${Instances[@]}
do
    Instance_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.micro --security-group-ids $SecurityGroup_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name, Value=$instance}]" --query "Instances[0].InstanceId" --output text)
    if [ $instance != "frontend" ]
    then
        IP=$(aws ec2 describe-instances --instance-ids $Instance_ID --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
        Record_Name=$instance.$DNS_Name
    else
        IP=$(aws ec2 describe-instances --instance-ids $Instance_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
        Record_Name=$DNS_Name
    fi
    echo "$instance IP Address is $IP"
    aws route53 change-resource-record-sets --hosted-zone-id $HostedZone_ID --change-batch '
    {
        "Comment": "Creating or Updating a record set"
        ,"Changes": [{
        "Action"              : "UPSERT"
        ,"ResourceRecordSet"  : {
            "Name"              : "'$Record_Name'"
            ,"Type"             : "A"
            ,"TTL"              : 1
            ,"ResourceRecords"  : [{
                "Value"         : "'$IP'"
            }]
        }
        }]
    }'
    echo "Updated $IP for $instance in ROUTE53 $Record_Name"
done
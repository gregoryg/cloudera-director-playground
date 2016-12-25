#!/bin/bash
## Edit for correct profile (if used) and region
aws_prefix="aws --profile gregoryg --region us-west-1 "

# 1) Launch the Cloudera Director instance
## Cloudera Director with local repo and web server 
echo 'Launching the Cloudera Director instance'
dirinstanceid=$(${aws_prefix} ec2 run-instances \
    --region us-west-1 \
    --image-id ami-736e2013 \
    --count 1 \
    --instance-type t2.large \
    --associate-public-ip-address \
    --subnet-id subnet-d337f48a \
    --key-name gregoryg-ncalifornia \
    --security-group-ids sg-167e2872 \
    --output text \
    --query 'Instances[*].InstanceId')
if [ "$?" != 0 ] ; then
   exit 1
fi


echo 'Launching the MySQL instance for CM metadata'
# 2) Launch the MySQL metadata instance for CM use
dbinstanceid=$(${aws_prefix} ec2 run-instances \
    --region us-west-1 \
    --image-id ami-ba6e22da \
    --count 1 \
    --instance-type t2.large \
    --associate-public-ip-address \
    --subnet-id subnet-d337f48a \
    --key-name gregoryg-ncalifornia \
    --security-group-ids sg-167e2872 \
    --output text \
    --query 'Instances[*].InstanceId')
if [ "$?" != 0 ] ; then
   exit 1
fi

echo 'Waiting to tag instances'
while state=$(${aws_prefix} ec2 describe-instances --region us-west-1 --instance-ids $dirinstanceid --output text --query 'Reservations[*].Instances[*].State.Name'); test "$state" = "pending"; do
  sleep 10; echo -n '.'
done; echo " $state"

## Tag the Director instance
${aws_prefix} ec2 create-tags \
    --region us-west-1 \
    --resources $dirinstanceid \
    --tags Key=owner,Value=gregoryg Key=Name,Value=greg-director

while state=$(${aws_prefix} ec2 describe-instances --region us-west-1 --instance-ids $dbinstanceid --output text --query 'Reservations[*].Instances[*].State.Name'); test "$state" = "pending"; do
  sleep 10; echo -n '.'
done; echo " $state"

## Tag the DB instance
${aws_prefix} ec2 create-tags \
    --region us-west-1 \
    --resources $dbinstanceid \
    --tags Key=owner,Value=gregoryg Key=Name,Value=greg-mysql

echo 'Fixing up the .ssh/config file'
info=$(${aws_prefix} ec2 describe-instances --instance-ids ${dirinstanceid} --query 'Reservations[*].Instances[*].{pubip:PublicIpAddress,privateip:PrivateIpAddress,privatedns:PrivateDnsName}' --output json)
dir_ip=`echo $info | jq -r '.[0][0].pubip'`
privip=`echo $info | jq -r '.[0][0].privateip'`
privdns=`echo $info | jq -r '.[0][0].privatedns'`
ssh-keygen -q -R ${dir_ip}

gsed -i.bak "/^ *Host aws-director/,/^ *Host /{s/^\( *Hostname *\)\(.*\)/\1$dir_ip/}" ~/.ssh/config
diff ~/.ssh/config ~/.ssh/config.bak

db_ip=$(${aws_prefix} ec2 describe-instances --instance-ids ${dbinstanceid} --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)
gsed -i.bak "/^ *Host aws-mysql/,/^ *Host /{s/^\( *Hostname *\)\(.*\)/\1$db_ip/}" ~/.ssh/config
diff ~/.ssh/config*

echo Waiting to start proxy... 
${aws_prefix} ec2 wait system-status-ok --instance-ids ${dirinstanceid}
emacsclient -n /centos@aws-director:

ssh -tt centos@aws-director "sudo yum -y install nc netcat"
echo waiting for Director to become available
for i in 1 2 3 4 5 6 7 8 9 10
do
    ssh centos@${dir_ip} "nc localhost 7189 < /dev/null"
    ret=$?
    if [ ${ret} == 0 ] ; then
        echo Opening Director web page
        open "http://${privdns}:7189/"
        break
    else
        echo -n .
        sleep 10
    fi
done
echo

echo Cloudera Director URL is http://${privdns}:7189/
open "http://${privdns}:7189/"

echo 'Done!'

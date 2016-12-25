#!/bin/bash
# 1) Launch the Cloudera Director instance
## Cloudera Director with local repo and web server 
echo 'Launching Cloudera Director instance'
info=$(gcloud compute instances create director-server \
       --zone us-central1-c \
       --disk name=cloudera-director,boot=yes \
       --machine-type n1-highmem-2 \
       --metadata owner=gregoryg \
       --network locked-down \
       --format="value(networkInterfaces[0].accessConfigs[0].natIP:label=EXTERNAL_IP,networkInterfaces[0].networkIP:label=INTERNAL_IP,status)")
if [ "$?" != 0 ] ; then
   exit 1
fi

dir_ip=`echo $info | cut -d' ' -f1`
echo Director external IP is $dir_ip
ssh-keygen -q -R ${dir_ip}

echo 'Launching MySQL metadata instance'
info=$(gcloud compute instances create dir-mysql \
       --zone us-central1-c \
       --disk name=mysql-for-metadata,boot=yes \
       --disk name=mysql-metadata-disk1,boot=no \
       --machine-type n1-highmem-2 \
       --metadata owner=gregoryg \
       --network locked-down \
       --format="value(networkInterfaces[0].accessConfigs[0].natIP:label=EXTERNAL_IP,networkInterfaces[0].networkIP:label=INTERNAL_IP,status)")
echo $info
mysql_ip=`echo $info | cut -d' ' -f1`
if [ "$?" != 0 ] ; then
   exit 1
fi

echo 'Fixing up the .ssh/config file'
gsed -i.bak "/^ *Host director-server */,/^ *Host /{s/^\( *Hostname *\)\(.*\)/\1$dir_ip/}" ~/.ssh/config
diff ~/.ssh/config.bak ~/.ssh/config

gsed -i.bak "/^ *Host mysql */,/^ *Host /{s/^\( *Hostname *\)\(.*\)/\1$mysql_ip/}" ~/.ssh/config
diff ~/.ssh/config.bak ~/.ssh/config


dirhost=`gcloud compute ssh gregj@director-server --command "hostname -f" --zone us-central1-c`

echo Starting proxy
emacsclient -n /gregj@director-server:
echo waiting for Director to become available
for i in 1 2 3 4 5 6 7 8 9 10
do
    ssh gregj@${dir_ip} "nc -z localhost 7189"
    ret=$?
    if [ ${ret} == 0 ] ; then
        echo Opening Director web page
        open "http://${dirhost}:7189/"
        break
    else
        echo -n .
        sleep 10
    fi
done
echo

echo Cloudera Director URL is http://${dirhost}:7189/
echo 'Done!'

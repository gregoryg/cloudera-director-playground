#!/bin/bash
export JAVA_HOME=/usr/java/jdk1.7.0_67-cloudera
SCRIPT_HOST=`hostname -f`
CM_HOST_PORT=${DEPLOYMENT_HOST_PORT:-$SCRIPT_HOST:7180}
CM_HOST=`echo $CM_HOST_PORT | cut -d':' -f1`
CM_PORT=`echo $CM_HOST_PORT | cut -d':' -f2`
CM_USER_NAME=${CM_USER_NAME:-admin}
CM_PASSWORD=${CM_PASSWORD:-admin}
CLUSTER_NAME=${CLUSTER_NAME:-lemoncheeks}

## Run this on the Cloudera Manager instance
## Pre-requisites: cluster running with Impala and Kudu

## Enable the Kudu CSD
KUDUJAR="KUDU-0.9.0.jar"
if [ -d /opt/cloudera/csd ] && [ ! -e /opt/cloudera/csd/${KUDUJAR} ] ; then
    cd
    wget "http://archive.cloudera.com/beta/kudu/csd/${KUDUJAR}"
    sudo mv -v ${KUDUJAR} /opt/cloudera/csd/
fi

# Build ssh command for setting up Impala_Kudu service.
## First install necessary packages: cm-api from pip, and jq for parsing JSON

sudo yum -y install epel-release
sudo yum -y install python-pip jq
sudo pip install cm-api
IMPALA_SVC=`curl -u "${CM_USER_NAME}:${CM_PASSWORD}" http://$CM_HOST_PORT/api/v5/clusters/${CLUSTER_NAME}/services | jq -r -c '.items[] | select(.type | contains("IMPALA")) | .name'`
echo "This is the name of the Impala service: |$IMPALA_SVC|"
if [ -z "$IMPALA_SVC" ] ; then
    echo There is no current Impala \(non-Kudu\) service installed - skipping deploy step
    exit
fi

curl -O https://raw.githubusercontent.com/cloudera/impala-kudu/feature/kudu/infra/deploy/deploy.py
chmod +x deploy.py
./deploy.py --host $CM_HOST clone IMPALA_KUDU-1 "$KUDU_SVC"

# Delete IMPALA-1
curl -X DELETE -u "${CM_USER_NAME}:${CM_PASSWORD}" "http://$CM_HOST:$CM_PORT/api/v5/clusters/lemoncheeks/services/$IMPALA_SVC"
# Start IMPALA_KUDU-1
curl -X POST -u "${CM_USER_NAME}:${CM_PASSWORD}" "http://$CM_HOST:$CM_PORT/api/v5/clusters/lemoncheeks/services/IMPALA_KUDU-1/commands/start"

###### Streamsets setup
wget -q https://archives.streamsets.com/datacollector/1.4.0.0/csd/STREAMSETS-1.4.0.0.jar
chmod 644 STREAMSETS-*.jar
sudo chown cloudera-scm:cloudera-scm STREAMSETS-*.jar
sudo mv -iv STREAMSETS-*.jar /opt/cloudera/csd/
sudo service cloudera-scm-server restart
# echo 'sleeping 2 minutes'
# sleep 120

## Install Maven, clone the demo repo, setup StreamSets service, build demo, and chown to admin.
wget -q http://mirrors.koehn.com/apache/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz
tar -zxf apache-maven-3.3.9-bin.tar.gz
chmod -R 777 /root/apache-maven-3.3.9/
# export JAVA_HOME=/usr/java/jdk1.8.0_60-cloudera/
export PATH=$PATH:`pwd`/apache-maven-3.3.9/bin/:$JAVA_HOME/bin
# echo 'export JAVA_HOME=/usr/java/jdk1.8.0_60-cloudera/' >> /root/.bashrc
# echo 'export PATH=$PATH:/home/admin/apache-maven-3.3.9/bin/:/usr/java/jdk1.8.0_60-cloudera/bin/' >> /root/.bashrc
# echo 'export JAVA_HOME=/usr/java/jdk1.8.0_60-cloudera/' >> /home/admin/.bashrc
# echo 'export PATH=$PATH:/home/admin/apache-maven-3.3.9/bin/:/usr/java/jdk1.8.0_60-cloudera/bin/' >> /home/admin/.bashrc
sudo yum -y install git
# git clone http://github.mtv.cloudera.com/foe/ConnectedCarDemo ## for VPN
gsutil cp -r gs://gregoryg/ConnectedCarDemo .
cd ConnectedCarDemo/demo/entity360
mvn clean package
cd bin/
python DeployStreamSets.py $CM_HOST $CM_HOST
echo "DEBUG: Determine what `pwd`/setup.sh needs for its host names; we don't match the expected host naming convention"
exit
./setup.sh $DEMOCLUSTERNAME-1.$DOMAIN $DEMOCLUSTERNAME-2.$DOMAIN
# chown -R admin:admin /home/admin

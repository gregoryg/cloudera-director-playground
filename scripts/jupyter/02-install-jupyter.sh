#!/bin/bash

cmhost=`echo ${DEPLOYMENT_HOST_PORT} | cut -d':' -f1`
cmhost=`grep server_host= /etc/cloudera-scm-agent/config.ini |cut -d '=' -f2-`
if [ -z "$cmhost" ] ; then
    echo "Error: Cannot determine Cloudera Manager host address - does this host run Cloudera Manager Agent?"
    exit 1
fi
echo Cloudera Manager is running on $cmhost

# get cluster name
clustername=$(curl --silent -X GET -u admin:admin http://$cmhost:7180/api/v14/clusters | jq -r '.items[].name')
if [ 1 != `echo $clustername | wc -l` ] ; then
    echo "Error: I can only deal with 1 cluster managed by the CM - found: `echo $clustername`"
    exit 1
fi

echo "Cloning Impala service to Impala-Kudu"
# Get name of HUE and Impala services on this cluster
huesvcname=$(curl --silent -u admin:admin http://$cmhost:7180/api/v14/clusters/$clustername/services | jq -r '.items[] | select(.type == "HUE") | .name')
impalasvcname=$(curl --silent -u admin:admin http://$cmhost:7180/api/v14/clusters/$clustername/services | jq -r '.items[] | select(.type == "IMPALA") | select(.name | contains("CD-IMPALA")) | .name')
impaladisplayname=$(curl --silent -u admin:admin http://$cmhost:7180/api/v14/clusters/$clustername/services/$impalasvcname | jq -r '.displayName')
wget https://raw.githubusercontent.com/cloudera/impala-kudu/feature/kudu/infra/deploy/deploy.py
chmod a+rx deploy.py
./deploy.py --host "$cmhost" clone IMPALA_KUDU-1 "$impaladisplayname"

# Configure HUE to use Impala-Kudu - this must happen before deleting original Impala service
echo "Updating Hue config to use Impala-Kudu"
curl --silent -X PUT -H "Content-Type:application/json" -u "admin:admin" -d '{"items":[{"name":"impala_service","value":"IMPALA_KUDU-1"}]}' http://$cmhost:7180/api/v14/clusters/$clustername/services/$huesvcname/config

if [ -n "$impalasvcname" ] ; then
    echo "Deleting the original Impala service"
    curl -X DELETE -u "admin:admin" "http://$cmhost:7180/api/v14/clusters/$clustername/services/$impalasvcname"
fi

echo Starting new service IMPALA_KUDU-1
curl -X POST -u "admin:admin" "http://$cmhost:7180/api/v14/clusters/$clustername/services/IMPALA_KUDU-1/commands/start"

echo "Setting up current JDK"
wget 'http://archive.cloudera.com/director/redhat/7/x86_64/director/2.2/RPMS/x86_64/jdk-8u60-linux-x64.rpm'
sudo yum -y install jdk-8u60-linux-x64.rpm

echo "Setting up defaults for impala-shell"
sudo alternatives --set impala-shell /opt/cloudera/parcels/IMPALA_KUDU/bin/impala-shell
sudo alternatives --config impala-shell
impalad=$(curl --silent -u "admin:admin" "http://$cmhost:7180/api/v14/hosts?view=FULL" | jq -r '[.items[] | select(.roleRefs[].roleName | contains("IMPALA_KUDU-1-IMPALAD")) | .ipAddress] | first ')
echo "[impala]
impalad=${impalad}:21007
  " > ~/.impalarc

zkhost=$(curl -u "admin:admin" "http://$cmhost:7180/api/v14/hosts?view=FULL" | jq -r '[.items[] | select(.roleRefs[].roleName | contains("ZOOKEEPER")) | .ipAddress] | first')
echo "Set up Jupyter notebook because notebooks are cool"
echo "And now update .bashrc"
tee -a ~/.bashrc <<EOF
# set environment variables for pyspark
export PYSPARK_DRIVER_PYTHON=/opt/cloudera/parcels/Anaconda/bin/jupyter
export PYSPARK_DRIVER_PYTHON_OPTS="notebook --NotebookApp.open_browser=False --NotebookApp.ip='*' --NotebookApp.port=8880"
export PYSPARK_PYTHON=/opt/cloudera/parcels/Anaconda/bin/python
export PATH=/opt/cloudera/parcels/Anaconda/bin:$PATH

EOF
echo "TODO: add env var to all nodes, including this gateway"
## export PYSPARK_PYTHON=/opt/cloudera/parcels/Anaconda/bin/python

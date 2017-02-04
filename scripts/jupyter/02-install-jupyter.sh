#!/bin/bash

echo "Setting up current JDK"
wget 'http://archive.cloudera.com/director/redhat/7/x86_64/director/2.2/RPMS/x86_64/jdk-8u60-linux-x64.rpm'
sudo yum -y install jdk-8u60-linux-x64.rpm

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

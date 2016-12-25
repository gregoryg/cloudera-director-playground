#!/bin/bash

gcloud compute instances create gort-cm gort-gateway \
       --boot-disk-size 100 \
       --boot-disk-type pd-ssd \
       --image centos-6 \
       --machine-type n1-highmem-4 \
       --metadata owner=gregoryg \
       --network locked-down \
       --zone us-central1-c

gcloud compute disks create gort-w1-d0 gort-w1-d1 gort-w2-d0 gort-w2-d1 gort-w3-d0 gort-w3-d1 gort-w4-d0 gort-w4-d1 gort-w5-d0 gort-w5-d1 \
       --description "data disks for Cloudera CDH worker nodes" \
       --size 1024GB \
       --type pd-ssd \
       --zone us-central1-c 



gcloud compute instances create gort-worker-1 \
       --boot-disk-size 100 \
       --boot-disk-type pd-ssd \
       --disk name=gort-w1-d0,mode=rw,boot=no,device-name=dn-data0,auto-delete=yes \
       --disk name=gort-w1-d1,mode=rw,boot=no,device-name=dn-data1,auto-delete=yes \
       --image centos-6 \
       --machine-type n1-highmem-4 \
       --metadata owner=gregoryg \
       --network locked-down \
       --no-address \
       --zone us-central1-c

gcloud compute instances create gort-worker-2 \
       --boot-disk-size 100 \
       --boot-disk-type pd-ssd \
       --disk name=gort-w2-d0,mode=rw,boot=no,device-name=dn-data0,auto-delete=yes \
       --disk name=gort-w2-d1,mode=rw,boot=no,device-name=dn-data1,auto-delete=yes \
       --image centos-6 \
       --machine-type n1-highmem-4 \
       --metadata owner=gregoryg \
       --network locked-down \
       --no-address \
       --zone us-central1-c

gcloud compute instances create gort-worker-3 \
       --boot-disk-size 100 \
       --boot-disk-type pd-ssd \
       --disk name=gort-w3-d0,mode=rw,boot=no,device-name=dn-data0,auto-delete=yes \
       --disk name=gort-w3-d1,mode=rw,boot=no,device-name=dn-data1,auto-delete=yes \
       --image centos-6 \
       --machine-type n1-highmem-4 \
       --metadata owner=gregoryg \
       --network locked-down \
       --no-address \
       --zone us-central1-c

gcloud compute instances create gort-worker-4 \
       --boot-disk-size 100 \
       --boot-disk-type pd-ssd \
       --disk name=gort-w4-d0,mode=rw,boot=no,device-name=dn-data0,auto-delete=yes \
       --disk name=gort-w4-d1,mode=rw,boot=no,device-name=dn-data1,auto-delete=yes \
       --image centos-6 \
       --machine-type n1-highmem-4 \
       --metadata owner=gregoryg \
       --network locked-down \
       --no-address \
       --zone us-central1-c

gcloud compute instances create gort-worker-5 \
       --boot-disk-size 100 \
       --boot-disk-type pd-ssd \
       --disk name=gort-w5-d0,mode=rw,boot=no,device-name=dn-data0,auto-delete=yes \
       --disk name=gort-w5-d1,mode=rw,boot=no,device-name=dn-data1,auto-delete=yes \
       --image centos-6 \
       --machine-type n1-highmem-4 \
       --metadata owner=gregoryg \
       --network locked-down \
       --no-address \
       --zone us-central1-c

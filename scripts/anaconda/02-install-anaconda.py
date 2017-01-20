#!/usr/bin/python
import os
import time
from cm_api.api_client import ApiResource
# If the exit code is not zero Cloudera Director will fail

# Post creation scripts also have access to the following environment variables:

#    DEPLOYMENT_HOST_PORT
#    ENVIRONMENT_NAME
#    DEPLOYMENT_NAME
#    CLUSTER_NAME
#    CM_USERNAME
#    CM_PASSWORD

def main():
    anaconda_repo="http://dynapse.net/archive/parcels/"
    cmhost = os.environ['DEPLOYMENT_HOST_PORT'].split(":")[0]
    api = ApiResource(cmhost, username='admin', password='admin')
    all_clusters = api.get_all_clusters()
    for cluster in all_clusters:
        if (cluster.name == os.environ['CLUSTER_NAME']):
            break

    cm = api.get_cloudera_manager()
    config = cm.get_config(view='summary')
    parcel_urls = config.get("REMOTE_PARCEL_REPO_URLS","").split(",")
    print "Adding Anaconda parcel repository"
    if anaconda_repo in parcel_urls:
        # already there, skip
        print "Anaconda repo url already included"
    else:
        parcel_urls.append(anaconda_repo)
        config["REMOTE_PARCEL_REPO_URLS"] = ",".join(parcel_urls)
        cm.update_config(config)
        # wait to make sure parcels are refreshed
        time.sleep(10)
        print "Added Anaconda repository URL"

    # Download Anaconda parcel
    print "Downloading parcel"
    parcel = cluster.get_parcel('Anaconda', '4.0.0')
    parcel.start_download()
    while True:
        parcel = cluster.get_parcel('Anaconda', '4.0.0')
        if parcel.stage == 'DOWNLOADED':
            break
        if parcel.state.errors:
            raise Exception(str(parcel.state.errors))
        print "   progress: %s of %s" % (parcel.state.progress, parcel.state.totalProgress)
        time.sleep(2)
    print "Downloaded"

    print "Distributing"
    parcel.start_distribution()
    while True:
        parcel = cluster.get_parcel('Anaconda', '4.0.0')
        if parcel.stage == 'DISTRIBUTED':
            break
        if parcel.state.errors:
            raise Exception(str(parcel.state.errors))
        print "   progress: %s of %s" % (parcel.state.progress, parcel.state.totalProgress)
        time.sleep(5)
    print "Distributed"

    print "Activating Anaconda"
    parcel.activate()
    while True:
        parcel = cluster.get_parcel('Anaconda', '4.0.0')
        if parcel.stage == 'ACTIVATED':
            break
        time.sleep(2)
    print "Activated. Anaconda is ready to use"

    
if __name__ == "__main__":
    main()


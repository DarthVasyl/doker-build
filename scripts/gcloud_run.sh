#!/bin/bash

###################################################
#    commands to create infrastruture from cli    #
###################################################

# <-- SET PROJECT VARIABLES -->
PROJECT_ID=gcloud-docker-demo
SERVICE_ACCOUNT=gcloud-admin@gcloud-docker-demo.iam.gserviceaccount.com
DB_INSTANCE_NAME=moodle-db
DB_NAME=moodle
DB_USER=moodleuser
DB_USER_PASS=m00dLe
ADMIN_PASS=m@Dm1n
FILESHARE_NAME=moodledata
FILESHARE_MOUNT=10.72.88.234:/moodledata
DB_ENDPOINT=gcloud-docker-demo:us-central1:moodle-db
REGION=us-central1
ZONE=uc-central1-c
CLUSTER_NAME=mdc-1

# <--- START SQL --- >
# create mysql instance with replication
sudo gcloud sql instances create $DB_INSTANCE_NAME --assign-ip --database-version=MYSQL_5_7 \
--enable-bin-log --region=$REGION --storage-type=SSD --tier=db-n1-standard-2 \
--failover-replica-name=$DB_INSTANCE_NAME-repl --replica-type=FAILOVER --replication=asynchronous

# create mysql user for moodle
sudo gcloud sql users create $DB_USER --host=% --instance=$DB_INSTANCE_NAME --password=$DB_USER_PASS

# check if moodle db exist
touch log && sudo gcloud sql databases list --instance=$DB_INSTANCE_NAME > log
if [ "grep -q $DB_NAME log" ]; then
  echo "DB already exist";
else
  # create dtabase for moodle
  sudo gcloud sql databases create $DB_NAME --instance=$DB_INSTANCE_NAME  
fi

### Get sql endpoint
DB_ENDPOINT=sudo gcloud beta sql instances describe $DB_INTANCE_NAME --project=$PROJECT_ID | grep connectionName | sed 's\connectionName: \\g'

# <--- END SQL --- >

# <--- START FILESHARE --- >
 sudo gcloud beta filestore instances create $FILESHARE_NAME \
     --project=$PROJECT_ID --location=$ZONE \
     --file-share=name=$FILESHARE_NAME,capacity=1TB \
     --network=name="default"
# <--- END FILESHARE --- >

# <--- START kubernetes cluster --- >
sudo gcloud container clusters create "$CLUSTER_NAME" --project $PROJECT_ID --addons=HttpLoadBalancing --disk-size="60" \
--enable-autorepair --enable-autoupgrade --enable-autoscaling --enable-cloud-monitoring --max-nodes="10" --min-nodes="2" \
--region=$REGION --enable-ip-alias --network "projects/$PROJECT_ID/global/networks/default" \
--subnetwork "projects/$PROJECT_ID/regions/$REGION/subnetworks/default"

### get kubernetes credentials
sudo gcloud beta container clusters get-credentials $CLUSTER_NAME --region $REGION --project $PROJECT_ID

# <--- START SQL proxy credentials --- >
# before this step you must create service account 
# create json key, bind account to your cluster, allow this acount edit sql instance
# and enable sql admin api
sudo kubectl create secret generic cloudsql-instance-credentials \
    --from-file=credentials.json=.keys/gcloud-docker-demo-1ae353ab8f29.json

sudo kubectl create secret generic cloudsql-db-credentials \
    --from-literal=username=$DB_USER --from-literal=password=$DB_USER_PASS
# <--- END SQL proxy credentials --- >

# <--- END kubernetes cluster --- >

# deployment for cluster describet in file app-deployment.yaml
# we can build Kubernetes deployment with command
sudo kubectl apply -f k8-deployments/app-deployment.yaml --validate=false

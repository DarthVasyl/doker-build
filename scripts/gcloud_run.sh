#!/bin/bash

###################################################
#    commands to create infrastruture from cli    #
###################################################

# <-- LATEST PROJECT VARIABLES -->
PROJECT_ID=gcloud-docker-demo
SERVICE_ACCOUNT=gcloud-admin@gcloud-docker-demo.iam.gserviceaccount.com
VM_INSTANCE_NAME=moodle-just-install
DB_INSTANCE_NAME=moodle-db
DB_NAME=moodle
DB_USER=moodleuser
DB_USER_PASS=m00dLe
FILESHARE_NAME=moodledata
FILESHARE_MOUNT=10.72.88.234:/moodledata
DB_ENDPOINT=gcloud-docker-demo:us-central1:moodle-db
REGION=us-central1
ZONE=uc-central1-c
# <--- START SQL --- >
# create mysql instance with replication
sudo gcloud sql instances create $DB_INSTANCE_NAME --authorized-networks=46.118.180.0/24 --assign-ip --database-version=MYSQL_5_7 \
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
### get info
# sudo gcloud beta filestore instances describe $FILESHARE_NAME --project=devops-docker-demo --location=us-central1-c | grep endpoint
# <--- END FILESHARE --- >

# <--- START TEST VM --- >
### create VM just for Moodle installation
sudo gcloud beta compute --project=$PROJECT_ID instances create $VM_INSTANCE_NAME --zone=$ZONE \
--machine-type=n1-standard-1 --subnet=default --service-account=$SERVICE_ACCOUNT \
--tags=http-server --image=cos-dev-71-11104-0-0 --image-project=cos-cloud --boot-disk-size=10GB --boot-disk-type=pd-standard \
--boot-disk-device-name=$VM_INSTANCE_NAME \
--metadata DB_HOST=$DB_ENDPOINT --metadata-from-file startup-script=moodle-just-install.sh

### Allow Http to machine
sudo gcloud compute --project=$PROJECT_ID firewall-rules create default-allow-http --direction=INGRESS \
--priority=1000 --network=default --action=ALLOW --rules=tcp:80 --source-ranges=0.0.0.0/0 --target-tags=http-server
# <--- END TEST VM --- >

# <--- START kubernetes cluster --- >
sudo gcloud container clusters create mdc-1 --addons=HttpLoadBalancing --disk-size=60 --enable-autorepair \
--enable-autoupgrade --enable-autoscaling --max-nodes=10 --min-nodes=2 --region=$REGION \
--service-account=$SERVICE_ACCOUNT

### get kubernetes credentials
sudo gcloud beta container clusters get-credentials mdc-1 --region $REGION --project $PROJECT_ID

# <--- START SQL proxy credentials --- >
sudo kubectl create secret generic cloudsql-instance-credentials \
    --from-file=credentials.json=.keys/gcloud-docker-demo-1ae353ab8f29.json

sudo kubectl create secret generic cloudsql-db-credentials \
    --from-literal=username=$DB_USER --from-literal=password=$DB_USER_PASS
# <--- END SQL proxy credentials --- >

# <--- END kubernetes cluster --- >

# build Kubernetes deployment
sudo kubectl apply -f k8-deployments/app-deployment.yaml --validate=false

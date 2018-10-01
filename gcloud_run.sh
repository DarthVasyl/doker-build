#!/bin/bash

#<-- VARS-->
PROJECT_ID=gcloud-docker-demo
SERVICE_ACCOUNT=gcloud-admin@gcloud-docker-demo.iam.gserviceaccount.com
VM_INSTANCE_NAME=moodle-just-install
DB_INSTANCE_NAME=moodle-db
DB_NAME=moodle
DB_USER=moodleuser
DB_USER_PASS=m00dLe
FILESHARE_NAME=moodledata
DB_ENDPOINT=gcloud-docker-demo:us-central1:moodle-db

# <--- START SQL --- >
# create mysql instance with replication
sudo gcloud sql instances create $DB_INSTANCE_NAME --authorized-networks=46.118.180.0/24 --assign-ip --database-version=MYSQL_5_7 \
--enable-bin-log --region=us-central --storage-type=SSD --tier=db-n1-standard-2 \
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
# <--- END SQL --- >

### Get sql endpoint
DB_ENDPOINT=sudo gcloud beta sql instances describe $DB_INTANCE_NAME --project=devops-docker-demo | grep connectionName | sed 's\connectionName: \\g'

# <--- START FILESHARE --- >
# sudo gcloud beta filestore instances create $FILESHARE_NAME \
#     --project=devops-docker-demo --location=us-central1-c \
#     --file-share=name=$FILESHARE_NAME,capacity=1TB \
#     --network=name="default"
### get info
# sudo gcloud beta filestore instances describe $FILESHARE_NAME --project=devops-docker-demo --location=us-central1-c | grep endpoint

### create VM just for Moodle installation

### Create machine for moodle installation
sudo gcloud beta compute --project=$PROJECT_ID instances create $VM_INSTANCE_NAME --zone=us-central1-b \
--machine-type=n1-standard-1 --subnet=default --service-account=$SERVICE_ACCOUNT \
--tags=http-server --image=cos-dev-71-11104-0-0 --image-project=cos-cloud --boot-disk-size=10GB --boot-disk-type=pd-standard \
--boot-disk-device-name=$VM_INSTANCE_NAME --metadata DB_HOST=$DB_ENDPOINT --metadata-from-file startup-script=moodle-just-install.sh

#--image=centos-7-v20180911 --image-project=centos-cloud

sudo gcloud beta compute --project=gcloud-docker-demo instances create moodle-just-install --zone=us-central1-b \
--machine-type=n1-standard-1 --subnet=default --service-account=gcloud-admin@gcloud-docker-demo.iam.gserviceaccount.com \
--tags=http-server --image=cos-dev-71-11104-0-0 --image-project=cos-cloud --boot-disk-size=10GB --boot-disk-type=pd-standard \
--boot-disk-device-name=moodle-just-install --metadata DB_HOST=gcloud-admin@gcloud-docker-demo.iam.gserviceaccount.com \
#--metadata-from-file startup-script=moodle-just-install.sh

### Allow Http to machine
sudo gcloud compute --project=devops-docker-demo firewall-rules create default-allow-http --direction=INGRESS \
--priority=1000 --network=default --action=ALLOW --rules=tcp:80 --source-ranges=0.0.0.0/0 --target-tags=http-server

sleep 2m
### script to run on pods
# sudo apt-get -y update
# sudo apt-get -y install nfs-common
# sudo mkdir /var/moodledata
# sudo mount 10.143.94.26:/moodledata /var/moodledata
# sudo chmod go+rw /var/moodledata
# <--- END SQL --- >

# <--- START kubernetes cluster --- >
sudo gcloud container clusters create mdc-1 --addons=HttpLoadBalancing --disk-size=60 --enable-autorepair \
--enable-autoupgrade --enable-autoscaling --max-nodes=10 --min-nodes=2 --region=us-central1 \
--service-account=docker-admin@devops-docker-demo.iam.gserviceaccount.com

sleep 5m
### get kubernetes credentials
sudo gcloud beta container clusters get-credentials mdc-1 --region us-central1 --project devops-docker-demo

### Create load balancer
#sudo kubectl expose moodle-1.4 --port=80 --target-port=8080 \
#        --name=moodle-14 --type=LoadBalancer

# <--- END kubernetes cluster --- >

# <--- START SQL proxy credentials --- >
sudo kubectl create secret generic cloudsql-instance-credentials \
    --from-file=credentials.json=devops-docker-demo-e2e3d79083d7.json

sudo kubectl create secret generic cloudsql-db-credentials \
    --from-literal=username=moodleuser --from-literal=password=m00dLe
# <--- END SQL proxy credentials --- >

# build Kubernetes deployment
sudo kubectl apply -f app-deployment.yaml --validate=false

sudo docker run -d -v /cloudsql:/cloudsql \
  -v ~/key-file.json:/config \
  gcr.io/cloudsql-docker/gce-proxy /cloud_sql_proxy -dir=/cloudsql \
  -instances=devops-docker-demo:us-central1:mdb
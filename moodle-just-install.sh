#!/bin/bash

# install docker
sudo yum install -y yum-utils device-mapper-persistent-data lvm2 &&\
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo && \
sudo yum install -y docker-ce

# start and enable service
sudo systemctl start docker.service && \
sudo systemctl enable docker.service

# mount fileshare
sudo yum -y update && \
sudo yum -y install nfs-utils && \
sudo mkdir /var/moodledata && \
sudo mount 10.143.94.26:/moodledata /var/moodledata && \
sudo chmod go+rw /var/moodledata

### GET sql proxy
sudo yum -y install mysql && \
sudo yum -y install wget && \
wget https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 -O cloud_sql_proxy && \
chmod +x cloud_sql_proxy

./cloud_sql_proxy -instances=devops-docker-demo:us-central1:mdb=tcp:3306 \
-credential_file=/home/formicking/key-file.json &

## GET proxy container
sudo yum -y install mysql
sudo docker pull gcr.io/cloudsql-docker/gce-proxy:1.12
# GET External IP for Moodle site path
MODLE_IP=sudo gcloud beta compute instances describe moodle-just-install --project=devops-docker-demo | grep natIP: | sed 's\    natIP: \\g'
MOODLE_PATH="http://$MOODLE_IP/moodle"
# get docker image
sudo gcloud docker --authorize-only && \
sudo gcloud docker -- pull gcr.io/devops-docker-demo/docker-build:build_v_1.8 && \
sudo docker run gcr.io/devops-docker-demo/docker-build:build_v_1.8 \
-e INIT_DB=1 -e MOODLE_URL=http://35.227.222.254/moodle -ti moodle \
--mount type=bind,source=/var/moodledata,target=/var/moodledata


sudo docker run gcr.io/devops-docker-demo/docker-build:build_v_1.6 \
-ti moodle -e DB_HOST=$DB_HOST -e INIT_DB=1 -e MOODLE_URL=$MOODLE_PATH \
--mount type=bind,source=/var/moodledata,target=/var/moodledata
##### TEMP ####

docker run -d -v /cloudsql:/cloudsql \
  -v ~/key-file.json:/config \
  -p 127.0.0.1:3306:3306 \
  gcr.io/cloudsql-docker/gce-proxy:1.12 /cloud_sql_proxy \
  -instances=devops-docker-demo:us-central1:mdb=tcp:0.0.0.0:3306 -credential_file=/config


/cloud_sql_proxy -instances=devops-docker-demo:us-central1:moodle-db=tcp:3306 -credential_file=/secrets/cloudsql/credentials.json
docker run -d -v /cloudsql:/cloudsql \
  -v <PATH_TO_KEY_FILE>:/config \
  gcr.io/cloudsql-docker/gce-proxy /cloud_sql_proxy -dir=/cloudsql \
  -instances=<INSTANCE_CONNECTION_NAME> -credential_file=/config
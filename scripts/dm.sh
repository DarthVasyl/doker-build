# create kubernetes cluster with deployment manager
sudo gcloud beta deployment-manager deployments create cluster  --config ../deployment-manager/cluster.yaml \
--project=gcloud-docker-demo --create-policy CREATE

# create deployment for cluster
sudo gcloud beta deployment-manager deployments create moodle  --config ../deployment-manager/moodle.yaml \
--project=gcloud-docker-demo --create-policy CREATE


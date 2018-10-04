sudo gcloud beta deployment-manager deployments create test  --config k8-deployments/demo.yaml \
--project=gcloud-docker-demo --create-policy CREATE
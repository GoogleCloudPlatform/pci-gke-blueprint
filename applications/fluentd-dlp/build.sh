#!/bin/bash -u

# set to the project ID of the destination container repository
#PROJECT_PREFIX="pci-poc"

TAG=`git log --oneline -n1|cut -d' '  -f1`b
docker build . -t gcr.io/${PROJECT_PREFIX}-in-scope/fluentd:${TAG}
docker push gcr.io/${PROJECT_PREFIX}-in-scope/fluentd:${TAG}
echo "FLUENTD_IMAGE_REMOTE_REPO: gcr.io/${PROJECT_PREFIX}-in-scope/fluentd:${TAG}"

#!/usr/bin/env bash

# Builds and pushes a customized frontend image

MICROSERVICES_DEMO_RELEASE_TAG="v0.1.4"
MICROSERVICES_DEMO_REPOSITORY="git@github.com:GoogleCloudPlatform/microservices-demo.git"
TAG="${MICROSERVICES_DEMO_RELEASE_TAG}-$(date +%Y-%m-%d-%H%M)"
APP_NAME="microservices-demo/frontend"
PROJECT="pci-gke-blueprint"

WORKING_DIR=$(mktemp -d)
git clone "${MICROSERVICES_DEMO_REPOSITORY}" ${WORKING_DIR}/microservices-demo

for customfile in  Dockerfile default.conf run.sh; do
    cp "${customfile}" "${WORKING_DIR}/microservices-demo/src/frontend"
done

pushd "${WORKING_DIR}/microservices-demo/src/frontend"
git checkout "${MICROSERVICES_DEMO_RELEASE_TAG}"

docker build . -t "${APP_NAME}:${TAG}"
docker tag "${APP_NAME}:${TAG}" "gcr.io/${PROJECT}/${APP_NAME}:${TAG}"
#gcloud auth configure-docker # if needed
docker push "gcr.io/${PROJECT}/${APP_NAME}:${TAG}"
popd
rm -rf "${WORKING_DIR}"

echo "Image: "
echo "gcr.io/${PROJECT}/${APP_NAME}:${TAG}"

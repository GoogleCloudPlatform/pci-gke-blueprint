#/usr/bin/env bash -ax

# Retrieve Cluster Credentials and Configure Custom Contexts
echo 'Retrieving cluster credentials'

gcloud container clusters get-credentials in-scope --zone us-central1-a --project ${TF_VAR_project_prefix}-in-scope
kubectl config rename-context $(kubectl config current-context) in-scope

gcloud container clusters get-credentials out-of-scope --zone us-central1-a --project "${TF_VAR_project_prefix}-out-of-scope"
kubectl config rename-context $(kubectl config current-context) out-of-scope

# Create a Sample TLS Certificate+Key to Use in the GKE Clusters
echo 'Create a Sample TLS Certificate+Key to Use in the GKE Clusters'

# check to make sure openssl is installed
which openssl
retVal=$?
if [ $retVal -ne 0 ]; then
  echo 'openssl not found.'
  exit $retVal
fi

echo 'generating a self-signed certificate and key'
openssl genrsa -out hipsterservice.key 2048
openssl req -new -key hipsterservice.key -out hipsterservice.csr \
  -subj "/CN=$DOMAIN_NAME"
openssl x509 -req -days 365 -in hipsterservice.csr -signkey hipsterservice.key \
  -out hipsterservice.crt

echo 'Creating a Secret that holds your certificate and key'
kubectl --context out-of-scope create secret tls tls-hipsterservice \
  --cert hipsterservice.crt --key hipsterservice.key

retVal=$?
if [ $retVal -ne 0 ]; then
  echo 'out-of-scope secret not created'
  exit $retVal
fi

kubectl --context in-scope create secret tls tls-hipsterservice \
  --cert hipsterservice.crt --key hipsterservice.key

retVal=$?
if [ $retVal -ne 0 ]; then
  echo 'in-scope secret not created'
  exit $retVal
fi

echo 'You now need to manually create a DLP De-identification template.'
echo 'Please follow the steps listed here: https://github.com/GoogleCloudPlatform/terraform-pci-starter#create-a-dlp-de-identification-template'
echo 'Once you are done, hit enter to continue with buidling fluentd'
read

# Build the Custom fluentd-gcp Container
echo 'Building the custom fluentd-gcp container'
pushd applications/fluentd-dlp
FLUENTD_REPO=`./build.sh | awk '/FLUENTD_IMAGE_REMOTE_REPO:/ {print $NF}' `
popd

# update workstation.env
echo 'Updating workstation.env'
if [[ `uname -s` == 'Darwin' ]]; then
  sed -i .tmp "s|FLUENTD_IMAGE_REMOTE_REPO=TBD|FLUENTD_IMAGE_REMOTE_REPO=${FLUENTD_REPO}|g" workstation.env
else
  sed -i "s|FLUENTD_IMAGE_REMOTE_REPO=TBD|FLUENTD_IMAGE_REMOTE_REPO=${FLUENTD_REPO}|g" workstation.env
fi

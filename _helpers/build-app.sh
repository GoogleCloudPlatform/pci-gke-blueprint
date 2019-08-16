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
  echo 'openssl not found. Please install openssl'
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

source ./workstation.env

# Helm Installation and Setup
echo "Helm Installation and Setup"

# check to make sure openssl is installed
which helm
retVal=$?
if [ $retVal -ne 0 ]; then
  echo 'helm not found. Please install helm and rerun this script starting at this step.'
  exit $retVal
fi

echo "Installing tiller on the in-scope cluster."
kubectl --context in-scope -n kube-system create sa tiller
kubectl --context in-scope \
        -n kube-system \
        create clusterrolebinding tiller \
        --clusterrole cluster-admin \
        --serviceaccount=kube-system:tiller
helm --kube-context in-scope  init --history-max 200 --service-account tiller

# check to make sure tiller was installed
if [ `kubectl --context in-scope get deploy,svc tiller-deploy -n kube-system | grep tiller-deploy | wc -l` -ne 2 ] ; then
  echo 'Something went wrong tiller was not installed on the in-scope cluster'
  exit 1
fi

echo "Installing tiller on the out-of-scope cluster."
kubectl --context out-of-scope -n kube-system create sa tiller
kubectl --context out-of-scope \
        -n kube-system \
        create clusterrolebinding tiller \
        --clusterrole cluster-admin \
        --serviceaccount=kube-system:tiller
helm --kube-context out-of-scope  init --history-max 200 --service-account tiller

# check to make sure tiller was installed
if [ `kubectl --context out-of-scope get deploy,svc tiller-deploy -n kube-system | grep tiller-deploy | wc -l` -ne 2 ] ; then
  echo 'Something went wrong tiller was not installed on the out-of-scope cluster'
  exit 1
fi

# Application Deployment
echo "Starting the Histper Store deployment..."
pushd helm

echo "Installing fluentd Logger"
helm install \
  --kube-context out-of-scope \
  --name fluentd-custom-target-project \
  --namespace kube-system \
  --set project_id=${TF_VAR_project_prefix}-management \
  ./fluentd-custom-target-project

echo "Installing out-of-scope microservices"
helm install \
  --kube-context out-of-scope \
  --name out-of-scope-microservices \
  ./out-of-scope-microservices

echo "Deploying the DLP-Fluentd Logger"
helm install \
  --kube-context in-scope \
  --name fluentd-filter-dlp \
  --namespace kube-system \
  --set project_id=${TF_VAR_project_prefix}-management \
  --set deidentify_template_name=${DEIDENTIFY_TEMPLATE_NAME} \
  --set fluentd_image_remote_repo=${FLUENTD_IMAGE_REMOTE_REPO} \
  ./fluentd-filter-dlp

echo "Deploying the in-scope microservices"
# Setting the `domain_name` will create a Managed Certificate resource. Don't
# add this line if you can't manage your domain's DNS record. You will need
# to point the DNS record to your Ingress' external IP.

helm install \
  --kube-context in-scope \
  --name in-scope-microservices \
  --set nginx_listener_1_ip="$(kubectl --context out-of-scope get svc nginx-listener-1 -o jsonpath="{.status.loadBalancer.ingress[*].ip}")" \
  --set nginx_listener_2_ip="$(kubectl --context out-of-scope get svc nginx-listener-2 -o jsonpath="{.status.loadBalancer.ingress[*].ip}")" \
  --set domain_name=${DOMAIN_NAME} \
  ./in-scope-microservices

EXTERNAL_IP=`kubectl  --context in-scope get ingress frontend-external-tls | grep front| awk {'print $3'}`
echo "Please manually create a DNS A record for ${DOMAIN_NAME} pointing to ${EXTERNAL_IP}"
echo "This is the ip address of your frontend load balancer."
echo 'You can find the ip address by running: kubectl  --context in-scope get ingress frontend-external-tls'

echo "Once your DNS has propagated you will be able to access your hipsterstore at ${DOMAIN_NAME}"

echo "Happy PCI-ing!"

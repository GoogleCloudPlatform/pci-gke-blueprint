#!/usr/bin/env bash

# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

source workstation.env

# Retrieve credentials, rename contexts:

export KUBECONFIG=${SRC_PATH}/${REPOSITORY_NAME}/private/kubeconfig
gcloud container clusters get-credentials in-scope      --region us-central1 --project ${TF_VAR_project_in_scope}
gcloud container clusters get-credentials out-of-scope  --region us-central1 --project ${TF_VAR_project_out_of_scope}
kubectx in-scope=gke_${TF_VAR_project_in_scope}_us-central1_in-scope
kubectx out-of-scope=gke_${TF_VAR_project_out_of_scope}_us-central1_out-of-scope

# Custom Istio Installation
## Download Istio

export ISTIO_VERSION=1.3.3
if  [ ! -d ${SRC_PATH}/istio-${ISTIO_VERSION} ]; then
  echo 'does not exist'
  cd ${SRC_PATH}
  wget https://github.com/istio/istio/releases/download/${ISTIO_VERSION}/istio-${ISTIO_VERSION}-linux.tar.gz
  tar -xzf istio-${ISTIO_VERSION}-linux.tar.gz
  rm istio-${ISTIO_VERSION}-linux.tar.gz
fi

## Install Istio custom resource definitions

for cluster in $(kubectx); do
  kubectx $cluster
  kubectl create namespace istio-system;
  kubectl create secret generic cacerts -n istio-system \
    --from-file=${SRC_PATH}/istio-${ISTIO_VERSION}/samples/certs/ca-cert.pem \
    --from-file=${SRC_PATH}/istio-${ISTIO_VERSION}/samples/certs/ca-key.pem \
    --from-file=${SRC_PATH}/istio-${ISTIO_VERSION}/samples/certs/root-cert.pem \
    --from-file=${SRC_PATH}/istio-${ISTIO_VERSION}/samples/certs/cert-chain.pem
  helm install istio-init \
    --kube-context $cluster \
    --namespace istio-system \
    ${SRC_PATH}/istio-${ISTIO_VERSION}/install/kubernetes/helm/istio-init
done

echo "Wait 60s"
sleep 60

## Install Istio in the in-scope cluster

helm install istio \
  --kube-context in-scope \
  --namespace istio-system \
  ${SRC_PATH}/istio-${ISTIO_VERSION}/install/kubernetes/helm/istio \
  --values ${SRC_PATH}/${REPOSITORY_NAME}/k8s/values-istio-multicluster-gateways.yml

## Install Istio in the out-of-scope cluster

helm install istio \
  --kube-context out-of-scope \
  --namespace istio-system \
  ${SRC_PATH}/istio-${ISTIO_VERSION}/install/kubernetes/helm/istio \
  --values ${SRC_PATH}/${REPOSITORY_NAME}/k8s/values-istio-multicluster-gateways-with-ilb.yml

## Set the kube-dns ConfigMap in both clusters

for cluster in $(kubectx); do
  kubectx $cluster
  kubectl apply -f - << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  labels:
      addonmanager.kubernetes.io/mode: EnsureExists
  name: kube-dns
  namespace: kube-system
data:
  stubDomains: |
    {"global": ["$(kubectl get svc -n istio-system istiocoredns -o jsonpath={.spec.clusterIP})"]}
EOF
done

# warnings from above command are safely ignored

## Verification steps

for cluster in $(kubectx)
do
  echo $cluster;
  kubectl --context $cluster  get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l; # output should be ~23
  kubectl --context $cluster -n kube-system get configmap kube-dns -o json | jq '.data';
  kubectl --context $cluster -n istio-system get service istio-ingressgateway # don't proceed until EXTERNAL-IP is set
done

# Hipster Shop Installation

# Retrieve a needed environment variable

export OUT_OF_SCOPE_INGRESS_GATEWAY_IP_ADDRESS=$(kubectl get \
 --context out-of-scope \
 --namespace istio-system \
 service istio-ingressgateway \
 -o jsonpath='{.status.loadBalancer.ingress[0].ip}' \
)
echo "OUT_OF_SCOPE_INGRESS_GATEWAY_IP_ADDRESS: $OUT_OF_SCOPE_INGRESS_GATEWAY_IP_ADDRESS"


# Add namespaces to both clusters
kubectl --context out-of-scope apply -f ${SRC_PATH}/${REPOSITORY_NAME}/k8s/namespaces/out-of-scope-namespace.yml
kubectl --context in-scope apply -f ${SRC_PATH}/${REPOSITORY_NAME}/k8s/namespaces/in-scope-namespace.yml

# Deploy the out-of-scope set of microservices:
helm install \
  --kube-context out-of-scope \
  --namespace out-of-scope \
  out-of-scope-microservices \
  ${SRC_PATH}/${REPOSITORY_NAME}/k8s/helm/out-of-scope-microservices

# Deploy the in-scope set of microservices:
helm install \
  --kube-context in-scope \
  --namespace in-scope \
  --set out_of_scope_ingress_gateway_ip_address=${OUT_OF_SCOPE_INGRESS_GATEWAY_IP_ADDRESS} \
  --set domain_name=${DOMAIN_NAME} \
  in-scope-microservices \
  ${SRC_PATH}/${REPOSITORY_NAME}/k8s/helm/in-scope-microservices

# verify managed certificate. This step can take up to 30 minutes to complete.
kubectl --context in-scope describe managedcertificates

# Verify ingress health. Take note of the backend health from ingress.kubernetes.io/backends
kubectl --context in-scope describe ingresses

# Verify application availability
# After ~3 minutes, The application should be accessible at $DOMAIN_NAME

curl -s -o /dev/null -I -w "%{http_code}" https://$DOMAIN_NAME # output should be 200
curl -s https://$DOMAIN_NAME | grep -q "One-stop for Hipster Fashion" ; echo $? # output should be 0
curl -Is http://$DOMAIN_NAME | head -1 # output should be "HTTP/1.1 301 Moved Permanently"

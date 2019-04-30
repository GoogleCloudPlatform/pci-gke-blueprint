#!/bin/bash -u

# Set vars as needed. eg.
#DEIDENTIFY_TEMPLATE_NAME="projects/pci-poc-in-scope/deidentifyTemplates/111111"
#FLUENTD_IMAGE_REMOTE_REPO="gcr.io/pci-poc-in-scope/fluentd:abababab"
#LOG_DESTINATION_PROJECT_ID="pci-poc-management"

sed "s#DEIDENTIFY_TEMPLATE_NAME#${DEIDENTIFY_TEMPLATE_NAME}#"     templates/fluentd-gcp-config-old-v1.2.5.yaml.tmpl > kubernetes-manifests-system/fluentd-gcp-config-old-v1.2.5.yaml
sed "s#LOG_DESTINATION_PROJECT_ID#${LOG_DESTINATION_PROJECT_ID}#" templates/fluentd-gcp-config-old-v1.2.5.yaml.tmpl > kubernetes-manifests-system/fluentd-gcp-config-old-v1.2.5.yaml
sed "s#FLUENTD_IMAGE_REMOTE_REPO#${FLUENTD_IMAGE_REMOTE_REPO}#"   templates/fluentd-daemonset-stock-gke.yaml.tmpl   > kubernetes-manifests-system/fluentd-daemonset-stock-gke.yaml

# Generates a kubernetes-manifests/ingress.yaml based on whether DOMAIN_NAME is set
# If unset, creates an ingress.yaml for a self-signed certificate
# else, creates an ingress.yaml that includes a ManagedCertificate resource based
# on the domain name. See docs/frontend-https.md

if [[ -z "$DOMAIN_NAME" ]] ; then
  cp templates/self-signed-cert.yaml kubernetes-manifests/ingress.yaml
else
  sed "s#DOMAIN_NAME#${DOMAIN_NAME}#" templates/managed-cert.yaml.tmpl > kubernetes-manifests/ingress.yaml
fi

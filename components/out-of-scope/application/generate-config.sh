#!/bin/bash -u

# Generates a kubernetes-manifests/ingress.yaml based on whether DOMAIN_NAME is set
# If unset, creates an ingress.yaml for a self-signed certificate
# else, creates an ingress.yaml that includes a ManagedCertificate resource based
# on the domain name. See docs/frontend-https.md


if [[ -z "$DOMAIN_NAME" ]] ; then
  cp templates/self-signed-cert.yaml kubernetes-manifests/ingress.yaml
else
  sed "s#DOMAIN_NAME#${DOMAIN_NAME}#" templates/managed-cert.yaml.tmpl > kubernetes-manifests/ingress.yaml
fi

# Set vars as needed.
#LOG_DESTINATION_PROJECT_ID="pci-poc-management"
sed "s#LOG_DESTINATION_PROJECT_ID#${LOG_DESTINATION_PROJECT_ID}#" templates/fluentd-gcp-config-old-v1.2.5.yaml.tmpl > kubernetes-manifests-system/fluentd-gcp-config-old-v1.2.5.yaml

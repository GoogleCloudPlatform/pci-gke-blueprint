#!/bin/bash -u

# Set vars as needed.
#LOG_DESTINATION_PROJECT_ID="pci-poc-management"
sed "s#LOG_DESTINATION_PROJECT_ID#${LOG_DESTINATION_PROJECT_ID}#" templates/fluentd-gcp-config-old-v1.2.5.yaml.tmpl > kubernetes-manifests-system/fluentd-gcp-config-old-v1.2.5.yaml

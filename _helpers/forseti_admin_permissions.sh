#!/bin/bash

# Fail fast when a command fails or a variable is undefined
set -eu

echo ""
echo "NOTE: Forseti requires broad permissions to operate."
echo "The Terraform service account needs organization-wide permissoins"
echo ""

echo "See <https://forsetisecurity.org/docs/v2.0/concepts/service-accounts.html#permissions>"
echo "for a full list of IAM roles that Forseti requires"
echo ""
echo "Preparing to execute with the following values:"
echo "==================================================="
echo "Admin Project: ${TF_ADMIN_PROJECT}"
echo "Organization: ${TF_VAR_org_id}"
echo "Billing Account: ${TF_VAR_billing_account}"
echo "Folder: ${TF_VAR_folder_id}"
echo "State Bucket: ${TF_ADMIN_BUCKET}"
echo "Credentials Path: ${TF_CREDS}"
echo "==================================================="
echo ""
echo "Continuing in 10 seconds. Ctrl+C to cancel"
sleep 10


gcloud organizations add-iam-policy-binding ${TF_VAR_org_id} \
  --member serviceAccount:terraform@${TF_ADMIN_PROJECT}.iam.gserviceaccount.com \
  --role roles/resourcemanager.organizationAdmin

gcloud organizations add-iam-policy-binding ${TF_VAR_org_id} \
  --member serviceAccount:terraform@${TF_ADMIN_PROJECT}.iam.gserviceaccount.com \
  --role roles/serviceusage.serviceUsageAdmin

gcloud organizations add-iam-policy-binding ${TF_VAR_org_id} \
  --member serviceAccount:terraform@${TF_ADMIN_PROJECT}.iam.gserviceaccount.com \
  --role roles/serviceusage.serviceAccountAdmin

gcloud alpha resource-manager folders add-iam-policy-binding ${TF_VAR_folder_id} \
  --member serviceAccount:terraform@${TF_ADMIN_PROJECT}.iam.gserviceaccount.com \
  --role roles/cloudsql.admin


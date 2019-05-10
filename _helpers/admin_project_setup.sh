#!/bin/bash

# Fail fast when a command fails or a variable is undefined
set -eu

echo ""
echo "Preparing Terraform resources and service account with the following values:"
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

echo "=> Creating project inside the folder ${TF_VAR_folder_id}"
gcloud alpha projects create ${TF_ADMIN_PROJECT} \
  --folder ${TF_VAR_folder_id}

echo "=> Linking ${TF_VAR_billing_account} Billing Account to your project"
gcloud beta billing projects link ${TF_ADMIN_PROJECT} \
  --billing-account=${TF_VAR_billing_account}

echo "=> Enabling required APIs"
gcloud --project ${TF_ADMIN_PROJECT} services enable container.googleapis.com
gcloud --project ${TF_ADMIN_PROJECT} services enable cloudresourcemanager.googleapis.com
gcloud --project ${TF_ADMIN_PROJECT} services enable cloudbilling.googleapis.com
gcloud --project ${TF_ADMIN_PROJECT} services enable iam.googleapis.com
gcloud --project ${TF_ADMIN_PROJECT} services enable admin.googleapis.com
gcloud --project ${TF_ADMIN_PROJECT} services enable sqladmin.googleapis.com

echo "=> Creating Terraform state bucket"
gsutil mb -p ${TF_ADMIN_PROJECT} gs://${TF_ADMIN_BUCKET}
gsutil versioning set on gs://${TF_ADMIN_BUCKET}

echo ""
echo "Admin resources created successfully"
echo ""
echo 'To continue with setting up a Terraform Service Account please run `helpers/setup_service_account.sh`'
echo ""


#!/bin/bash
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


# Fail fast when a command fails or a variable is undefined
set -eu

echo ""
echo "Preparing to execute with the following values:"
echo "==================================================="
echo "Admin Project: ${TF_ADMIN_PROJECT:?}"
echo "Organization: ${TF_VAR_org_id:?}"
echo "Billing Account: ${TF_VAR_billing_account:?}"
echo "Folder: ${TF_VAR_folder_id:?}"
echo "State Bucket: ${TF_ADMIN_BUCKET:?}"
echo "Credentials Path: ${GOOGLE_APPLICATION_CREDENTIALS:?}"
echo "==================================================="
echo ""
echo "Continuing in 10 seconds. Ctrl+C to cancel"
sleep 10


echo "=> Creating terraform service account"
gcloud iam service-accounts create terraform \
  --display-name "Terraform admin account" \
  --project "${TF_ADMIN_PROJECT}"

echo "=> Creating service account keys and saving to ${GOOGLE_APPLICATION_CREDENTIALS}"
gcloud iam service-accounts keys create "${GOOGLE_APPLICATION_CREDENTIALS}" \
  --iam-account "terraform@${TF_ADMIN_PROJECT}.iam.gserviceaccount.com"

echo "=> Binding IAM roles to service account"

# Add Viewer permissions for the Terraform Admin project
gcloud projects add-iam-policy-binding "${TF_ADMIN_PROJECT}" \
  --member "serviceAccount:terraform@${TF_ADMIN_PROJECT}.iam.gserviceaccount.com" \
  --role roles/viewer

# Enable Access Context Manager API for the Terraform Admin project
gcloud services --project ${TF_ADMIN_PROJECT} enable accesscontextmanager.googleapis.com

# Add Storage Admin permissions for the Terraform Admin project
gcloud projects add-iam-policy-binding "${TF_ADMIN_PROJECT}" \
  --member "serviceAccount:terraform@${TF_ADMIN_PROJECT}.iam.gserviceaccount.com" \
  --role roles/storage.admin

# Add accesscontextmanager.policyAdmin
gcloud organizations add-iam-policy-binding "${TF_VAR_org_id}" \
  --member "serviceAccount:terraform@${TF_ADMIN_PROJECT}.iam.gserviceaccount.com" \
  --role="roles/accesscontextmanager.policyAdmin"

# Add resourcemanager.organizationAdmin
gcloud organizations add-iam-policy-binding "${TF_VAR_org_id}" \
  --member "serviceAccount:terraform@${TF_ADMIN_PROJECT}.iam.gserviceaccount.com" \
  --role="roles/resourcemanager.organizationAdmin"

# Add orgpolicy.policyAdmin
gcloud organizations add-iam-policy-binding "${TF_VAR_org_id}" \
  --member "serviceAccount:terraform@${TF_ADMIN_PROJECT}.iam.gserviceaccount.com" \
  --role="roles/orgpolicy.policyAdmin"

# Add billing admin
gcloud organizations add-iam-policy-binding "${TF_VAR_org_id}" \
  --member "serviceAccount:terraform@${TF_ADMIN_PROJECT}.iam.gserviceaccount.com" \
  --role="roles/billing.admin"

# Add Storage Admin permissions to entire Folder
gcloud resource-manager folders add-iam-policy-binding "${TF_VAR_folder_id}" \
  --member "serviceAccount:terraform@${TF_ADMIN_PROJECT}.iam.gserviceaccount.com" \
  --role roles/storage.admin

# Add Container cluster admin permissions to entire Folder
gcloud resource-manager folders add-iam-policy-binding "${TF_VAR_folder_id}" \
  --member "serviceAccount:terraform@${TF_ADMIN_PROJECT}.iam.gserviceaccount.com" \
  --role roles/container.admin

# Add serviceusage.serviceUsageAdmin
gcloud resource-manager folders add-iam-policy-binding "${TF_VAR_folder_id}" \
  --member "serviceAccount:terraform@${TF_ADMIN_PROJECT}.iam.gserviceaccount.com" \
  --role roles/serviceusage.serviceUsageAdmin

# Add IAM serviceAccountUser permissions to entire Folder
gcloud resource-manager folders add-iam-policy-binding "${TF_VAR_folder_id}" \
  --member "serviceAccount:terraform@${TF_ADMIN_PROJECT}.iam.gserviceaccount.com" \
  --role roles/iam.serviceAccountUser

# Add Project Creator permissions to entire Folder
gcloud resource-manager folders add-iam-policy-binding "${TF_VAR_folder_id}" \
  --member "serviceAccount:terraform@${TF_ADMIN_PROJECT}.iam.gserviceaccount.com" \
  --role roles/resourcemanager.projectCreator

gcloud resource-manager folders add-iam-policy-binding "${TF_VAR_folder_id}" \
  --member "serviceAccount:terraform@${TF_ADMIN_PROJECT}.iam.gserviceaccount.com" \
  --role roles/resourcemanager.folderIamAdmin

# Add Billing Project Manager permissions to all projects in Folder
gcloud resource-manager folders add-iam-policy-binding "${TF_VAR_folder_id}" \
  --member "serviceAccount:terraform@${TF_ADMIN_PROJECT}.iam.gserviceaccount.com" \
  --role roles/billing.projectManager

# Add Compute Admin permissions to all projects in Folder
gcloud resource-manager folders add-iam-policy-binding "${TF_VAR_folder_id}" \
  --member "serviceAccount:terraform@${TF_ADMIN_PROJECT}.iam.gserviceaccount.com" \
  --role roles/compute.admin

# Add Shared VPC Admin permissions to all projects in Folder
gcloud resource-manager folders add-iam-policy-binding "${TF_VAR_folder_id}" \
  --member "serviceAccount:terraform@${TF_ADMIN_PROJECT}.iam.gserviceaccount.com" \
  --role roles/compute.xpnAdmin

echo "=> Setting up IAM roles for StackDriver Logging"

gcloud resource-manager folders add-iam-policy-binding "${TF_VAR_folder_id}" \
  --member "serviceAccount:terraform@${TF_ADMIN_PROJECT}.iam.gserviceaccount.com" \
  --role roles/logging.configWriter

echo ""
echo "Service Account set up successfully"
echo ""
echo 'To continue setting up permissions for Forseti please run "./_helpers/forseti_admin_permissions.sh"'
echo ""

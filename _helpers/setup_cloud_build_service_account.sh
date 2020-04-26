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

cloud_build_service_account=$1

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


echo "=> Binding IAM roles to service account"

# Add Viewer permissions for the Terraform Admin project
gcloud projects add-iam-policy-binding "${TF_ADMIN_PROJECT}" \
  --member "serviceAccount:$cloud_build_service_account" \
  --role roles/viewer

# Enable Access Context Manager API for the Terraform Admin project
gcloud services --project ${TF_ADMIN_PROJECT} enable accesscontextmanager.googleapis.com

# Add Storage Admin permissions for the Terraform Admin project
gcloud projects add-iam-policy-binding "${TF_ADMIN_PROJECT}" \
  --member "serviceAccount:$cloud_build_service_account" \
  --role roles/storage.admin

# Add accesscontextmanager.policyAdmin
gcloud organizations add-iam-policy-binding "${TF_VAR_org_id}" \
  --member "serviceAccount:$cloud_build_service_account" \
  --role="roles/accesscontextmanager.policyAdmin"

# Add resourcemanager.organizationAdmin
gcloud organizations add-iam-policy-binding "${TF_VAR_org_id}" \
  --member "serviceAccount:$cloud_build_service_account" \
  --role="roles/resourcemanager.organizationAdmin"

# Add orgpolicy.policyAdmin
gcloud organizations add-iam-policy-binding "${TF_VAR_org_id}" \
  --member "serviceAccount:$cloud_build_service_account" \
  --role="roles/orgpolicy.policyAdmin"

# Add billing admin
gcloud organizations add-iam-policy-binding "${TF_VAR_org_id}" \
  --member "serviceAccount:$cloud_build_service_account" \
  --role="roles/billing.admin"

# Add Storage Admin permissions to entire Folder
gcloud resource-manager folders add-iam-policy-binding "${TF_VAR_folder_id}" \
  --member "serviceAccount:$cloud_build_service_account" \
  --role roles/storage.admin

# Add Container cluster admin permissions to entire Folder
gcloud resource-manager folders add-iam-policy-binding "${TF_VAR_folder_id}" \
  --member "serviceAccount:$cloud_build_service_account" \
  --role roles/container.admin

# Add serviceusage.serviceUsageAdmin
gcloud resource-manager folders add-iam-policy-binding "${TF_VAR_folder_id}" \
  --member "serviceAccount:$cloud_build_service_account" \
  --role roles/serviceusage.serviceUsageAdmin

# Add IAM serviceAccountUser permissions to entire Folder
gcloud resource-manager folders add-iam-policy-binding "${TF_VAR_folder_id}" \
  --member "serviceAccount:$cloud_build_service_account" \
  --role roles/iam.serviceAccountUser

# Add Project Creator permissions to entire Folder
gcloud resource-manager folders add-iam-policy-binding "${TF_VAR_folder_id}" \
  --member "serviceAccount:$cloud_build_service_account" \
  --role roles/resourcemanager.projectCreator

gcloud resource-manager folders add-iam-policy-binding "${TF_VAR_folder_id}" \
  --member "serviceAccount:$cloud_build_service_account" \
  --role roles/resourcemanager.folderIamAdmin

# Add Billing Project Manager permissions to all projects in Folder
gcloud resource-manager folders add-iam-policy-binding "${TF_VAR_folder_id}" \
  --member "serviceAccount:$cloud_build_service_account" \
  --role roles/billing.projectManager

# Add Compute Admin permissions to all projects in Folder
gcloud resource-manager folders add-iam-policy-binding "${TF_VAR_folder_id}" \
  --member "serviceAccount:$cloud_build_service_account" \
  --role roles/compute.admin

# Add Shared VPC Admin permissions to all projects in Folder
gcloud resource-manager folders add-iam-policy-binding "${TF_VAR_folder_id}" \
  --member "serviceAccount:$cloud_build_service_account" \
  --role roles/compute.xpnAdmin

echo "=> Setting up IAM roles for StackDriver Logging"

gcloud resource-manager folders add-iam-policy-binding "${TF_VAR_folder_id}" \
  --member "serviceAccount:$cloud_build_service_account" \
  --role roles/logging.configWriter

echo ""
echo "Service Account set up successfully"
echo ""
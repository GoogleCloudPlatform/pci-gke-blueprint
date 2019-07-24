#!/bin/bash
# Copyright 2019 Google LLC
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
echo "NOTE: Forseti requires broad permissions to operate."
echo "The Terraform service account needs organization-wide permissoins"
echo ""

echo "See <https://forsetisecurity.org/docs/v2.0/concepts/service-accounts.html#permissions>"
echo "for a full list of IAM roles that Forseti requires"
echo ""
echo "Preparing to execute with the following values:"
echo "==================================================="
echo "Admin Project: ${TF_ADMIN_PROJECT:?}"
echo "Organization: ${TF_VAR_org_id:?}"
echo "Billing Account: ${TF_VAR_billing_account:?}"
echo "Folder: ${TF_VAR_folder_id:?}"
echo "State Bucket: ${TF_ADMIN_BUCKET:?}"
echo "Credentials Path: ${TF_CREDS:?}"
echo "==================================================="
echo ""
echo "Continuing in 10 seconds. Ctrl+C to cancel"
sleep 10


gcloud organizations add-iam-policy-binding "${TF_VAR_org_id}" \
  --member "serviceAccount:terraform@${TF_ADMIN_PROJECT}.iam.gserviceaccount.com" \
  --role roles/resourcemanager.organizationAdmin

gcloud organizations add-iam-policy-binding "${TF_VAR_org_id}" \
  --member "serviceAccount:terraform@${TF_ADMIN_PROJECT}.iam.gserviceaccount.com" \
  --role roles/serviceusage.serviceUsageAdmin

gcloud alpha resource-manager folders add-iam-policy-binding "${TF_VAR_folder_id}" \
  --member "serviceAccount:terraform@${TF_ADMIN_PROJECT}.iam.gserviceaccount.com" \
  --role roles/iam.serviceAccountAdmin

gcloud alpha resource-manager folders add-iam-policy-binding "${TF_VAR_folder_id}" \
  --member "serviceAccount:terraform@${TF_ADMIN_PROJECT}.iam.gserviceaccount.com" \
  --role roles/cloudsql.admin


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
gcloud beta builds triggers create github \
--repo-name=KonradSchieban/pci-gke-blueprint \
--repo-owner=KonradSchieban \
--description 'CICD' \
--branch-pattern='^feature/cicd$' \
--build-config=cicd/cloudbuild.yaml \



#--substitutions _ALWAYS_REPORT=true,_ENABLE_HELLOWORLD=true,_ENABLE_HIPSTERSTORE=true,\
#_INSCOPE_PROJECT_ID=$YOUR_MAIN_PROJECT,_INSCOPE_SA_EMAIL=project-service-account@$YOUR_MAIN_PROJECT.iam.gserviceaccount.com,\
#_INTEGRATION_TEST_PROJECT=$YOUR_STAGING_PROJECT,_IS_SHARED_VPC_HOST=false,\
#_KEY_NAME=terraform-cicd,_KEYRING=cicd,\
#_NETWORK_PROJECT_ID=$YOUR_MAIN_PROJECT,_PCI_PROFILE_GCR_PROJECT=$YOUR_MAIN_PROJECT,\
#_PROJECT_PREFIX="",_REPORT_BUCKET=$YOUR_MAIN_PROJECT-terraform-admin,\
#_RUN_APPLY=true,_SECRETS_BUCKET=$YOUR_MAIN_PROJECT-terraform-admin,\
#_TERRAFORM_ADMIN_BUCKET=$YOUR_MAIN_PROJECT-terraform-admin,\
#_KMS_LOCATION=us-central1
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

# Set up the admin resources run
echo 'Setting up the Terraform Admin Project'

# Source the environment setup file you created previously
source ./workstation.env

# Create the Admin project
./_helpers/admin_project_setup.sh

# Create the Terraform service account
./_helpers/setup_service_account.sh

# run terraform
sed "s/<SET TO THE VALUE OF TF_ADMIN_BUCKET>/${TF_ADMIN_BUCKET}/" terraform/infrastructure/backend.tf.example > terraform/infrastructure/backend.tf
pushd terraform/infrastructure
terraform init
terraform plan -out terraform.out
terraform apply terraform.out
popd

# DNS
echo "Update your DNS settings such that"
echo "dig NS <frontend_zone_dns_name> from the terraform output"
echo "equals the <nameservers> from the terraform output"

#Example:
# from the output of  "terraform apply":
# frontend_zone_dns_name = a.example.com
# nameservers = [
#   "ns-cloud-d1.googledomains.com.",
#   "ns-cloud-d2.googledomains.com.",
#   "ns-cloud-d3.googledomains.com.",
#   "ns-cloud-d4.googledomains.com.",
# ]
# $ dig +noall +answer  NS a.example.com
# a.gcpsecurity.solutions. 3600	IN	NS	ns-cloud-d4.googledomains.com.
# a.gcpsecurity.solutions. 3600	IN	NS	ns-cloud-d2.googledomains.com.
# a.gcpsecurity.solutions. 3600	IN	NS	ns-cloud-d3.googledomains.com.
# a.gcpsecurity.solutions. 3600	IN	NS	ns-cloud-d1.googledomains.com.

echo "continue with deploy-app.sh"

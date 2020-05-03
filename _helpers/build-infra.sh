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

usage() {
	echo "Usage: build-infra [-ach] "
	echo
	echo "Builds infrastructure of pci-gke-blueprint"
	echo
	echo "  -c (optional)     Running script in continuous integration and skipping service account creation"
	echo "  -a (optional)     Admin project setup will be skipped"
	echo "  -h (optional)     Print this help menu"
}

unset run_type skip_admin_project
skip_admin_project=false

while getopts 'ach' c
do
	case $c in
		c) run_type="cicd";;
		a) skip_admin_project=true;;
		h|?)
		  usage
		  exit 2
		  ;;
	esac
done

# Source the environment setup file you created previously
source ./workstation.env

if [ "$skip_admin_project" = "false" ];then
  # Set up the admin resources run
  echo 'Setting up the Terraform Admin Project'

  # Create the Admin project
  ./_helpers/admin_project_setup.sh
fi

if [ "$run_type" = "cicd" ];then
  # Prepare CloudBuild service account
  cloud_build_service_account=`gcloud config get-value account`
  ./_helpers/setup_cloud_build_service_account.sh $cloud_build_service_account
else
  # Create the Terraform service account
  ./_helpers/setup_service_account.sh
fi

# run terraform
sed "s/<SET TO THE VALUE OF TF_ADMIN_BUCKET>/${TF_ADMIN_BUCKET}/" terraform/infrastructure/backend.tf.example > terraform/infrastructure/backend.tf
pushd terraform/infrastructure
terraform init
terraform plan -out terraform.out
terraform apply terraform.out
if [ $? -ne 0 ];then
  echo "Terraform apply failed. Aborting..."
  if [ "$run_type" = "cicd" ];then
    terraform destroy -auto-approve
  fi
  exit 1
fi
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

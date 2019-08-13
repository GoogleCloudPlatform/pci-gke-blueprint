#/usr/bin/env bash -ax

# Set up the admin resources run
echo 'Setting up the Terraform Admin Project'

# Source the environment setup file you created previously
source ./workstation.env

# Create the Admin project
./_helpers/admin_project_setup.sh

# Create the Terraform service account
./_helpers/setup_service_account.sh

# Add Forseti-specific permissions to the service account
./_helpers/forseti_admin_permissions.sh

# create the component projects
echo 'Creating the component projects'

cp terraform/shared.tf.example terraform/shared.tf.local
pushd terraform/projects/
./build.sh
popd

echo "Verifying that 4 projects have been created."
gcloud projects list --filter="parent.id=${TF_VAR_folder_id}" | grep ${TF_VAR_project_prefix}

# test to make sure the correct number of projects were created
if [ `gcloud projects list --filter="parent.id=${TF_VAR_folder_id}" | grep ${TF_VAR_project_prefix} | wc -l` -ne 4 ] ; then
  echo 'Something went wrong there should be 4 projects listed'
  exit 1
fi

# setup component infra
echo 'Setting up the component infrastructure'

pushd terraform/components
./build.sh
popd

echo "Verifying that in-scope and out-of-scope clusters have been created."
gcloud beta container clusters list --project=${TF_VAR_project_prefix}-in-scope
gcloud beta container clusters list --project=${TF_VAR_project_prefix}-out-of-scope

if [ `gcloud beta container clusters list --project=${TF_VAR_project_prefix}-out-of-scope | grep scope | wc -l` -ne 1 ] ; then
  echo 'Something went wrong the out-of-scope cluster was not created'
  exit 1
fi

if [ `gcloud beta container clusters list --project=${TF_VAR_project_prefix}-in-scope | grep scope | wc -l` -ne 1 ] ; then
  echo 'Something went wrong the in-scope cluster was not created'
  exit 1
fi

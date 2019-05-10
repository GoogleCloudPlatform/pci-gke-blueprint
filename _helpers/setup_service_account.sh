# Fail fast when a command fails or a variable is undefined
set -eu

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


echo "=> Creating terraform service account"
gcloud iam service-accounts create terraform \
  --display-name "Terraform admin account"
  --project ${TF_ADMIN_PROJECT}

echo "=> Creating service account keys and saving to ${TF_CREDS}"
gcloud iam service-accounts keys create ${TF_CREDS} \
  --iam-account terraform@${TF_ADMIN_PROJECT}.iam.gserviceaccount.com


echo "=> Binding IAM roles to service account"
# Add Viewer permissions for the Terraform Admin project
gcloud projects add-iam-policy-binding ${TF_ADMIN_PROJECT} \
  --member serviceAccount:terraform@${TF_ADMIN_PROJECT}.iam.gserviceaccount.com \
  --role roles/viewer

# Add Storage Admin permissions for the Terraform Admin project
gcloud projects add-iam-policy-binding ${TF_ADMIN_PROJECT} \
  --member serviceAccount:terraform@${TF_ADMIN_PROJECT}.iam.gserviceaccount.com \
  --role roles/storage.admin

# Add Storage Admin permissions to entire Folder
gcloud alpha resource-manager folders add-iam-policy-binding ${TF_VAR_folder_id} \
  --member serviceAccount:terraform@${TF_ADMIN_PROJECT}.iam.gserviceaccount.com \
  --role roles/storage.admin

# Add Container cluster admin permissions to entire Folder
gcloud alpha resource-manager folders add-iam-policy-binding ${TF_VAR_folder_id} \
  --member serviceAccount:terraform@${TF_ADMIN_PROJECT}.iam.gserviceaccount.com \
  --role roles/container.admin

# Add IAM serviceAccountUser permissions to entire Folder
gcloud alpha resource-manager folders add-iam-policy-binding ${TF_VAR_folder_id} \
  --member serviceAccount:terraform@${TF_ADMIN_PROJECT}.iam.gserviceaccount.com \
  --role roles/iam.serviceAccountUser

# Add Project Creator permissions to entire Folder
gcloud alpha resource-manager folders add-iam-policy-binding ${TF_VAR_folder_id} \
  --member serviceAccount:terraform@${TF_ADMIN_PROJECT}.iam.gserviceaccount.com \
  --role roles/resourcemanager.projectCreator

# Add Billing Project Manager permissions to all projects in Folder
gcloud alpha resource-manager folders add-iam-policy-binding ${TF_VAR_folder_id} \
  --member serviceAccount:terraform@${TF_ADMIN_PROJECT}.iam.gserviceaccount.com \
  --role roles/billing.projectManager

# Add Compute Admin permissions to all projects in Folder
gcloud alpha resource-manager folders add-iam-policy-binding ${TF_VAR_folder_id} \
  --member serviceAccount:terraform@${TF_ADMIN_PROJECT}.iam.gserviceaccount.com \
  --role roles/compute.admin

# Add Shared VPC Admin permissions to all projects in Folder
gcloud alpha resource-manager folders add-iam-policy-binding ${TF_VAR_folder_id} \
  --member serviceAccount:terraform@${TF_ADMIN_PROJECT}.iam.gserviceaccount.com \
  --role roles/compute.xpnAdmin

echo "=> Setting up IAM roles for StackDriver Logging"

gcloud alpha resource-manager folders add-iam-policy-binding ${TF_VAR_folder_id} \
  --member serviceAccount:terraform@${TF_ADMIN_PROJECT}.iam.gserviceaccount.com \
  --role roles/logging.configWriter

echo ""
echo "Service Account set up successfully"
echo ""
echo 'To continue setting up permissions for Forseti please run `helpers/forseti_admin_permissions.sh`'
echo ""


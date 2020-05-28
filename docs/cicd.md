# CICD for PCI-GKE Blueprint

The PCI-GKE Blueprint can be deployed in a CICD pipeline using Cloud Build to continuously
deploy and validate the infrastructure on GCP. In addition to deploying the infrastructure
using Terraform, Chef InSpec is used to run a profile of compliance controls to validate
the in-scope project against the PCI-DSS benchmark (https://github.com/GoogleCloudPlatform/inspec-gcp-pci-profile).

After running the InSpec profile against the in-scope project Cloud Build will store the
report in json and html format inside a Cloud Storage bucket for review.

## Setup steps

### Inspec-gcp-pci-benchmark Container
Before setting up the pipeline in Cloud Build a container needs to be created that contains
the Inspec profile. Clone the PCI benchmark repo into a directory outside the pci-gke 
blueprint:

`git clone https://github.com/GoogleCloudPlatform/inspec-gcp-pci-profile.git`

A container needs to be created which runs the InSpec profile in the pipeline. 
Build a container by running:

`docker build . -t gcr.io/<project_id>/inspec-gcp-pci-profile:<version>`

Push the Docker container to the Google Container Registry:

`docker push gcr.io/<project_id>/inspec-gcp-pci-profile:<version>`

### Prerequisites
* The Cloud Build service account requires the organization admin and folder admin on
organization level.
* The Cloud Build service account needs to have the Cloud Billing User role on the Billing account.
* The Cloud Build service account needs to have the Project Creator role on folder level.
* The Cloud Build service account needs to be a domain owner of the front-end domain that you
specify in the workstation.env file.
* Enable the Context Manager and Cloud Billing API in the project in which you create the Cloud Build
pipeline.
* If you are specifying an existing admin project in the pipeline setup (parameter `_TF_ADMIN_PROJECT`),
make sure the Cloud Build service account has the Project Owner role on the admin project.

### Cloud Build Pipeline setup
Navigate to Cloud Build in the GCP console and wait until the API is enabled (if not already done).
Connect to the repository that contains the code for the PCI-GKE-blueprint (e.g. a fork of the
upstream repository or a separate clone in Google Cloud Source Repositories).

Define a trigger for Cloud Build. For the Build configuration enter `cicd/cloudbuild.yml`.
Create the following Substitution variables and enter values according to the workstation.env file:
* _GCR_PROJECT_ID
* _GOOGLE_GROUPS_DOMAIN
* _REPORTS_BUCKET
* _TF_ADMIN_BUCKET
* _TF_ADMIN_PROJECT
* _TF_VAR_BILLING_ACCOUNT
* _TF_VAR_FOLDER_ID
* _TF_VAR_FRONTEND_ZONE_DNS_NAME
* _TF_VAR_GSUITE_ID
* _TF_VAR_ORG_ID
* _TF_VAR_PROJECT_PREFIX
* _DESTROY_INFRA_AFTER_CREATE

The variable _REPORTS_BUCKET is the GCS bucket which will contain the InSpec report files in json
and html format. Make sure that the Cloud Build service account has the Cloud Storage Admin role
on the bucket that you specify.

The variable _DESTROY_INFRA_AFTER_CREATE is boolean (`false` or `true`) and determines whether the
infrastructure should be destroyed as final step of the pipeline execution.
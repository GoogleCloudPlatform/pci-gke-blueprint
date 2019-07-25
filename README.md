# PCI Starter

![high level project view](docs/diagrams/highlevel_project_view.png)

This repository contains a set of Terraform configurations and scripts to help
demonstrate how to bootstrap a PCI environment in GCP. When appropriate, we
also showcase GCP services, tools, or projects we think might be useful to
start your own GCP PCI environment or as samples for any other purposes.

Here are the projects/services we make use of in this demo:

- Terraform
- Docker
- Helm
- Kubernetes
- Google Kubernetes Engine
- Forseti
- StackDriver
- Google-managed SSL Certificates
- Cloud Data Loss Prevention
- Cloud Storage
- Cloud Security Command Center
- GoogleCloudPlatform/microservices-demo
- Fluentd
- Nginx



## Table of Contents
* [Prerequisites](#prerequisites)
  * [Installation Dependencies](#installation-dependencies)
  * [GCP IAM Requirements](#gcp-iam-requirements)
* [Workstation Configuration](#workstation-configuration)
* [Project Creation](#project-creation)
  * [Terraform Admin Project](#terraform-admin-project)
  * [Component Projects](#component-projects)
* [Setup Component Infrastructure](#setup-component-infrastructure)
  * [GKE Cluster Creation](#gke-cluster-creation)
  * [Logging Setup](#logging-setup)
* [Prepare Application Deployment](#prepare-application-deployment)
  * [Retrieve Cluster Credentials and Configure Custom Contexts](#retrieve-cluster-credentials-and-configure-custom-contexts)
  * [Create a Sample TLS Certificate Key to Use in the GKE Clusters](#create-a-sample-tls-certificatekey-to-use-in-the-gke-clusters)
  * [Configure Cloud Data Loss Prevention Integration](#configure-cloud-data-loss-prevention-integration)
  * [Helm Installation and Setup](#helm-installation-and-setup)
* [Application Deployment](#application-deployment)
  * [Deploy Fluentd Logger](#deploy-fluentd-logger)
  * [Deploy the "out-of-scope" Microservices](#deploy-the-out-of-scope-microservices)
  * [Deploy the DLP-Fluentd Logger](#deploy-the-dlp-fluentd-logger)
  * [Deploy the "in-scope" Microservices](#deploy-the-in-scope-microservices)
  * [Forseti Install and Setup](#forseti-install-and-setup)
* [List of Included Features](#list-of-included-features)
  * [Google Managed SSL Certificates](/docs/frontend-https.md)
  * [Automated Redaction of Credit Card data via the Data Loss Prevention API](/docs/dlp.md)
  * [Encrypted Cross-cluster communication with Nginx’s grpc_proxy](/docs/grpc-proxying.md)
  * [Customized Fluentd with Centralized Stackdriver Logging](/docs/fluentd.md)
  * [Forseti and Cloud Security Command Center](/docs/forseti.md)
  * [Audit and Flow Logs](/docs/audit-flow-logs.md)
* [Architecture](#architecture)
* [Development](#development)
* [Known Issues and Limitations](#known-issues-and-limitations)

## Prerequisites

Before starting, we need to make sure that our local environment is configured
correctly. We need to make sure we have the correct tools and a GCP account
with the correct permissions.

### Installation Dependencies
- [Terraform](https://www.terraform.io/downloads.html)
- [gcloud](https://cloud.google.com/sdk/gcloud/)
- [Docker](https://docs.docker.com/install/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [helm](https://helm.sh/docs/using_helm/)

### GCP IAM Requirements

In order to execute this module you will need to create a Service Account with
the following roles:

- Project Setup
    - roles/resourcemanager.projectCreator on the folder
    - roles/billing.projectManager on the folder
    - roles/resourcemanager.projectIamAdmin on the folder
    - roles/storage.admin on the folder
    - roles/browser on the folder
- Networking
    - roles/compute.xpnAdmin on the folder
- GKE Clusters
    - roles/container.admin on the folder
    - roles/iam.serviceAccountUser on the folder
- Forseti Permissions
    - roles/serviceusage.serviceUsageAdmin on the organization
    - roles/iam.serviceAccountAdmin on the organization
    - roles/cloudsql.admin on the folder

Before continuing, make sure you have permissions to create this Service Account.

## Workstation Configuration

Before starting the demo creation, create a file called `workstation.env` with the
following, making sure to replace any values to match your environment. This
project comes with a `workstation.env.example` file you can copy to get
started.

You can find the values for `YOUR_ORG_ID` and `YOUR_BILLING_ACCOUNT_ID` using the following commands:
```
gcloud organizations list
gcloud beta billing accounts list
```
To create a folder follow these [instructions](https://cloud.google.com/resource-manager/docs/creating-managing-folders).

    # Choose your Organization
    export TF_VAR_org_id=YOUR_ORG_ID

    # Choose your Billing Account
    export TF_VAR_billing_account=YOUR_BILLING_ACCOUNT_ID

    # Folder that contains all projects for this demo
    # If an appropriate folder doesn't already exist, please create one before
    # continuing
    export TF_VAR_folder_id=YOUR_PROJECT_FOLDER

    # The Project ID where Terraform state and service accounts are created.
    export TF_ADMIN_PROJECT=${USER}-terraform-admin

    # Set bucket name for State files
    export TF_ADMIN_BUCKET=${USER}-terraform-admin

    # Set the path to the service account credentials file
    export TF_CREDS=~/.config/gcloud/${USER}-terraform-admin.json

    # Set default application credentials
    export GOOGLE_APPLICATION_CREDENTIALS="${TF_CREDS}"

    # Override the following project prefix if desired
    export TF_VAR_project_prefix=pci-poc

    # Set a domain name to use for self-signed or managed certificates.
    # If you are using GCP managed certificates, make sure to pick a domain
    # that you can control DNS records for
    # export DOMAIN_NAME=myhipsterstore.example.com

    # The name of the DLP De-identification template
    # You will set this later in the demo instructions.
    # export DEIDENTIFY_TEMPLATE_NAME=TBD

    # The remote repository for the customized Fluentd Image
    # You will set this later in the demo instructions.
    # export FLUENTD_IMAGE_REMOTE_REPO=TBD

Remember to always `source` this file before executing any of the steps in this demo!


## Project Creation

After configuring your local environment, we will now create the GCP projects
needed for the demo starting with the Terraform Admin project.


### Terraform Admin Project

The first project to create is a special administrative project where Terraform
resources are kept. The most important resource will be the Cloud Storage
bucket that will contain the Terraform state files.

The following steps script out the creation of this project, resources, service
account, and IAM bindings required for the demo. Though we recommend creating a
new Terraform-specific service account to build this demo, you may want to
consult your organization's internal GCP team to determine the best way to run
this demo.

To set up the admin resources run the following commands:

    # Source the environment setup file you created previously
    source workstation.env

    # Create the Admin project
    ./_helpers/admin_project_setup.sh

    # Create the Terraform service account
    ./_helpers/setup_service_account.sh

    # Add Forseti-specific permissions to the service account
    ./_helpers/forseti_admin_permissions.sh

### Component Projects

There 4 several GCP projects to create:

* network
* management
* in-scope
* out-of-scope

Each of these projects is in a separate folder under `terraform/projects/`.

**NOTE:**  **It's important to source the `workstation.env` file before running any
`terraform` commands.**  The `TF_VAR_` environment varibles will override their
respective terraform variables. For example, `TF_VAR_billing_account` will
override the terraform variable, `billing_account`.

1. Copy the `terraform/shared.tf.example` file to a new file at
`terraform/shared.tf.local`.
1. Change to the `terraform/projects/` directory
1. Execute the `build.sh` script
1. Verify the 4 projects have been created:
`gcloud projects list --filter="parent.id=${TF_VAR_folder_id}"`


## Setup Component Infrastructure

After creating the GCP projects, this section walks through creation of various
resources that act as the infrastructure for a sample microservice
architecture.

**NOTE:** It's important to source the top-level `workstation.env` file before running any
of these steps. This will make sure your environment variables are consistent
and correct throughout the process.

We create two Kubernetes clusters running on Google Kubernetes Engine. One
cluster is marked for running services in scope of PCI compliance and another
cluster for non-PCI resources.

1. Change directories to `terraform/components`
1. Execute the `build.sh` script
1. To verify navigate to the "[Kubernetes Engine](https://console.cloud.google.com/kubernetes/list)"
section of Google Cloud Console. There should be one cluster called `in-scope`
in your "In Scope" project and one cluster called `out-of-scope` for the Out of
Scope project.
1. Verify by checking the [Cloud Storage](https://console.cloud.google.com/storage/browser) browser
of the Management project. There should be a new logging bucket that (within
the next 30 minutes) should populate with exported logs from your In Scope
project.

## Prepare Application Deployment

The sample application chosen for this demo is the [Hipster Store Demo](https://github.com/GoogleCloudPlatform/microservices-demo)

In this section, we'll deploy a custom version of this Hipster Store that
separates any microservices that interact with Cardholder Data from those that
don't.

You can view a public, running version of the demo store [here](http://35.238.163.103)

### Retrieve Cluster Credentials and Configure Custom Contexts

Each cluster's credentials need to be retrieved so we can execute commands on
the two Kubernetes clusters. We will also set up [custom contexts](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)
to simplify working with multiple clusters.

First, let's use [gcloud container clusters get-credentials](https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubect)
to set up `kubectl`'s configuration for the `in-scope` cluster and activate its
context and rename to the more user-friendly `in-scope`:

```
gcloud container clusters get-credentials in-scope --zone us-central1-a --project ${TF_VAR_project_prefix}-in-scope
kubectl config rename-context $(kubectl config current-context) in-scope
```

Repeat the same for the `out-of-scope` cluster:

```
gcloud container clusters get-credentials out-of-scope --zone us-central1-a --project "${TF_VAR_project_prefix}-out-of-scope"
kubectl config rename-context $(kubectl config current-context) out-of-scope
```

You can now target a specific cluster with `kubectl` by applying `--context` to
the command. For example, `kubectl --context in-scope cluster-info` will return
cluster info on the `in-scope` cluster even if the current context is something
else.

This will help us in the next section when we create self-signed certificates
to encrypt traffic between our clusters.


### Create a Sample TLS Certificate+Key to Use in the GKE Clusters

Based on [Using multiple SSL certificates in HTTP(s) load balancing with Ingress](https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-multi-ssl#specifying_certificates_for_your_ingress).

These steps will generate an SSL key+certificate pair and deploy to the
Kubernetes cluster as a secret. This secret can be used for encrypting traffic
across the two clusters.

**NOTE:** In a real environment, it wouldn't be recommended to use a
self-signed certificate. Please follow your organization's policy guidelines
for creating and managing private keys. This is for demonstration purposes
only.

First, generate a self-signed certificate and key:

```
openssl genrsa -out hipsterservice.key 2048
openssl req -new -key hipsterservice.key -out hipsterservice.csr \
    -subj "/CN=$DOMAIN_NAME"
openssl x509 -req -days 365 -in hipsterservice.csr -signkey hipsterservice.key \
    -out hipsterservice.crt
```
Create a Secret that holds your certificate and key:

```
kubectl --context out-of-scope create secret tls tls-hipsterservice \
  --cert hipsterservice.crt --key hipsterservice.key

kubectl --context in-scope create secret tls tls-hipsterservice \
  --cert hipsterservice.crt --key hipsterservice.key
```

Verify success of the above with:

```
$ kubectl --context out-of-scope describe secrets tls-hipsterservice
Name:         tls-hipsterservice
Namespace:    default
Labels:       <none>
Annotations:  <none>

Type:  kubernetes.io/tls

Data
====
tls.crt:  1021 bytes
tls.key:  1675 bytes

```

```
$ kubectl --context in-scope describe secrets tls-hipsterservice
Name:         tls-hipsterservice
Namespace:    default
Labels:       <none>
Annotations:  <none>

Type:  kubernetes.io/tls

Data
====
tls.crt:  1021 bytes
tls.key:  1675 bytes
```

###  Data Loss Prevention API Configuration

This section walks through creating a Data Loss Prevention template and
utilizing it to mask sensitive cardholder data from StackDriver logs. See
[DLP API](docs/dlp.md).

#### Create a DLP De-identification Template

**Documentation**: [Creating Cloud DLP de-identification templates](https://cloud.google.com/dlp/docs/creating-templates-deid)

A deidentification template needs to be created to pass to the DLP API filter
configuration. There are multiple methods for creating the template. The method
used here is the GCP documentation's API Explorer.

1. In a browser, navigate to https://cloud.google.com/dlp/docs/reference/rest/v2/projects.deidentifyTemplates/create
1. In the sidebar, in the "Request parameters" section, in the `parent` field,
enter `projects/<YOUR_INSCOPE_PROJECT>` eg. `projects/pci-poc-in-scope`
1. In the request field, enter these values:
  {
    "deidentifyTemplate": {
       "deidentifyConfig": {
           "infoTypeTransformations": {
             "transformations": [
               {
                 "infoTypes": [
                   {
                     "name": "CREDIT_CARD_NUMBER"
                   }
                 ],
                 "primitiveTransformation": {
                   "replaceWithInfoTypeConfig": {}
                 }
               }
             ]
           }
         }
       }
     }
1. Use the "EXECUTE" button to trigger the API call. You'll be prompted for
authentication if needed.
1. A valid API call will result in a table towards the bottom with a green header
and the string "200". Copy the value of the `name` field to save it.
1. In the `workstation.env` file, replace `TBD` from the line `export DEIDENTIFY_TEMPLATE_NAME=TBD` with this value.

#### Build the Custom `fluentd-gcp` Container

1. From the `applications/fluentd-dlp` directory
1. Run `./build.sh` which will build, tag, and push your docker container to the
in-scope project. Take note of the outputted `FLUENTD_IMAGE_REMOTE_REPO` value.
1. In the `workstation.env` file, replace `TBD` from the line `export FLUENTD_IMAGE_REMOTE_REPO=TBD` with this.
1. Re-run `source workstation.env` from the top-level of the project directory

### Helm Installation and Setup

Our Microservices Demo is configured using Helm charts. If you haven't already,
now is a good time to install `helm` in your development environment.


After making sure `helm` is installed, run the following commands to install the server-side component (`tiller`) to your clusters:

```
kubectl --context in-scope -n kube-system create sa tiller
kubectl --context in-scope \
        -n kube-system \
        create clusterrolebinding tiller \
        --clusterrole cluster-admin \
        --serviceaccount=kube-system:tiller
helm --kube-context in-scope  init --history-max 200 --service-account tiller
```

and repeat for the other cluster:

```
kubectl --context out-of-scope -n kube-system create sa tiller
kubectl --context out-of-scope \
        -n kube-system \
        create clusterrolebinding tiller \
        --clusterrole cluster-admin \
        --serviceaccount=kube-system:tiller
helm --kube-context out-of-scope  init --history-max 200 --service-account tiller
```

To verify run `kubectl --context in-scope get deploy,svc tiller-deploy -n kube-system`
and repeat for the `out-of-scope` context if desired.

## Application Deployment

After setting up `helm`, change directories to the top-level `helm` directory
and start by deploying the `fluentd` chart:

### Deploy Fluentd Logger

The following will deploy a specially configured Fluentd Logger to the cluster.
This logger is set up to send all logs to the Management project. This way all
logs for the application can be viewed under one StackDriver instance.

```
helm install \
  --kube-context out-of-scope \
  --name fluentd-custom-target-project \
  --namespace kube-system \
  --set project_id=${TF_VAR_project_prefix}-management \
  ./fluentd-custom-target-project
```

### Deploy the "out-of-scope" Microservices

This deploys all the Microservices that are considered out of PCI scope.

```
helm install \
  --kube-context out-of-scope \
  --name out-of-scope-microservices \
  ./out-of-scope-microservices
```

### Deploy the DLP-Fluentd Logger

Like the out of scope Fluentd Logger, this version sends all log messages to
the Management project's StackDriver. Additionally, it uses the DLP API to scan
for possible Credit Card number leaks and redacts the information.

**NOTE**: Like the other components of this project, this is only meant for
demonstration purposes. Real world log volume may be too cost prohibitive to
use DLP in this way. Please consult with your GCP specialists for your specific
use case and cost considerations!

```
helm install \
  --kube-context in-scope \
  --name fluentd-filter-dlp \
  --namespace kube-system \
  --set project_id=${TF_VAR_project_prefix}-management \
  --set deidentify_template_name=${DEIDENTIFY_TEMPLATE_NAME} \
  --set fluentd_image_remote_repo=${FLUENTD_IMAGE_REMOTE_REPO} \
  ./fluentd-filter-dlp
```

### Deploy the "in-scope" Microservices

Finally, deploy the Microservices in PCI scope. Note that we use information
from the `out-of-scope` cluster, specifically ingress IP information, to
properly configure the deployment.

Additionally, you can opt in to have GCP manage a valid SSL certificate for
your Frontend. This requires that you own and manage your domain name. See
[Additional Notes on Google-Managed SSL Certificates](docs/frontend-https.md) below for more
information.

```
# Setting the `domain_name` will create a Managed Certificate resource. Don't
# add this line if you can't manage your domain's DNS record. You will need
# to point the DNS record to your Ingress' external IP.

helm install \
  --kube-context in-scope \
  --name in-scope-microservices \
  --set nginx_listener_1_ip="$(kubectl --context out-of-scope get svc nginx-listener-1 -o jsonpath="{.status.loadBalancer.ingress[*].ip}")" \
  --set nginx_listener_2_ip="$(kubectl --context out-of-scope get svc nginx-listener-2 -o jsonpath="{.status.loadBalancer.ingress[*].ip}")" \
  --set domain_name=${DOMAIN_NAME} \
  ./in-scope-microservices
```

### Forseti Install and Setup

See [Forseti documentation](docs/forseti.md) for detailed instructions on
setting up the Forseti component and integrating with Cloud Security Command
Center

# List of Included Features

* [Google Managed SSL Certificates](/docs/frontend-https.md)
* [Automated Redaction of Credit Card data via the Data Loss Prevention API](/docs/dlp.md)
* [Encrypted Cross-cluster communication with Nginx’s grpc_proxy](/docs/grpc-proxying.md)
* [Customized Fluentd with Centralized Stackdriver Logging](/docs/fluentd.md)
* [Forseti and Cloud Security Command Center](/docs/forseti.md)
* [Audit and Flow Logs](/docs/audit-flow-logs.md)

# Architecture

See the separate [Architecture documentation](docs/architecture.md) for
detailed diagrams and information.

# Development

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for information on contributing to this project.

### License Header

Each source code requires a copyright notice in the header. Use the
`addlicense` script to add this boilerplate to any new files.

```
go get -u github.com/google/addlicense
```


### Linting

The makefile in this project will lint or sometimes just format any shell,
Python, golang, Terraform, or Dockerfiles. The linters will only be run if
the makefile finds files with the appropriate file extension.

All of the linter checks are in the default make target, so you just have to
run

```
make -s
```

The -s is for 'silent'. Successful output looks like this

```
Running shellcheck
Running terraform validate
Running hadolint on Dockerfiles
Checking for required files
Testing the validity of the header check
..
----------------------------------------------------------------------
Ran 2 tests in 0.019s

OK
Checking file headers
The following lines have trailing whitespace
```

The linters
are as follows:
* Shell - shellcheck. Can be found in homebrew
* Terraform - terraform has a built-in linter in the 'terraform validate'
command.
* Dockerfiles - hadolint. Can be found in homebrew

## Known Issues and Limitations

- This demo assumes that it will be deployed to a dedicated GCP Organization.
  Some components, like Forseti and Cloud Security Command Center are
  Organization-level resources that are not designed to be run with multiple
  copies in a single GCP Organization. They don't necessarily conflict, but
  may, depending on your Organization's configuration.
- If you can not create a new Organization for this demo, your particular GCP
  Organization's roles and permissions may vary. You may need certain resources
  such as the Terraform Service Account and Terraform Admin Project to be
  created by a user with an `Organization Admin` or `Billing Account Admin` roles
- Although it's not recommended, you **may** be able to build the demo with your
  own User Account or a different Service Account. Just note that the
  `terraform/components` resources need to be created with the same account
  that created the projects (or has the `Project Owner` role on each project).
  Because of this, switching back and forth between different accounts to run
  these Terraform components will not work without manual intervention.
- If your GCP Organization is shared between other users or teams, consult your
  Organization Admins before building the demo.
- This demo does not implement a multi-envionment setup. There is no
  "pre-prod", "staging", or "production" differentiation. However, there is no
  reason that this demo couldn't be expanded to accommodate such a setup if you
  so choose.
- Order matters when it comes to building the infrastructure, create the
  projects in the order laid out in this documentation.
- Some additional variables are required to integrate Forseti with Cloud
  Security Command Center. It may require that Forseti is configured twice.
  Once without the `forseti_cscc_source_id` variable set and once again after
  CSCC is manually configured.
- As detailed in [Data Loss Prevention API](docs/dlp.md), the DLP API filter, as
  implemented, is not designed to scale to handle production loads.
- This demo is meant to showcase various GCP features and act as a starting
  point to build a security-focused environment focused on PCI compliance. This
  demo has **not been reviewed by a QSA** and deploying an application into
  this environment does not qualify as being PCI-DSS compliant

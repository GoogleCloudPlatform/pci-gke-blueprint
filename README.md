# PCI on GKE Blueprint

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
- StackDriver
- Google-managed SSL Certificates
- Cloud Data Loss Prevention
- Cloud Storage
- Cloud Security Command Center
- GoogleCloudPlatform/microservices-demo



## Documentation
* [Quickstart](#Quickstart)
* [Prerequisites](#prerequisites)
  * [Installation Dependencies](#installation-dependencies)
  * [GCP IAM Requirements](#gcp-iam-requirements)
* [Workstation Configuration](#workstation-configuration)
* [Building the Infrastructure](docs/build-infrastructure.md)
* [Deploying the Application](docs/deploy-application.md)
* [Diagrams](docs/diagrams.md)
* [Kubernetes RBAC via Google Groups membership demonstration](docs/Google-Groups-and-RBAC.md)
* [Development](/docs/development.md)
* [Known Issues and Limitations](#known-issues-and-limitations)
* [Helpful Links](#helpful-links)

## Quickstart
We recommend you read through the documentation in [Building the Infrastructure](docs/build-infrastructure.md) and [Deploying the Application](docs/deploy-application.md) but if you just want to get started:
1. Follow the steps in [Prerequisites](#prerequisites)
1. Set-up the workstation.env file [Workstation Configuration](#workstation-configuration)
1. Run `./_helpers/build-infra.sh`
1. Run `./_helpers/deploy-app.sh`

## Prerequisites

Before starting, we need to make sure that our local environment is configured
correctly. We need to make sure we have the correct tools and a GCP account
with the correct permissions.

### Installation Dependencies
- [Terraform](https://www.terraform.io/downloads.html)
- [gcloud](https://cloud.google.com/sdk/gcloud/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [kubectx](https://github.com/ahmetb/kubectx#installation)
- [helm, version 3](https://helm.sh/docs/using_helm/)

### GCP IAM Requirements

In order to execute this module you will need access to a Google Cloud Organization, with Oraganization Admin and Folder Admin permissions.

### Authenticate to gcloud

* Once the gcloud SDK is installed, run [gcloud auth login](https://cloud.google.com/sdk/gcloud/reference/auth/login) to authenticate with your Google Account.


## Workstation Configuration

This project comes with a [workstation.env.example](./workstation.env.example) file that is intended to be copied and customized for your environment.

```
cp workstation.env.example workstation.env
```

You can find the values for `YOUR_ORG_ID` and `YOUR_BILLING_ACCOUNT_ID` using the following commands:

```
gcloud organizations list
gcloud beta billing accounts list
```

To create a folder follow these [instructions](https://cloud.google.com/resource-manager/docs/creating-managing-folders).

Most variables can be left as-is, this is a list of the ones that are required to be set, see the comments in-line for details:

- `TF_VAR_org_id`
- `TF_VAR_gsuite_id`
- `TF_VAR_billing_account`
- `TF_VAR_folder_id`
- `TF_ADMIN_BUCKET`
- `TF_VAR_frontend_zone_dns_name`
- `GOOGLE_GROUPS_DOMAIN`
- `SRC_PATH`
- ` REPOSITORY_NAME`



You'll need to source your `workstaion.env` file before executing any of the steps in this demo:

```
source workstation.env
```

* At this point, your workstation is ready. Continue from here by either running `./_helpers/build-infra.sh`, or following the
stepwise instructions for that script in [Building the Infrastructure](docs/build-infrastructure.md).

## Known Issues and Limitations

- This demo assumes that it will be deployed to a dedicated GCP Organization.
  Some components, like Cloud Security Command Center are
  Organization-level resources that are not designed to be run with multiple
  copies in a single GCP Organization. They don't necessarily conflict, but
  may, depending on your Organization's configuration.
- If your GCP Organization is shared between other users or teams, consult your
  Organization Admins before building the demo.
- This demo does not implement a multi-envionment setup. There is no
  "pre-prod", "staging", or "production" differentiation. However, there is no
  reason that this demo couldn't be expanded to accommodate such a setup if you
  so choose.
- Order matters when it comes to building the infrastructure, create the
  projects in the order laid out in this documentation.
- This demo is meant to showcase various GCP features and act as a starting
  point to build a security-focused environment focused on PCI compliance. This
  demo has **not been reviewed by a QSA** and deploying an application into
  this environment does not qualify as being PCI-DSS compliant

## Helpful Links

* Significant portions of this project are based on "[Building a multi-cluster service mesh on GKE using replicated control-plane architecture](https://cloud.google.com/solutions/building-a-multi-cluster-service-mesh-on-gke-using-replicated-control-plane-architecture)"

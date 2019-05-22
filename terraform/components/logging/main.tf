/**
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
data "terraform_remote_state" "project_management" {
  backend = "gcs"

  config {
    bucket = "${local.remote_state_bucket}"
    prefix = "terraform/state/management"
  }
}

data "terraform_remote_state" "project_in_scope" {
  backend = "gcs"

  config {
    bucket = "${local.remote_state_bucket}"
    prefix = "terraform/state/in-scope"
  }
}

data "terraform_remote_state" "project_out_of_scope" {
  backend = "gcs"

  config {
    bucket = "${local.remote_state_bucket}"
    prefix = "terraform/state/out-of-scope"
  }
}

data "terraform_remote_state" "project_network" {
  backend = "gcs"

  config {
    bucket = "${local.remote_state_bucket}"
    prefix = "terraform/state/network"
  }
}

data "terraform_remote_state" "forseti" {
  backend = "gcs"

  config {
    bucket = "${local.remote_state_bucket}"
    prefix = "terraform/state/components/forseti"
  }
}

module "folder-sink-destination" {
  source                   = "github.com/terraform-google-modules/terraform-google-log-export//modules/storage?ref=v2.0.0"
  project_id               = "${data.terraform_remote_state.project_management.project_id}"
  storage_bucket_name      = "${var.project_prefix}-folder-audit-log-bucket"
  log_sink_writer_identity = "${module.folder-log-export.writer_identity}"
}

module "in-scope-project-sink-destination" {
  source                   = "github.com/terraform-google-modules/terraform-google-log-export//modules/storage?ref=v2.0.0"
  project_id               = "${data.terraform_remote_state.project_management.project_id}"
  storage_bucket_name      = "${var.project_prefix}-in-scope-project-log-bucket"
  log_sink_writer_identity = "${module.in-scope-project-log-export.writer_identity}"
}

module "network-project-sink-destination" {
  source                   = "github.com/terraform-google-modules/terraform-google-log-export//modules/storage?ref=v2.0.0"
  project_id               = "${data.terraform_remote_state.project_management.project_id}"
  storage_bucket_name      = "${var.project_prefix}-network-project-log-bucket"
  log_sink_writer_identity = "${module.network-project-log-export.writer_identity}"
}

#
# Export all Audit Logs >= WARNING to Bucket from
# the Folder level
#
module "folder-log-export" {
  source                 = "github.com/terraform-google-modules/terraform-google-log-export?ref=v2.0.0"
  destination_uri        = "${module.folder-sink-destination.destination_uri}"
  filter                 = "logName:cloudaudit.googleapis.com AND severity >= WARNING"
  log_sink_name          = "folder-audit-log-sink"
  parent_resource_id     = "${var.folder_id}"
  parent_resource_type   = "folder"
  unique_writer_identity = "true"
  include_children       = "true"
}

#
# In-Scope Logging Sink
#
# Send the following logs to a storage bucket in the management project for
# further analysis and retention:
#
# - GCE Instance Logs including lower severity Audit logs than the broader
# Folder-level sink
#
module "in-scope-project-log-export" {
  source                 = "github.com/terraform-google-modules/terraform-google-log-export?ref=v2.0.0"
  destination_uri        = "${module.in-scope-project-sink-destination.destination_uri}"
  filter                 = "resource.type=gce_instance"
  log_sink_name          = "in-scope-project-log-sink"
  parent_resource_id     = "${data.terraform_remote_state.project_in_scope.project_id}"
  parent_resource_type   = "project"
  unique_writer_identity = "true"
}

#
# Network Logging Sink
#
# Send the following logs to a storage bucket in the management project for
# further analysis and retention:
#
# - VPC Flow logs for in-scope subnet
#
module "network-project-log-export" {
  source                 = "github.com/terraform-google-modules/terraform-google-log-export?ref=v2.0.0"
  destination_uri        = "${module.network-project-sink-destination.destination_uri}"
  filter                 = "resource.type=gce_subnetwork AND resource.labels.subnetwork_name=in-scope AND logName:vpc_flows"
  log_sink_name          = "network-project-log-sink"
  parent_resource_id     = "${data.terraform_remote_state.project_network.project_id}"
  parent_resource_type   = "project"
  unique_writer_identity = "true"
}

#
# Grant permissions for the in- and out- service accounts to log to the management
# project
#
# These permissions are NOT related to the log exporting are used exclusively
# for GKE instance nodes to log messages to Stackdriver
resource "google_project_iam_binding" "in-and-out-scope-sd-log_writer" {
  role    = "roles/logging.logWriter"
  project = "${data.terraform_remote_state.project_management.project_id}"

  members = [
    "serviceAccount:${data.terraform_remote_state.project_in_scope.service_account_email}",
    "serviceAccount:${data.terraform_remote_state.project_out_of_scope.service_account_email}",
  ]
}

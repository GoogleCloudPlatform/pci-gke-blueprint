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

resource "google_storage_bucket" "log_bucket" {
  name    = "${var.project_prefix}-logging-bucket"
  project = "${data.terraform_remote_state.project_management.project_id}"
}

#
# Export all Audit Logs >= WARNING to Bucket from
# the Folder level
#
resource "google_logging_folder_sink" "audit-log-sink" {
  name             = "audit-log-sink"
  folder           = "${var.folder_id}"
  destination      = "storage.googleapis.com/${google_storage_bucket.log_bucket.name}"
  filter           = "logName:activity AND severity >= WARNING"
  include_children = "true"
}

#
# In-Scope Logging Sinks
#

# GCE Logs
resource "google_logging_project_sink" "in-scope-instance-sink" {
  name                   = "in-scope-instance-sink"
  project                = "${data.terraform_remote_state.project_in_scope.project_id}"
  destination            = "storage.googleapis.com/${google_storage_bucket.log_bucket.name}"
  filter                 = "resource.type = gce_instance"
  unique_writer_identity = "true"
}

# Subnetwork Flow Logs
resource "google_logging_project_sink" "in-scope-flowlog-sink" {
  name                   = "in-scope-flowlog-sink"
  project                = "${data.terraform_remote_state.project_network.project_id}"
  destination            = "storage.googleapis.com/${google_storage_bucket.log_bucket.name}"
  filter                 = "resource.type = gce_subnetwork AND resource.labels.subnetwork_name = in-scope"
  unique_writer_identity = "true"
}

#
# Grant permissions to Logging Bucket destination
#
resource "google_project_iam_binding" "log_writer" {
  role    = "roles/storage.objectCreator"
  project = "${data.terraform_remote_state.project_management.project_id}"

  members = [
    "${google_logging_folder_sink.audit-log-sink.writer_identity}",
    "${google_logging_project_sink.in-scope-flowlog-sink.writer_identity}",
    "serviceAccount:${data.terraform_remote_state.forseti.forseti_server_service_account}",
    "${google_logging_project_sink.in-scope-instance-sink.writer_identity}",
  ]
}

# Grant permissions for the in- and out- service accounts to log to the management
# project
resource "google_project_iam_binding" "in-and-out-scope-sd-log_writer" {
  role    = "roles/logging.logWriter"
  project = "${data.terraform_remote_state.project_management.project_id}"

  members = [
    "serviceAccount:${data.terraform_remote_state.project_in_scope.service_account_email}",
    "serviceAccount:${data.terraform_remote_state.project_out_of_scope.service_account_email}",
  ]
}

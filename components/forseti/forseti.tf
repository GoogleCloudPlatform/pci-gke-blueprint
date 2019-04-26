/**
 * Copyright 2018 Google LLC
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

data "terraform_remote_state" "network" {
  backend = "gcs"

  config {
    bucket = "${local.remote_state_bucket}"
    prefix = "terraform/state/network"
  }
}

data "terraform_remote_state" "project_management" {
  backend = "gcs"

  config {
    bucket = "${local.remote_state_bucket}"
    prefix = "terraform/state/management"
  }
}

/******************************************
   Forseti Module Install
  *****************************************/
module "forseti-install" {
  source             = "github.com/terraform-google-modules/terraform-google-forseti"
  gsuite_admin_email = ""
  project_id         = "${data.terraform_remote_state.project_management.project_id}"
  org_id             = ""
  folder_id          = "${var.folder_id}"
  domain             = "${var.domain}"
  network            = "${data.terraform_remote_state.network.network_name}"
  network_project    = "${data.terraform_remote_state.network.project_id}"
  subnetwork         = "${local.mgmt_subnet_name}"

  cscc_source_id          = "${local.forseti_cscc_source_id}"
  cscc_violations_enabled = "${local.forseti_cscc_violations_enabled}"

  # Bug in the forseti module variable interpolation. The value must be
  # hardcoded, otherwise the error
  # `Error: # module.forseti-install.module.server.google_compute_firewall.forseti-server-allow-grpc: source_ranges: should be a list`
  # is thrown.
  server_grpc_allow_ranges = ["10.10.1.0/24"]
}

output "forseti_client_service_account" {
  value       = "${module.forseti-install.forseti-client-service-account}"
  description = "The service account generated for the forseti client instance"
}

output "forseti_server_service_account" {
  value       = "${module.forseti-install.forseti-server-service-account}"
  description = "The service account generated for the forseti server instance"
}

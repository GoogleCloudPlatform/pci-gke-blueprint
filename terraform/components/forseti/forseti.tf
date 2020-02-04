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

data "terraform_remote_state" "network" {
  backend = "gcs"

  config = {
    bucket = var.remote_state_bucket
    prefix = "terraform/state/network"
  }
}

data "terraform_remote_state" "project_management" {
  backend = "gcs"

  config = {
    bucket = var.remote_state_bucket
    prefix = "terraform/state/management"
  }
}

/******************************************
   Forseti Module Install
  *****************************************/
module "forseti-install" {
  source  = "terraform-google-modules/forseti/google"
  version = "~> 5.1"

  gsuite_admin_email = ""
  project_id         = data.terraform_remote_state.project_management.outputs.project_id
  org_id             = ""
  folder_id          = var.folder_id
  domain             = var.domain
  network            = data.terraform_remote_state.network.outputs.network_name
  network_project    = data.terraform_remote_state.network.outputs.project_id
  subnetwork         = local.mgmt_subnet_name

  cscc_source_id          = local.forseti_cscc_source_id
  cscc_violations_enabled = local.forseti_cscc_violations_enabled

  server_grpc_allow_ranges = [local.mgmt_subnet_cidr]
}

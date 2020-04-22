/**
 * Copyright 2020 Google LLC
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

provider "google" {
  version = "~> 3.8"
  region  = var.region
}
provider "google-beta" {
  version = "~> 3.8"
  region  = var.region
}
variable "billing_account" {
  description = "The ID of the associated billing account"
  default     = ""
}
variable "org_id" {
  description = "The ID of the Google Cloud Organization."
  default     = ""
}
variable "terraform_service_account" {
  description = "The IDs of the Terraform users or Service Accounts to be applied to VPC Service Controls"
  default     = ["serviceAccount:<service-account-email>", "user:<user-email>"]
}
variable "domain" {
  description = "The domain name of the Google Cloud Organization. Use this if you can't add Organization Viewer permissions to your TF ServiceAccount"
  default     = ""
}
variable "folder_id" {
  description = "The ID of the folder in which projects should be created (optional)."
  default     = ""
}
variable "project_prefix" {
  description = "Segment to prefix all project names with."
  default     = "pci-poc"
}
variable "region" {
  default = "us-central1"
}
variable "frontend_hostname" {
  default = "store"
}
variable "frontend_zone_dns_name" {
  default = "mycompany.com"
}
variable "shared_vpc_name" {
  default     = "shared-vpc"
  description = "The name of the Shared VPC network"
}
variable "gsuite_id" {
  default     = "gsuite-customer-id"
  description = "G Suite customer ID"
}
variable "gke_security_group_name" {
  description = "Google Group name to be used for GKE RBAC via Google Groups. See https://cloud.google.com/kubernetes-engine/docs/how-to/role-based-access-control#groups-setup-gsuite"
}
variable "project_network" {
  description = "Name of the network project"
}
variable "project_management" {
  description = "Name of the management project"
}
variable "project_in_scope" {
  description = "Name of the in-scope project"
}
variable "project_out_of_scope" {
  description = "Name of the out-of-scope project"
}

locals {
  folder_id = "${var.folder_id != "" ? var.folder_id : ""}"

  # in-scope network details
  in_scope_subnet_name = "in-scope"
  in_scope_subnet_cidr = "10.0.4.0/22"

  in_scope_pod_ip_range_name = "in-scope-pod-cidr"
  in_scope_pod_ip_cidr_range = "10.4.0.0/14"

  in_scope_services_ip_range_name = "in-scope-services-cidr"
  in_scope_services_ip_cidr_range = "10.0.32.0/20"

  in_scope_master_ipv4_cidr_block                           = "10.10.11.0/28"
  in_scope_master_authorized_networks_config_1_display_name = "all"
  in_scope_master_authorized_networks_config_1_cidr_block   = "0.0.0.0/0"

  # in-scope cluster details
  in_scope_cluster_name                         = "in-scope"
  in_scope_node_pool_initial_node_count         = 1
  in_scope_cluster_release_channel              = "REGULAR"
  in_scope_node_pool_autoscaling_min_node_count = 1
  in_scope_node_pool_autoscaling_max_node_count = 10
  in_scope_node_pool_machine_type               = "n1-standard-2"
  in_scope_node_pool_oauth_scopes = [
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/devstorage.read_only",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring",
    "https://www.googleapis.com/auth/trace.append",
    "https://www.googleapis.com/auth/cloud_debugger",
    "https://www.googleapis.com/auth/cloud-platform",
  ]
  in_scope_node_pool_auto_repair     = true
  in_scope_node_pool_auto_upgrade    = true
  in_scope_node_pool_max_surge       = 1
  in_scope_node_pool_max_unavailable = 0

  # out-of-scope network details
  out_of_scope_subnet_name = "out-of-scope"
  out_of_scope_subnet_cidr = "172.16.4.0/22"

  out_of_scope_pod_ip_range_name = "out-of-scope-pod-cidr"
  out_of_scope_pod_ip_cidr_range = "172.20.0.0/14"

  out_of_scope_services_ip_range_name = "out-of-scope-services-cidr"
  out_of_scope_services_ip_cidr_range = "172.16.16.0/20"

  out_of_scope_master_ipv4_cidr_block                           = "10.10.12.0/28"
  out_of_scope_master_authorized_networks_config_1_display_name = "all"
  out_of_scope_master_authorized_networks_config_1_cidr_block   = "0.0.0.0/0"

  # out-of-scope cluster details
  out_of_scope_cluster_name                         = "out-of-scope"
  out_of_scope_node_pool_initial_node_count         = 1
  out_of_scope_cluster_release_channel              = "REGULAR"
  out_of_scope_node_pool_autoscaling_min_node_count = 1
  out_of_scope_node_pool_autoscaling_max_node_count = 10
  out_of_scope_node_pool_machine_type               = "n1-standard-2"
  out_of_scope_node_pool_oauth_scopes = [
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/devstorage.read_only",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring",
    "https://www.googleapis.com/auth/trace.append",
    "https://www.googleapis.com/auth/cloud_debugger",
    "https://www.googleapis.com/auth/cloud-platform",
  ]
  out_of_scope_node_pool_auto_repair     = true
  out_of_scope_node_pool_auto_upgrade    = true
  out_of_scope_node_pool_max_surge       = 1
  out_of_scope_node_pool_max_unavailable = 0

  frontend_external_address_name = "frontend-ext-ip"
  regular_service_perimeter_restricted_services = [
    "cloudtrace.googleapis.com",
    "monitoring.googleapis.com",]

  google_compute_security_policy_frontend_name = "frontend-application-security-policy"

  # See https://cloud.google.com/armor/docs/rule-tuning#sql_injection
  # SQLi Sensitivity Level 1
  google_compute_security_policy_sqli_rule_expression_list = <<EOT
    evaluatePreconfiguredExpr('sqli-stable',[
      'owasp-crs-v030001-id942110-sqli',
      'owasp-crs-v030001-id942120-sqli',
      'owasp-crs-v030001-id942150-sqli',
      'owasp-crs-v030001-id942180-sqli',
      'owasp-crs-v030001-id942200-sqli',
      'owasp-crs-v030001-id942210-sqli',
      'owasp-crs-v030001-id942260-sqli',
      'owasp-crs-v030001-id942300-sqli',
      'owasp-crs-v030001-id942310-sqli',
      'owasp-crs-v030001-id942330-sqli',
      'owasp-crs-v030001-id942340-sqli',
      'owasp-crs-v030001-id942380-sqli',
      'owasp-crs-v030001-id942390-sqli',
      'owasp-crs-v030001-id942400-sqli',
      'owasp-crs-v030001-id942410-sqli',
      'owasp-crs-v030001-id942430-sqli',
      'owasp-crs-v030001-id942440-sqli',
      'owasp-crs-v030001-id942450-sqli',
      'owasp-crs-v030001-id942251-sqli',
      'owasp-crs-v030001-id942420-sqli',
      'owasp-crs-v030001-id942431-sqli',
      'owasp-crs-v030001-id942460-sqli',
      'owasp-crs-v030001-id942421-sqli',
      'owasp-crs-v030001-id942432-sqli'
    ])
EOT


}

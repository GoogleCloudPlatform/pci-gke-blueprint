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

resource "google_container_cluster" "primary" {
  name               = "${local.out_of_scope_cluster_name}"
  min_master_version = "${local.gke_minimum_version}"
  location           = "us-central1-a"
  node_locations     = ["us-central1-b"]
  network            = "${data.terraform_remote_state.project_network.vpc_self_link}"
  subnetwork         = "projects/${data.terraform_remote_state.project_network.project_id}/regions/${var.region}/subnetworks/${local.out_of_scope_subnet_name}"
  project            = "${data.terraform_remote_state.project_out_of_scope.project_id}"

  # We use a custom fluentd DaemonSet to manage logging. We do this so we can
  # configure filter rules to mask sensitive data.
  logging_service = "none"

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  initial_node_count = 1

  remove_default_node_pool = true

  # Required for initial cluster setup. Avoids setting the node service
  # account to the incorrect default service account.
  node_config {
    service_account = "${data.terraform_remote_state.project_out_of_scope.service_account_email}"
    preemptible     = true
    tags            = ["out-of-scope"]
  }

  # Setting an empty username and password explicitly disables basic auth
  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  ip_allocation_policy {
    use_ip_aliases                = true
    cluster_secondary_range_name  = "${local.out_of_scope_pod_ip_range_name}"
    services_secondary_range_name = "${local.out_of_scope_services_ip_range_name}"
  }

  private_cluster_config {
    # In a private cluster, nodes do not have public IP addresses, and the master
    # is inaccessible by default.
    enable_private_nodes = true

    # "Master IP range" is a private RFC 1918 reange for the master's VPC. The
    # master range must not overlap with any subnet in your cluster's VPC. The
    # master and your cluster use VPC peering to communicate privately.
    # See https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters
    master_ipv4_cidr_block = "10.10.12.0/28"
  }

  # Allows any traffic to access cluster master on its public IP address.
  # Change this to limit accessibility to a range of IPs or corporate network.
  # You'll need access to the master to run `kubectl` commands
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"
      display_name = "all"
    }
  }
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name               = "${local.out_of_scope_cluster_name}-node-pool"
  depends_on         = ["google_container_cluster.primary"]
  version            = "${local.gke_minimum_version}"
  location           = "us-central1-a"
  initial_node_count = 2

  autoscaling {
    min_node_count = 1
    max_node_count = 10
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  cluster = "${google_container_cluster.primary.name}"
  project = "${data.terraform_remote_state.project_out_of_scope.project_id}"

  node_config {
    preemptible     = true
    machine_type    = "n1-standard-1"
    service_account = "${data.terraform_remote_state.project_out_of_scope.service_account_email}"

    tags = ["out-of-scope"]

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/trace.append",
      "https://www.googleapis.com/auth/cloud_debugger",
    ]
  }
}

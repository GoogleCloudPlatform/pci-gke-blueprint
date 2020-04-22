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

# create the clusters
# https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-shared-vpc#creating_a_cluster_in_your_first_service_project
resource "google_container_cluster" "in_scope" {
  provider                 = google-beta
  name                     = local.in_scope_cluster_name
  location                 = var.region
  project                  = google_project.in_scope.project_id
  network                  = google_compute_network.shared-vpc.self_link
  subnetwork               = google_compute_subnetwork.in-scope.self_link
  remove_default_node_pool = true
  initial_node_count       = local.in_scope_node_pool_initial_node_count
  enable_shielded_nodes    = true

  release_channel {
    channel = local.in_scope_cluster_release_channel
  }
  workload_identity_config {
    identity_namespace = "${google_project.in_scope.project_id}.svc.id.goog"
  }
  addons_config {
    istio_config {
      disabled = true
    }
  }
  ip_allocation_policy {
    cluster_secondary_range_name  = local.in_scope_pod_ip_range_name
    services_secondary_range_name = local.in_scope_services_ip_range_name
  }
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = local.in_scope_master_ipv4_cidr_block
  }
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = local.in_scope_master_authorized_networks_config_1_cidr_block
      display_name = local.in_scope_master_authorized_networks_config_1_display_name
    }
  }
  authenticator_groups_config {
    security_group = var.gke_security_group_name
  }
}

resource "google_container_node_pool" "in_scope_node_pool" {
  provider           = google-beta
  name               = "${local.in_scope_cluster_name}-node-pool"
  location           = var.region
  initial_node_count = local.in_scope_node_pool_initial_node_count
  cluster            = google_container_cluster.in_scope.name
  project            = google_project.in_scope.project_id

  autoscaling {
    min_node_count = local.in_scope_node_pool_autoscaling_min_node_count
    max_node_count = local.in_scope_node_pool_autoscaling_max_node_count
  }
  management {
    auto_repair  = local.in_scope_node_pool_auto_repair
    auto_upgrade = local.in_scope_node_pool_auto_upgrade
  }
  upgrade_settings {
    max_surge       = local.in_scope_node_pool_max_surge
    max_unavailable = local.in_scope_node_pool_max_unavailable
  }
  node_config {
    machine_type = local.in_scope_node_pool_machine_type
    image_type   = "COS_CONTAINERD"
    oauth_scopes = local.in_scope_node_pool_oauth_scopes
    shielded_instance_config {
      enable_secure_boot = true
    }
    workload_metadata_config {
      node_metadata = "GKE_METADATA_SERVER"
    }
  }
}

resource "google_container_cluster" "out_of_scope" {
  provider                 = google-beta
  name                     = local.out_of_scope_cluster_name
  location                 = var.region
  project                  = google_project.out_of_scope.project_id
  network                  = google_compute_network.shared-vpc.self_link
  subnetwork               = google_compute_subnetwork.out-of-scope.self_link
  remove_default_node_pool = true
  initial_node_count       = local.out_of_scope_node_pool_initial_node_count
  enable_shielded_nodes    = true

  release_channel {
    channel = local.out_of_scope_cluster_release_channel
  }
  workload_identity_config {
    identity_namespace = "${google_project.out_of_scope.project_id}.svc.id.goog"
  }
  addons_config {
    istio_config {
      disabled = true
    }
  }
  ip_allocation_policy {
    cluster_secondary_range_name  = local.out_of_scope_pod_ip_range_name
    services_secondary_range_name = local.out_of_scope_services_ip_range_name
  }
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = local.out_of_scope_master_ipv4_cidr_block
  }
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = local.out_of_scope_master_authorized_networks_config_1_cidr_block
      display_name = local.out_of_scope_master_authorized_networks_config_1_display_name
    }
  }
  authenticator_groups_config {
    security_group = var.gke_security_group_name
  }
}

resource "google_container_node_pool" "out_of_scope_node_pool" {
  provider           = google-beta
  name               = "${local.out_of_scope_cluster_name}-node-pool"
  location           = var.region
  initial_node_count = local.out_of_scope_node_pool_initial_node_count
  cluster            = google_container_cluster.out_of_scope.name
  project            = google_project.out_of_scope.project_id

  autoscaling {
    min_node_count = local.out_of_scope_node_pool_autoscaling_min_node_count
    max_node_count = local.out_of_scope_node_pool_autoscaling_max_node_count
  }
  management {
    auto_repair  = local.out_of_scope_node_pool_auto_repair
    auto_upgrade = local.out_of_scope_node_pool_auto_upgrade
  }
  upgrade_settings {
    max_surge       = local.out_of_scope_node_pool_max_surge
    max_unavailable = local.out_of_scope_node_pool_max_unavailable
  }

  node_config {
    machine_type = local.out_of_scope_node_pool_machine_type
    image_type   = "COS_CONTAINERD"
    oauth_scopes = local.out_of_scope_node_pool_oauth_scopes
    shielded_instance_config {
      enable_secure_boot = true
    }
    workload_metadata_config {
      node_metadata = "GKE_METADATA_SERVER"
    }
  }
}

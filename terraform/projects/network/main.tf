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

module "project_network" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 6.2.1"

  name                        = local.project_network
  org_id                      = var.org_id
  domain                      = var.domain
  billing_account             = var.billing_account
  folder_id                   = local.folder_id
  disable_services_on_destroy = "false"

  activate_apis = [
    "compute.googleapis.com",
    "container.googleapis.com",
  ]
}

module "vpc_pci" {
  source  = "terraform-google-modules/network/google"
  version = "~> 2.0.1"

  shared_vpc_host = "true"
  project_id      = module.project_network.project_id

  network_name = var.shared_vpc_name
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name   = local.mgmt_subnet_name
      subnet_ip     = local.mgmt_subnet_cidr
      subnet_region = var.region
    },
    {
      subnet_name               = local.in_scope_subnet_name
      subnet_ip                 = local.in_scope_subnet_cidr
      subnet_region             = var.region
      subnet_private_access     = "true"
      subnet_flow_logs          = "true"
      subnet_flow_logs_interval = "INTERVAL_10_MIN"
      subnet_flow_logs_sampling = 0.7
      subnet_flow_logs_metadata = "INCLUDE_ALL_METADATA"
    },
    {
      subnet_name           = local.out_of_scope_subnet_name
      subnet_ip             = local.out_of_scope_subnet_cidr
      subnet_region         = var.region
      subnet_private_access = "true"
    },
  ]

  secondary_ranges = {
    management = []

    out-of-scope = [
      {
        range_name    = local.out_of_scope_pod_ip_range_name
        ip_cidr_range = "10.11.0.0/16"
      },
      {
        range_name    = local.out_of_scope_services_ip_range_name
        ip_cidr_range = "10.12.0.0/16"
      },
    ]

    in-scope = [
      {
        range_name    = local.in_scope_pod_ip_range_name
        ip_cidr_range = "10.13.0.0/16"
      },
      {
        range_name    = local.in_scope_services_ip_range_name
        ip_cidr_range = "10.14.0.0/16"
      },
    ]
  }

  routes = [
    {
      name              = "egress-internet"
      description       = "route through IGW to access internet"
      destination_range = "0.0.0.0/0"
      tags              = "egress-inet"
      next_hop_internet = "true"
    },
  ]
}

resource "google_compute_router" "router" {
  name    = "router"
  project = module.project_network.project_id
  region  = var.region
  network = module.vpc_pci.network_self_link
}

resource "google_compute_router_nat" "nat" {
  name = "nat-all"

  # Set an explicit dependency on VPC module.
  # This enforces the correct creation order for this NAT resource.
  depends_on = [module.vpc_pci]

  project                            = module.project_network.project_id
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = "https://www.googleapis.com/compute/v1/projects/${module.project_network.project_id}/regions/${var.region}/subnetworks/${local.in_scope_subnet_name}"
    source_ip_ranges_to_nat = ["PRIMARY_IP_RANGE"]
  }

  subnetwork {
    name                    = "https://www.googleapis.com/compute/v1/projects/${module.project_network.project_id}/regions/${var.region}/subnetworks/${local.out_of_scope_subnet_name}"
    source_ip_ranges_to_nat = ["PRIMARY_IP_RANGE"]
  }
}

# Sets up a custom Firewall Admin that we use to allow GKE's service agent to
# freely modify Firewall rules on the network project.
#
# If you would like to manage Firewall rules manually or through other means,
# remove these permissions.
#
resource "google_project_iam_custom_role" "firewall_admin" {
  depends_on = [module.vpc_pci]
  project    = local.project_network
  role_id    = "firewall_admin"
  title      = "Firewall Admin"

  permissions = [
    "compute.firewalls.create",
    "compute.firewalls.get",
    "compute.firewalls.delete",
    "compute.firewalls.list",
    "compute.firewalls.update",
    "compute.networks.updatePolicy",
  ]
}

# role_id of a form to be consumed by the role attribute of google_project_iam_member
output firewall_admin_role_id_custom_formatted {
  value = "projects/${local.project_network}/roles/${google_project_iam_custom_role.firewall_admin.role_id}"
}

output project_id {
  value = module.project_network.project_id
}

output vpc_self_link {
  value = module.vpc_pci.network_self_link
}

output subnets_self_links {
  value = module.vpc_pci.subnets_self_links
}

output network_name {
  value = module.vpc_pci.network_name
}

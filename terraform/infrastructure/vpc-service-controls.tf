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

module "vpc_service_control_organizational_access_policy" {
  source      = "terraform-google-modules/vpc-service-controls/google"
  version     = "1.0.3"
  parent_id   = var.org_id
  policy_name = "PCI Policy"
}

module "access_level_members" {
  source  = "terraform-google-modules/vpc-service-controls/google//modules/access_level"
  version = "1.0.3"
  policy  = module.vpc_service_control_organizational_access_policy.policy_id
  name    = "terraform_members"
  members = [var.terraform_service_account]
}

module "regular_service_perimeter" {
  source              = "terraform-google-modules/vpc-service-controls/google//modules/regular_service_perimeter"
  version             = "1.0.3"
  policy              = module.vpc_service_control_organizational_access_policy.policy_id
  perimeter_name      = "gke_perimeter"
  description         = "Perimeter shielding GKE projects"
  resources           = [google_project.in_scope.number, google_project.out_of_scope.number, google_project.network.number, google_project.management.number]
  access_levels       = [module.access_level_members.name]
  restricted_services = local.regular_service_perimeter_restricted_services
}

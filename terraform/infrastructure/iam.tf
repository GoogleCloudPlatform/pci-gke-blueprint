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

# Grant the Host Service Agent User role to the GKE service accounts on the host project
resource "google_project_iam_binding" "host-service-agent-for-gke-service-accounts" {
  project = google_project.network.project_id
  role    = "roles/container.hostServiceAgentUser"
  members = [
    "serviceAccount:service-${google_project.in_scope.number}@container-engine-robot.iam.gserviceaccount.com",
    "serviceAccount:service-${google_project.out_of_scope.number}@container-engine-robot.iam.gserviceaccount.com",
  ]
}

resource "google_project_iam_custom_role" "firewall_admin" {
  depends_on = [google_project.network]
  project    = google_project.network.project_id
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

# Add the in-scope Kubernetes Engine Service Agent to the above custom role
resource "google_project_iam_member" "add_firewall_admin_to_in_scope_gke_service_account" {
  project = google_project.network.project_id
  role    = "projects/${google_project.network.project_id}/roles/firewall_admin"
  member  = "serviceAccount:service-${google_project.in_scope.number}@container-engine-robot.iam.gserviceaccount.com"
}

# Add the out-of-scope Kubernetes Engine Service Agent to the above custom role
resource "google_project_iam_member" "add_firewall_admin_to_out_of_scope_gke_service_account" {
  project = google_project.network.project_id
  role    = "projects/${google_project.network.project_id}/roles/firewall_admin"
  member  = "serviceAccount:service-${google_project.out_of_scope.number}@container-engine-robot.iam.gserviceaccount.com"
}

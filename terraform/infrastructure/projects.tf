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

# Create the projects
resource "google_project" "network" {
  name                = var.project_network
  project_id          = var.project_network
  folder_id           = local.folder_id
  billing_account     = var.billing_account
  auto_create_network = false
}
resource "google_project" "in_scope" {
  name                = var.project_in_scope
  project_id          = var.project_in_scope
  folder_id           = local.folder_id
  billing_account     = var.billing_account
  auto_create_network = false
}
resource "google_project" "out_of_scope" {
  name                = var.project_out_of_scope
  project_id          = var.project_out_of_scope
  folder_id           = local.folder_id
  billing_account     = var.billing_account
  auto_create_network = false
}
resource "google_project" "management" {
  name                = var.project_management
  project_id          = var.project_management
  folder_id           = local.folder_id
  billing_account     = var.billing_account
  auto_create_network = false
}

# Enable GKE API
# https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-shared-vpc#enabling_the_api_in_your_projects
resource "google_project_service" "container_api_network" {
  project                    = google_project.network.project_id
  service                    = "container.googleapis.com"
  disable_dependent_services = true
  disable_on_destroy         = true
}
resource "google_project_service" "container_api_in_scope" {
  project                    = google_project.in_scope.project_id
  service                    = "container.googleapis.com"
  disable_dependent_services = true
  disable_on_destroy         = true
}
resource "google_project_service" "container_api_out_of_scope" {
  project                    = google_project.out_of_scope.project_id
  service                    = "container.googleapis.com"
  disable_dependent_services = true
  disable_on_destroy         = true
}

# Enable Stackdriver Trace API
resource "google_project_service" "cloudtrace_api_out_of_scope" {
  project                    = google_project.out_of_scope.project_id
  service                    = "cloudtrace.googleapis.com"
  disable_dependent_services = true
  disable_on_destroy         = true
}
resource "google_project_service" "monitoring_api_out_of_scope" {
  project                    = google_project.out_of_scope.project_id
  service                    = "monitoring.googleapis.com"
  disable_dependent_services = true
  disable_on_destroy         = true
}
resource "google_project_service" "cloudtrace_api_in_scope" {
  project                    = google_project.in_scope.project_id
  service                    = "cloudtrace.googleapis.com"
  disable_dependent_services = true
  disable_on_destroy         = true
}
resource "google_project_service" "monitoring_api_in_scope" {
  project                    = google_project.in_scope.project_id
  service                    = "monitoring.googleapis.com"
  disable_dependent_services = true
  disable_on_destroy         = true
}
resource "google_project_service" "dns_api_network" {
  project                    = google_project.network.project_id
  service                    = "dns.googleapis.com"
  disable_dependent_services = true
  disable_on_destroy         = true
}

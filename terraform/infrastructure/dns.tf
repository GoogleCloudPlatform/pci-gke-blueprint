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

resource "google_dns_managed_zone" "frontend" {
  project    = google_project.network.project_id
  name       = "frontend-zone"
  dns_name   = "${var.frontend_zone_dns_name}."
  depends_on = [google_project_service.dns_api_network]
}

resource "google_dns_record_set" "frontend" {
  project      = google_project.network.project_id
  name         = "${var.frontend_hostname}.${google_dns_managed_zone.frontend.dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.frontend.name
  rrdatas      = [google_compute_global_address.frontend-ext-ip.address]
}

output "frontend_zone_dns_name" {
  value = var.frontend_zone_dns_name
}

output "nameservers" {
  value = google_dns_managed_zone.frontend.name_servers
}

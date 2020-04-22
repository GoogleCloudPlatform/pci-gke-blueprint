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

# This allows traffic from the in-scope cluster's services to the out-of-scope
# internal load balancer
# the ports are listed in /helm/out-of-scope-microservices/templates/nginx-listener.yaml
resource "google_compute_firewall" "from_out_of_scope_to_in_scope_internal_load_balancer" {
  name          = "from-out-of-scope-to-in-scope-internal-load-balancer"
  project       = google_project.network.project_id
  network       = google_compute_network.shared-vpc.name
  source_ranges = ["0.0.0.0/0"]
  allow {
    protocol = "tcp"
    ports    = ["4443-4449"]
  }
}

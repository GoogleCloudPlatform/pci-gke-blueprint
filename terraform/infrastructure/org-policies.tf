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


resource "google_folder_organization_policy" "external_ip_policy" {
  folder     = "folders/${var.folder_id}"
  constraint = "compute.vmExternalIpAccess"

  list_policy {
    deny {
      all = true
    }
  }
}


resource "google_folder_organization_policy" "domain_restricted_sharing_policy" {
  folder     = "folders/${var.folder_id}"
  constraint = "iam.allowedPolicyMemberDomains"

  list_policy {
    allow {
      values = [var.gsuite_id]
    }
  }
}


resource "google_folder_organization_policy" "trusted_image_policy" {
  folder     = "folders/${var.folder_id}"
  constraint = "compute.trustedImageProjects"

  list_policy {
    allow {
      values = ["projects/cos-cloud", "projects/cos-containerd"]
    }
  }
}

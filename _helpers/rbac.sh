#!/usr/bin/env bash
# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


source workstation.env

# in-scope
helm template \
--set namespace=${IN_SCOPE_NAMESPACE},pod_readers_group=${IN_SCOPE_POD_READERS_GROUP},namespace_admins_group=${IN_SCOPE_NAMESPACE_ADMINS_GROUP} \
k8s/helm/rbac | kubectl --context ${IN_SCOPE_CONTEXT} apply -f -

# out-of-scope
helm template \
--set namespace=${OUT_OF_SCOPE_NAMESPACE},pod_readers_group=${OUT_OF_SCOPE_POD_READERS_GROUP},namespace_admins_group=${OUT_OF_SCOPE_NAMESPACE_ADMINS_GROUP} \
k8s/helm/rbac | kubectl --context ${OUT_OF_SCOPE_CONTEXT} apply -f -

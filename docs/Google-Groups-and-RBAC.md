# Kubernetes RBAC via Google Groups membership demonstration

* This document is a walkthrough demonstration of Kubernetes role based access control (RBAC) via Google Groups membership. It requires creating various user accounts and Google groups, and shows how differing levels of access can be achieved by controlling group membership.

## Create Users, and Google Groups

* In the Gsuite account associated with your GCP organization, these users need to exist: `user1@domain`, `user2@domain`, `user3@domain`, `user4@domain`

* Create these groups with the indicated memberships

|Group Description   |Group Name | Members|
|---|---|---|
| Pod reader in the in-scope namespace	| in-scope-developers-pci@domain |	user1@domain
| Deployment admin in the in-scope namespace|	in-scope-admins-pci@domain |	user2@domain
| Pod reader in the out-of-scope namespace	| out-of-scope-developers-pci@domain	| user3@domain
| Deployment admin in the out-of-scope namespace	| out-of-scope-admins-pci@domain	| user4@domain
| Default parent group |	gke-security-groups@domain	| in-scope-developers-pci@domain, in-scope-admins-pci@domain, out-of-scope-developers-pci@domain, out-of-scope-admins-pci@domain

## Cloud IAM
* In the GCP console, use the project navigator to choose the folder "blueprint-pci" (or what you have chosen as the folder to contain your resources, as defined by `TF_VAR_folder_id`). Using IAM, add a permission:  `gke-security-groups@domain` as a member, and Kubernetes Engine Cluster Viewer as the role.

## Add the appropriate Roles and RoleBindings

Ensure that the `# RBAC settings` section of your workstation.env is correct. As cluster admin, apply the role based access rules by running `./_helpers/rbac.sh`. This script applies Kubernetes Roles and ClusterRoleBindings to both clusters using values from `workstation.env`

## Authenticate as each on the command line

Set up some environment variables and authenticate as each user. For the walkthrough, we'll only need to authenticate as user1@ and user2@. Run `gcloud auth login` and log in as each in a browser. It's useful to do this in an ephemeral browser session like Chrome's Incognito

# Testing Access

* These steps walk through masquerading as some of the other users in order to demonstrate those users' access or lack of access.

## In-scope pod readers

```
export MASQUERADE_USER="user1"
gcloud config set account ${MASQUERADE_USER}@domain
export KUBECONFIG=${SRC_PATH}/${REPOSITORY_NAME}/private/kubeconfig-${MASQUERADE_USER}
gcloud container clusters get-credentials in-scope --region us-central1 --project ${TF_VAR_project_prefix}-in-scope
```

* Members of in-scope-developers-pci@domain, namely user1@domain can get pods, but not delete them. Or most other operations:

```
$ kubectl -n in-scope get pod -l app=frontend
NAME                        READY   STATUS    RESTARTS   AGE
frontend-75c69544cc-m2ztg   2/2     Running   0          19h

$ kubectl -n in-scope delete pod -l app=frontend
Error from server (Forbidden): pods "frontend-75c69544cc-m2ztg" is forbidden: User "user1@domain" cannot delete resource "pods" in API group "" in the namespace "in-scope": Required "container.pods.delete" permission.

$ kubectl -n in-scope get deployment -l app=frontend
Error from server (Forbidden): deployments.extensions is forbidden: User "user1@domain" cannot list resource "deployments" in API group "extensions" in the namespace "in-scope": Required "container.deployments.list" permission.
```

## In-scope namespace admins

```
export MASQUERADE_USER="user2"
gcloud config set account ${MASQUERADE_USER}@domain
export KUBECONFIG=${SRC_PATH}/${REPOSITORY_NAME}/private/kubeconfig-${MASQUERADE_USER}
gcloud container clusters get-credentials in-scope --region us-central1 --project ${TF_VAR_project_prefix}-in-scope
```

Members of in-scope-admins-pci@domain, namely user2@domain can get all pods in the in-scope namespace:

```
$ kubectl -n in-scope get pod
NAME                               READY   STATUS    RESTARTS   AGE
checkoutservice-7bc7567db4-c8gnl   2/2     Running   0          19h
frontend-75c69544cc-m2ztg          2/2     Running   0          19h
paymentservice-8597659d47-xqw6l    2/2     Running   0          19h
```

Not in any other:

```
$ kubectl get pod --all-namespaces
Error from server (Forbidden): pods is forbidden: User "user2@domain" cannot list resource "pods" in API group "" at the cluster scope: Required "container.pods.list" permission.
```

Can delete a pod in in-scope:

```
$ kubectl -n in-scope get pod -l app=frontend
NAME                        READY   STATUS    RESTARTS   AGE
frontend-75c69544cc-m2ztg   2/2     Running   0          19h
src/terraform-pci-internal$ kubectl -n in-scope delete pod -l app=frontend
pod "frontend-75c69544cc-m2ztg" deleted
```

Can run `gcloud get-credentials` to authenticate to the out-of-scope cluster (by virtue of membership in `gke-security-groups@domain`) but can't `kubectl get pod` there:

```
$ gcloud container clusters get-credentials out-of-scope --region us-central1 --project ${TF_VAR_project_prefix}-out-of-scope
Fetching cluster endpoint and auth data.
kubeconfig entry generated for out-of-scope.
$ kubectl get pod
Error from server (Forbidden): pods is forbidden: User "user2@domain" cannot list resource "pods" in API group "" in the namespace "default": Required "container.pods.list" permission.
```


# Cleaning Up

These commands will revert your gcloud CLI user context and set `KUBECONFIG` as used in the rest of this repository.

```
gcloud config set account $YOUR_GOOGLE_ACCOUNT
export KUBECONFIG=${SRC_PATH}/${REPOSITORY_NAME}/private/kubeconfig
```

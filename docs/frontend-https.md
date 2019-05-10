# Additional Note on Google-Managed SSL Certificates


If you want to use Google-Managed certificates, you must set a
domain name configured with a DNS record that points to the load
balancer's public IP address. That IP address is outputted on the
command line when `terraform apply` was run in the
`terraform/components/out-of-scope` directory. It is also
accessible in the GCP console in the out-of-scope project's load
balancer's details.

If you want to use a self-signed certificate instead or can't
access the domain's DNS record, just leave out `--set
domain_name=${DOMAIN_NAME}` from the previous section's `helm` command.

## Verification

For GCP-Managed Certificates, it can take some time (15-60 minutes) for new certificate generation. After running the `helm` commands from the previous sections, check the status of managed certificates with

```
kubectl --context in-scope describe managedcertificate frontend-certificate
```

and to fetch information on the underlying GCP SSL certificate resource:

```
gcloud beta compute ssl-certificates list --project=${TF_VAR_project_prefix}-out-of-scope
```

Take the certificate's resource name, and view the status with:

```
gcloud beta compute ssl-certificates describe SSL_CERT_NAME --project=${TF_VAR_project_prefix}-out-of-scope
```

When `kubectl describe managedcertificates frontend-certificate` displays
`Status > Domain Status > Status: Active`, you can be sure the certificate is
generated successfully.

## See Also

For more info on GCP-Managed Certificates, see the following documentation:

* Kubernetes > [Using Google-managed SSL certificates](https://cloud.google.com/kubernetes-engine/docs/how-to/managed-certs)
* [Working with Google-managed SSL certificates](https://cloud.google.com/load-balancing/docs/ssl-certificates#managed-certs)


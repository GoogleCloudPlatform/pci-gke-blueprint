# SSL Certificates

This project supports two options for supplying certificates for TLS encrypted communication with the frontend
load balancer: Using a self-signed certificates or a Google Managed certificate. For more details on self-managed and self-signed certificates, see [Working with self-managed SSL certificates](https://cloud.google.com/load-balancing/docs/ssl-certificates#working-self-managed). Note the warning: "...Self-signed certificates are not suitable for public sites. While a self-signed certificate implements full encryption, it will cause most browsers to present a warning or error when visitors try to access your site." Alternatively, if you want to use Google-Managed certificates, it must be mapped to a public DNS
domain name that you control. It will need to be configured with a DNS record that points to the load
balancer's public IP address.

## Deploying with a self-managed SSL certificate

The default configuration is to deploy using a self-signed certificate. If the in-scope-microservices helm chart is installed without passing `--set domain_name=${DOMAIN_NAME}`, then
the Secret `tls-hipsterservice` created as part of the installation instructions will be used.

## Deploying with a Google-Managed SSL certificate

### Configure DNS

Uncomment and set the `DOMAIN_NAME` variable in `workstation.env`, and source the file once again: `source workstation.env`

The domain name will then need to be configured with the public IP address of the frontend load balancer. That IP address is obtained from the output of the
`terraform apply` command when run in the `terraform/components/in-scope` directory. It is also
accessible in the GCP console, in the in-scope project's load
balancer's details. From the Console, ensure that the in-scope project is selected, and navigate to Network Services > Load Balancing. There should only be one entry, click on it to view its details,
including its IP address.

As described in the Readme, this command is used to initially install the helm chart, including supplying the domain name:

```
helm install \
  --kube-context in-scope \
  --name in-scope-microservices
  --set nginx_listener_1_ip="$(kubectl --context out-of-scope get svc nginx-listener-1 -o jsonpath="{.status.loadBalancer.ingress[*].ip}")" \
  --set nginx_listener_2_ip="$(kubectl --context out-of-scope get svc nginx-listener-2 -o jsonpath="{.status.loadBalancer.ingress[*].ip}")" \
  --set domain_name=${DOMAIN_NAME} \
  ./in-scope-microservices
```

## Verification

For GCP-Managed Certificates, it can take some time (15-60 minutes) for new certificate generation. After running the `helm` commands from the previous sections, check the status of managed certificates with

```
kubectl --context in-scope describe managedcertificate frontend-certificate
```

and to fetch information on the underlying GCP SSL certificate resource:

```
gcloud beta compute ssl-certificates list --project=${TF_VAR_project_prefix}-in-scope
```

Copy the certificate's resource name to the clipboard, and using it to view the status with:

```
gcloud beta compute ssl-certificates describe SSL_CERT_NAME --project=${TF_VAR_project_prefix}-in-scope
```

When `kubectl describe --context in-scope managedcertificates frontend-certificate` displays
`Status > Domain Status > Status: Active`, you can be sure the certificate is
generated successfully. You can then verify by loading https://$DOMAIN_NAME in a browser.

## See Also

For more info on GCP-Managed Certificates, see the following documentation:

* Kubernetes > [Using Google-managed SSL certificates](https://cloud.google.com/kubernetes-engine/docs/how-to/managed-certs)
* [Working with Google-managed SSL certificates](https://cloud.google.com/load-balancing/docs/ssl-certificates#managed-certs)

# Microservices Demo Frontend over HTTPS

The load balancer for the frontend (`components/out-of-scope/application/kubernetes-manifests/frontend.yaml`)
can be configured to use either a self-signed SSL certificate or a Google Managed
SSL Certificate. Both configuration options are included.

After completing the configuration for either option, the steps in the [Apply the out-of-scope Kubernetes configurations](../README.md#apply-the-out-of-scope-kubernetes-configurations)
section can be continued.

## Load Balancing over HTTPS Using a self-signed certificate

1. From the `components/out-of-scope/application/` directory, run `generate-config.sh`
That will place a copy of `ingress.yaml` in the `kubernetes-manifests` directory
that will use a self-signed certificate via the `tls` Secret created in the Readme.

## Using a Google Managed SSL Certificate for the Frontend Load Balancer

### Requirements

An additional requirement is a domain name configured with a DNS record that
points to the load balancer's public IP address. That IP address is outputted on
the command line when `terraform apply` was run in the
`components/out-of-scope/infrastructure` directory. It is also accessible in the GCP
console in the out-of-scope project's load balancer's details.

### Configuration

1. From the `components/out-of-scope/application/` directory, run `DOMAIN_NAME=<your-domain-name.com> ./generate-config.sh`
That will generate a copy of `ingress.yaml` in the `kubernetes-manifests` directory
that will create a generated Google-managed certificate and configure an Ingress
rule that uses the certificate.

1. To apply the configuration, run:

```
kubectl apply -f kubernetes-manifests/with-managed-ssl/frontend.yaml
```

### Verification
Certificate generation and validation can take from 15 to 60 minutes to complete.

The status of the managedcertificate can be viewed with

```
kubectl --context out-of-scope describe managedcertificate frontend-certificate
```

The underlying GCP ssl-certificate resource name can be retrieved with:

```
gcloud beta compute ssl-certificates list --project=OUT_OF_SCOPE_PROJECT
```

Using the certificate's name, the status can be viewed via:

```
gcloud beta compute ssl-certificates describe SSL_CERT_NAME --project=OUT_OF_SCOPE_PROJECT
```

The certificate has been successfully generated when the output of
`kubectl describe managedcertificates frontend-certificate` displays Status > Domain Status > Status: Active

## See Also

* Kubernetes > [Using Google-managed SSL certificates](https://cloud.google.com/kubernetes-engine/docs/how-to/managed-certs)
* [Working with Google-managed SSL certificates](https://cloud.google.com/load-balancing/docs/ssl-certificates#managed-certs)

# Forseti + Cloud Security Command Center

## Installation

1. Make sure your shell is in the `components/forseti` directory
1. Create a new `backend.tf` by copying `backend.tf.example` and replacing the
bucket value with your Terraform state bucket name
1. Run `terraform init`
1. Run `terraform apply`
1. Verify by checking that the Management project has two new GCE instances:
one for the Forseti client and one for the Forseti server. Additionally, there
should also be a CloudSQL instance.


## Cloud Security Command Center Integration

Note: Your acting account must have at least `Security Center Admin Viewer` and
`Security Center Sources Admin` bound to the appropriate Organization to
continue with this procedure.

1. Select `Add Security Sources` on the Cloud SCC Dashboard
1. Find the [Forseti Cloud
Connector](https://console.cloud.google.com/marketplace/details/forseti/forseti-security-cloud-scc-connector)
and click the sign up button
1. Follow the instructions making sure to select the management project and the
Forseti server service account when asked
1. After setting up the Forseti-Cloud SCC connector, you should receive a
Source ID. If you can't find it, navigate to the CSCC dashboard, click
**Settings** in the top right, and click the **Security Sources** tab.
1. In your `shared.tf.local`, add values for the following local variables:
    - `forseti_cscc_source_id`: Value of the Forseti Source ID from the previous step
    - `forseti_cscc_violations_enabled`: `"true"`
1. Navigate your shell to the `components/forseti` directory and re-run `terraform apply`. Terraform should take care of setting the configuration file values and re-deploying the Forseti Server.
1. To validate immediately SSH to the forseti client compute instance and do the following tasks:
    1. [build an inventory](https://forsetisecurity.org/docs/v2.13/use/cli/inventory.html)
    1. [run a scan](https://forsetisecurity.org/docs/v2.13/use/cli/scanner.html)
    1. [execute a notifier](https://forsetisecurity.org/docs/v2.13/use/cli/notifier.html)

If everything is set up correctly, information will start to
appear in the Cloud Security Command Center dashboard.

After verifying setup, Forseti will continue to run these scans
and notifications as system cron jobs.

## Related Links

- [Setting Up Notifications](https://forsetisecurity.org/docs/v2.13/configure/notifier/#cloud-scc-notification)
- [Viewing Vulnerabilities](https://cloud.google.com/security-command-center/docs/how-to-view-vulnerabilities-threats)
- [Forseti Cloud SCC Setup](https://forsetisecurity.org/docs/v2.9/configure/notifier/#setup)

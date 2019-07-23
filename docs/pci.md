# PCI DSS Requirements

| PCI DSS Requirements v3.2.1 | Description of Implementation |
| -------------------------- | ------------------------------ |
| 1. Install and maintain a firewall configuration to protect cardholder data | |
| 1.1.2 Current network diagram that identifies all connections between the cardholder data environment and other networks, including any wireless networks | [Architecture Diagram](https://github.com/GoogleCloudPlatform/terraform-pci-starter/blob/master/docs/diagrams/application_traffic.png) |
| 1.1.3 Current diagram that shows all cardholder data flows across systems and networks. | [Architecture Diagram](https://github.com/GoogleCloudPlatform/terraform-pci-starter/blob/master/docs/diagrams/application_traffic.png) |
| 1.1.4 Requirements for a firewall at each Internet connection and between any demilitarized zone (DMZ) and the Internal network zone | A frontend load balancer is used to restrict Internet traffic to the frontend kubernetes pods only on port 443 |
| 1.2.1  Restrict inbound and outbound traffic to that which is necessary for the cardholder data environment, and specifically deny all other traffic. | Firewall rules and internal load balancers are used to restrict traffic into and out of the CDE environment |
| 1.2.2 Secure and synchronize router configuration files.  | Terraform .tf files |
| 1.3.1 Implement a DMZ to limit inbound traffic to only system components that provide authorized publicly accessible services, protocols, and ports. | Segmented subnets, firewall rules and load balancers limit traffic to specific ports and pods |
| 1.3.2 Limit inbound Internet traffic to IP addresses within the DMZ. | A frontend load balancer is used to restrict Internet traffic to the frontend kubernetes pods only |
| 1.3.4 Do not allow unauthorized outbound traffic from the cardholder data environment to the Internet. | Firewall rules are use to restrict outbound traffic from the nodes |
| 1.3.5 Permit only “established” connections into the network. | Firewall rules are use to restrict inbound and outbound traffic |
| 1.3.6 Place system components that store cardholder data (such as a database) in an internal network zone, segregated from the DMZ and other untrusted networks. | PCI nodes are in their own subnet which is different from the public load balancer(s) |
| 1.3.7 Do not disclose private IP addresses and routing information to unauthorized parties. | RFC 1918 address space is used for all PCI nodes |
| 2. Do not use vendor-supplied defaults for system passwords and other security parameters | |
| 3. Protect stored cardholder data | |
| 4. Encrypt transmission of cardholder data across open, public networks | |
| 5. Use and regularly update anti-virus software or programs | |
| 6. Develop and maintain secure systems and applications | |
| 7. Restrict access to cardholder data by business need-to-know | |
| 8. Assign a unique ID to each person with computer access | |
| 9. Restrict physical access to cardholder data | Google is responsible for physical security controls on all Google data centers underlying GCP. |
| 10. Track and monitor all access to network resources and cardholder data | |
| 11. Regularly test security systems and processes | |
| 12. Maintain a policy that addresses information security for all personnel | More information about requirement 12 can be found in the [GCP PCI Shared Responsibility Matrix](http://services.google.com/fh/files/misc/gcp_crm_2018.pdf) |

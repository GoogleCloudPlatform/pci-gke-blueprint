# PCI DSS Requirements

| PCI DSS Requirements v3.2.1 | Description of Implementation |
| -------------------------- | ------------------------------ |
| **1. Install and maintain a firewall configuration to protect cardholder data** | |
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
| **2. Do not use vendor-supplied defaults for system passwords and other security parameters** | |
| 2.2.1  Implement only one primary function per server to prevent functions that require different security levels from co-existing on the same server. (For example, web servers, database servers, and DNS should be implemented on separate servers.) | There is 1 service per containers and containers are grouped in specific pods and clusters |
| 2.2.2 Enable only necessary services,  protocols, daemons, etc., as required for the function of the system. | COS is being used at the node OS |
| 2.2.3 Implement additional security features for any required services, protocols, or daemons that are considered to be insecure. | TLS is being used for all traffic in and out of the in-scope VPC |
| 2.2.5  Remove all unnecessary functionality, such as scripts, drivers, features, subsystems, file systems, and unnecessary web servers. | COS is being used as the OS and the containers only container the necessary code and libraries for their service / function |
| 2.3 Encrypt all non-console administrative access using strong cryptography. | TLS and SSH are being used |
| 2.4 Maintain an inventory of system components that are in scope for PCI DSS. | This can be tracked with Forseti or the Terraform templates |
| **3. Protect stored cardholder data** | |
| 3.3 Mask PAN when displayed (the first six and last four digits are the maximum number of digits to be displayed), such that only personnel with a legitimate business need can see more than the first six/last four digits of the PAN. | Cloud DLP is used to redact the PAN in stackdriver logs |
| 3.4 Render PAN unreadable anywhere it is stored (including on portable digital media, backup media, and in logs) by using any of the following approaches: One-way hashes based on strong cryptography, (hash must be of the entire PAN), Truncation (hashing cannot be used to replace the truncated segment of PAN), Index tokens and pads (pads must be securely stored), Strong cryptography with associated key-management processes and procedures. | Cloud DLP is used to redact the PAN in stackdriver logs |
| **4. Encrypt transmission of cardholder data across open, public networks** | |
| 4.1 Use strong cryptography and security protocols to safeguard sensitive cardholder data during transmission over open, public networks, including the following: • Only trusted keys and certificates are accepted. • The protocol in use only supports secure versions or configurations. • The encryption strength is appropriate for the encryption methodology in use. | TLS with Frontend Load Balancers is being used |
| **5. Use and regularly update anti-virus software or programs** | Not currently implemented in this project |
| **6. Develop and maintain secure systems and applications** | |
| **7. Restrict access to cardholder data by business need-to-know** | |
| **8. Assign a unique ID to each person with computer access** | Not currently implemented in this project. Cloud Identity, IAM and RBAC can be used to meet requirement 8  |
| **9. Restrict physical access to cardholder data** | Google is responsible for physical security controls on all Google data centers underlying GCP. |
| **10. Track and monitor all access to network resources and cardholder data** | |
| 10.1  Implement audit trails to link all access to system components to each individual user. | Audit logs and Stackdriver are being used |  
| 10.2  Implement automated audit trails for all system components to reconstruct the following events: | Audit Logs |
| 10.2.1 All individual user accesses to cardholder data. | Audit Logs |
| 10.2.2 All actions taken by any individual with root or administrative privileges. | Audit Logs |
| 10.2.3 Access to all audit trails. | Audit Logs |
| 10.2.4 Invalid logical access attempts. | Audit Logs |
| 10.3 Record at least the following audit trail entries for all system components for each event: | Audit Logs and Stackdriver |
| 10.3.1 User identification. | Audit Logs and Stackdriver |
| 10.3.2 Type of event. | Audit Logs and Stackdriver |
| 10.3.3 Date and time. | Audit Logs and Stackdriver |
| 10.3.4 Success or failure indication. | Audit Logs and Stackdriver |
| 10.3.5 Origination of event. | Audit Logs and Stackdriver |
| 10.3.6 Identity or name of affected data, system component, or resource. | Audit Logs and Stackdriver |
| 10.4 Using time-synchronization technology, synchronize all critical system clocks and times and ensure that the following is implemented for acquiring, distributing, and storing time.| Google NTP servers are being used |
| 10.4.1 Critical systems have the correct and consistent time. | Google NTP servers are being used |
| 10.4.3 Time settings are received from industry-accepted time sources. | Google NTP servers are being used |
| 10.5 Secure audit trails so they cannot be altered. | |
| 10.5.1 Limit viewing of audit trails to those with a job-related need. | Logs are in their own project, which could be restricted |
| 10.5.4 Write logs for external-facing technologies onto a secure, centralized, internal log server or media device. | Logs are in their own project and storage buckets |
| **11. Regularly test security systems and processes** | N/A for this project |
| **12. Maintain a policy that addresses information security for all personnel** | More information about requirement 12 can be found in the [GCP PCI Shared Responsibility Matrix](http://services.google.com/fh/files/misc/gcp_crm_2018.pdf) |

# gRPC Proxying with Nginx

Nginx is used as a TLS encrypted gRPC proxy on both clusters.

![Nginx gRPC Proxying](/docs/diagrams/application_traffic.png)

In the default [microservices-demo architecture](https://github.com/GoogleCloudPlatform/microservices-demo#service-architecture), the fronted service connects directly with its
dependent services such as the product (catalog) service, and the recommendation
service. In this project, we have split the microservices across two separate
clusters, the in-scope and out-of-scope clusters.

After splitting the services, in order to allow the required connections to be
made, and to be made securely, Nginx-based gRPC proxies were introduced. Instead
of paymentservice connecting directly to the productservice application, it
instead connects to the "nginx-sender" Kubernetes Deployment running in the
in-scope cluster. That Deployment includes an Nginx service configured to listen
for paymentservice connections (tcp, port 3550 in this example), and then
forwards and encrypts the request to one of the two "nginx-listener" Deployments
residing on the out-of-scope cluster.

There are two "nginx-listener" Deployments since each includes an Internal Load
Balancer which is to be configured on a total of 7 tcp ports, and there is a 5
port limit for tcp-based internal load balancers. Each "nginx-listener" then
receives the encrypted gRPC forwarded request from the "nginx-sender" and in
turn forwards on that request to the respective required service.

These gRPC proxies are packaged along with the application's configurations in
their respective helm charts: [nginx-sender-configmap](/helm/in-scope-microservices/templates/nginx-sender-configmap.yaml#L38) and [nginx-listener-configmap.yaml](https://github.com/GoogleCloudPlatform/terraform-pci-starter/blob/master/helm/out-of-scope-microservices/templates/nginx-listener-configmap.yaml#L41).

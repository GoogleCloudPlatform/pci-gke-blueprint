# HTTP to HTTPS redirection

HTTP to HTTPS redirection (SSL redirection) is currently an [open issue](https://github.com/kubernetes/ingress-gce/issues/51) in the ingress-gce project. Until implemented and released, it is accomplished in this project by the frontend application. The upstream [microservices-demo frontend image](https://github.com/GoogleCloudPlatform/microservices-demo/tree/master/src/frontend) is used as a base, and customized by adding a reverse proxy in front of the microservice. This is accomplished with nginx, and its [proxy_pass](https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_pass) directive. The end result is that HTTP requests to the load balancer are forwarded through to the frontend, detected as being http requests, and an HTTP 301 redirect is returned as the response. HTTPS requests are similarly forwarded, detected as originating as HTTPS, and proxied through to the frontend microservice.

## Building the custom frontend image

A public custom frontend image is published and used by this project. The [build.sh](../microservices-demo/frontend/build.sh) script is used to build and push it to a GCP container registry repository.  When run, it creates a temporary directory, clones the upstream repository, and customizes it by changing the final image to be an `alpine:nginx` image with the previously built frontend Go package installed:

```
...
FROM nginx:alpine as release
...
```

## Nginx configuration

The reverse proxy configuration in `default.conf` is added to the image as well. This config checks for the [X-Forwarded-Proto:](https://cloud.google.com/load-balancing/docs/https#target-proxies) header, and if it is https, proxies it to the frontend service listening on port 8000. Additional logic is in place to allow the HTTP/S load balancer's health check, (user-agent matching `GoogleHC`) to be proxied through as well, allowing successful health checks. This is required since an http 301 redirect response in this situation is considered a failed health check ([Success criteria for HTTP, HTTPS, and HTTP/2](https://cloud.google.com/load-balancing/docs/health-check-concepts#criteria-protocol-http)).

```
server {
  listen 80;
  location / {
    if ($http_user_agent ~* "^GoogleHC") {
      proxy_pass http://localhost:8080 ;
      break;
    }
    if ($http_x_forwarded_proto = "https") {
      proxy_pass http://localhost:8080 ;
      break;
    }
    return 301 https://$host$request_uri;
  }
...
```

## Kubernetes Deployment health checks

The readinessProbe and livenessProbes of the frontend deployment require updates so that they set the
`X-Forwarded-Proto` header when running their checks:

```
kind: Deployment
metadata:
  name: frontend
...
          readinessProbe:
            initialDelaySeconds: 10
            httpGet:
              path: "/_healthz"
              port: 80
              httpHeaders:
              - name: "Cookie"
                value: "shop_session-id=x-readiness-probe"
              - name: "X-Forwarded-Proto"
                value: "https"
          livenessProbe:
            initialDelaySeconds: 10
            httpGet:
              path: "/_healthz"
              port: 80
              httpHeaders:
              - name: "Cookie"
                value: "shop_session-id=x-liveness-probe"
              - name: "X-Forwarded-Proto"
                value: "https"
...
```

## Sidecar alternative

Similar behavior would be achievable without customizing the frontend image by using a sidecar container. That would be preferable in a non-Istio enabled namespace. However, Istio's automated sidecar-injection doesn't work well with multiple network-listening containers on a single Pod.

# Copied and edited from original at
# https://github.com/GoogleCloudPlatform/microservices-demo/blob/d66cbdd27f73bb1ffa7479a3527f55dec070baa0/src/frontend/Dockerfile

FROM golang:1.12-alpine as builder
RUN apk add --no-cache ca-certificates git && \
      wget -qO/go/bin/dep https://github.com/golang/dep/releases/download/v0.5.0/dep-linux-amd64 && \
      chmod +x /go/bin/dep

ENV PROJECT github.com/GoogleCloudPlatform/microservices-demo/src/frontend
WORKDIR /go/src/$PROJECT

# restore dependencies
COPY Gopkg.* ./
RUN dep ensure --vendor-only -v
COPY . .
RUN go install .

FROM nginx:alpine as release

RUN apk add --no-cache ca-certificates \
    busybox-extras net-tools bind-tools
WORKDIR /frontend
COPY --from=builder /go/bin/frontend /frontend/server
COPY ./templates ./templates
COPY ./static ./static

COPY ./run.sh /bin/run.sh
EXPOSE 80
COPY default.conf /etc/nginx/conf.d/default.conf
ENTRYPOINT ["/bin/run.sh" ]

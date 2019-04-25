The files in this directory contain the files needed to build a customized version
of the fluentd-gcp logging agent that includes the `fluent-plugin-gcp-dlp-filter`.

## Building and deploying

To build the container, set `PROJECT_PREFIX` in `build.sh` before running it. It
will build, tag and push the container to GCR. The image will be tagged with the
git sha from `git log` and outputted to to the console. Use that value for
`FLUENTD_IMAGE_REMOTE_REPO` when later configuring and running `../generate-config.sh`

# Versions

Currently, the version of `fluentd-gcp` installed by GKE when using the built-in
[logging option](https://cloud.google.com/monitoring/kubernetes-engine/legacy-stackdriver/logging#enabling_stackdriver_logging)
is [0.6-1.6.0-1](https://console.cloud.google.com/gcr/images/stackdriver-agents/GLOBAL/stackdriver-logging-agent@sha256:f8d5231b67b9c53f60068b535a11811d29d1b3efd53d2b79f2a2591ea338e4f2/details?tab=info) which is built from [v1.6.0](https://github.com/GoogleCloudPlatform/google-fluentd/releases/tag/v1.6.0) as published in Github.


To be consistent with GKE, the files in this directory are sourced and edited from
[google-fluentd @v1.6.0](https://github.com/GoogleCloudPlatform/google-fluentd/releases/tag/v1.6.0).

# The DLP API fluentd filter

This Dockerfile includes:
```
RUN curl -LOs https://github.com/salrashid123/fluent-plugin-gcp-dlp-filter/raw/master/fluent-plugin-gcp-dlp-filter-0.0.7.gem
```
which uses the `fluent-plugin-gcp-dlp-filter` from https://github.com/salrashid123/fluent-plugin-gcp-dlp-filter.

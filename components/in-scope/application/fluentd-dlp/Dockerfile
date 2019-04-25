# Copied and edited from: https://github.com/GoogleCloudPlatform/google-fluentd/blob/43b8f932bd4e7e1004c5b8079bd63ead74b1859e/docker/Dockerfile

FROM debian:9.5-slim

# TODO: This may be a moving target, figure out how to pin.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        gnupg2 \
        lsb-release \
        build-essential \
        procps \
        systemd \
        ca-certificates \
        adduser \
    # Install google-fluentd at version 1.6.0-1.
    && curl -sS https://dl.google.com/cloudagents/install-logging-agent.sh | REPO_SUFFIX=20181011-3 DO_NOT_INSTALL_CATCH_ALL_CONFIG=true bash
    # If any additional gems need to be installed, it should happen before the
    # image cleanup.
    # ==> INSTALL_ADDITIONAL_GEMS_HERE_IF_NEEDED <==

RUN /opt/google-fluentd/embedded/bin/gem install google-cloud-dlp -v 0.8.0 --no-ri --no-rdoc
RUN curl -LOs https://github.com/salrashid123/fluent-plugin-gcp-dlp-filter/raw/master/fluent-plugin-gcp-dlp-filter-0.0.7.gem
RUN /opt/google-fluentd/embedded/bin/gem install --local  /fluent-plugin-gcp-dlp-filter-0.0.7.gem

RUN sed -i "s/num_threads 8/num_threads 8\n  detect_json true\n  # Enable metadata agent lookups.\n  enable_metadata_agent true\n  metadata_agent_url \"http:\/\/local-metadata-agent.stackdriver.com:8000\"/" "/etc/google-fluentd/google-fluentd.conf"

ENV LD_PRELOAD=/opt/google-fluentd/embedded/lib/libjemalloc.so

COPY entrypoint.sh Dockerfile /

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/google-fluentd"]

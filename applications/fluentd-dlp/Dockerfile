# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Copied and edited from: https://github.com/GoogleCloudPlatform/google-fluentd/blob/43b8f932bd4e7e1004c5b8079bd63ead74b1859e/docker/Dockerfile

FROM debian:9.5-slim

# TODO: This may be a moving target, figure out how to pin.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl=7.52.1-5+deb9u9 \
        gnupg2=2.1.18-8~deb9u4\
        lsb-release=9.20161125 \
        build-essential=12.3 \
        procps=2:3.3.12-3+deb9u1 \
        systemd=232-25+deb9u11 \
        ca-certificates=20161130+nmu1+deb9u1 \
        adduser=3.115 \
    # Install google-fluentd at version 1.6.0-1.
    && curl -sS https://dl.google.com/cloudagents/install-logging-agent.sh | REPO_SUFFIX=20181011-3 DO_NOT_INSTALL_CATCH_ALL_CONFIG=true bash \
    # If any additional gems need to be installed, it should happen before the
    # image cleanup.
    # ==> INSTALL_ADDITIONAL_GEMS_HERE_IF_NEEDED <==
    && /opt/google-fluentd/embedded/bin/gem install google-cloud-dlp -v 0.8.0 --no-ri --no-rdoc \
    && curl -LOs https://github.com/salrashid123/fluent-plugin-gcp-dlp-filter/raw/master/fluent-plugin-gcp-dlp-filter-0.0.7.gem \
    && /opt/google-fluentd/embedded/bin/gem install --local  /fluent-plugin-gcp-dlp-filter-0.0.7.gem \
    # BEGIN CLEANUP
    && apt-get purge -y \
        curl \
        lsb-release \
        build-essential \
        gtk2.0 \
        libkrb5-3 \
    && apt-get autoremove -y --purge \
    # Remove docs.
    && rm -rf \
        /usr/share/doc \
        /usr/share/man \
        /opt/google-fluentd/embedded/lib/ruby/gems/*/doc \
        /opt/google-fluentd/embedded/share/doc \
        /opt/google-fluentd/embedded/share/gtk-doc \
        /opt/google-fluentd/embedded/share/man \
        /opt/google-fluentd/embedded/share/terminfo \
    # Remove unused gems.
    && /opt/google-fluentd/embedded/bin/gem uninstall -ax --force \
        # Gems for ingesting logs to Treasure Data Cloud.
        td \
        td-client \
        td-logger \
        fluent-plugin-td \
        fluent-plugin-td-monitoring \
        hirb \
        parallel \
        ohai \
        mixlib-cli \
        mixlib-config \
        mixlib-log \
        mixlib-shellout \
        systemu \
        # Gems for Mongo.
        fluent-plugin-mongo \
        mongo \
    # Remove unused gem versions.
    && /opt/google-fluentd/embedded/bin/gem uninstall httpclient -v 2.7.2 \
    && rm -rf \
        # Cache.
        /var/cache \
        # apt.
        /usr/bin/apt-* \
        /var/lib/apt/lists/* \
        # dpkg.
        /usr/bin/dpkg* \
        /var/lib/dpkg \
        # Temp files.
        /tmp/* \
        # LDAP.
        /usr/lib/x86_64-linux-gnu/libldap* \
        # IBM mainframe / EBCDIC specific encodings.
        /usr/lib/x86_64-linux-gnu/gconv/IBM* \
        /usr/lib/x86_64-linux-gnu/gconv/EBCDIC* \
        # ecpg.
        /opt/google-fluentd/embedded/bin/ecpg \
        # OpenSSL.
        /opt/google-fluentd/embedded/bin/openssl \
        /usr/bin/openssl \
        # Postgres.
        /opt/google-fluentd/embedded/bin/pg_* \
        /opt/google-fluentd/embedded/bin/postgre* \
        /opt/google-fluentd/embedded/share/postgre* \
        /opt/google-fluentd/embedded/lib/postgre* \
        /opt/google-fluentd/embedded/bin/psql \
        # libtool.
        /opt/google-fluentd/embedded/share/libtool \
        /opt/google-fluentd/embedded/bin/libtool \
        # .a files and include libraries.
        /opt/google-fluentd/embedded/include \
        /opt/google-fluentd/embedded/lib/*.a \
    # Log files.
    && find /var/log -name "*.log" -type f -delete \
    # Remove .c .cc .h files.
    && (find /opt/google-fluentd/embedded/ \( -name '*.c' -o -name '*.cc' -o -name '*.h' \) -exec rm '{}' ';') \
    # Remove unused api client libraries.
    && (find /opt/google-fluentd/embedded/lib/ruby/gems/*/gems/google-api-client-*/generated/google/apis -mindepth 1 -maxdepth 1 \! -name 'logging*' -exec  rm -rf '{}' ';') \
    && sed -i "s/num_threads 8/num_threads 8\n  detect_json true\n  # Enable metadata agent lookups.\n  enable_metadata_agent true\n  metadata_agent_url \"http:\/\/local-metadata-agent.stackdriver.com:8000\"/" "/etc/google-fluentd/google-fluentd.conf"


ENV LD_PRELOAD=/opt/google-fluentd/embedded/lib/libjemalloc.so

COPY entrypoint.sh Dockerfile /

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/google-fluentd"]

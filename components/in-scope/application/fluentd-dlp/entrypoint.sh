#!/bin/bash

# Copied and edited from:
# https://github.com/GoogleCloudPlatform/google-fluentd/blob/43b8f932bd4e7e1004c5b8079bd63ead74b1859e/docker/entrypoint.sh

# For systems without journald.
mkdir -p /var/log/journal

if [ -z "${METADATA_AGENT_URL:-}" -a -n "${METADATA_AGENT_HOSTNAME:-}" ]; then
  METADATA_AGENT_URL="http://${METADATA_AGENT_HOSTNAME}:8000"
fi
if [ -n "$METADATA_AGENT_URL" ]; then
  sed -i "s,http://local-metadata-agent.stackdriver.com:8000,$METADATA_AGENT_URL," \
    /etc/google-fluentd/google-fluentd.conf
fi

# This docker image supports sending either a flag or a command as the docker
# command. When a flag is sent, it will be passed on to the fluentd process.
# Anything else will be interpreted as the command to be run.
#
# Passing a flag.
# $ docker run -it {image:tag} -o /var/log/google-fluentd.log
#
# Passing a command.
# $ docker run -it {image:tag} /bin/bash
#
# Default behavior uses CMD defined in Dockerfile.
# $ docker run -it {image:tag}
if [ "${1:0:1}" = '-' ]; then
  exec "/usr/sbin/google-fluentd" "$@"
else
  exec "$@"
fi

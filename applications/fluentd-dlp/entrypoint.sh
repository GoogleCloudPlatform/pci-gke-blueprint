#!/bin/bash
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


# Copied and edited from:
# https://github.com/GoogleCloudPlatform/google-fluentd/blob/43b8f932bd4e7e1004c5b8079bd63ead74b1859e/docker/entrypoint.sh

# For systems without journald.
mkdir -p /var/log/journal

if [ -z "${METADATA_AGENT_URL:-}" ] && [ -n "${METADATA_AGENT_HOSTNAME:-}" ]; then
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

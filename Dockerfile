# This file is part of aws-cwl-exporter <https://github.com/StevenJDH/aws-cwl-exporter>.
# Copyright (C) 2022 Steven Jenkins De Haro.
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

FROM amazon/aws-cli:2.8.7

# Updating the base image to fix CVE issues,
# and installing a few needed tools.
RUN yum update -y && \
    yum install shadow-utils jq -y && \
    yum clean all && \
    rm -rf /var/cache/yum && \
    groupadd --system aws && \
    adduser --system aws -g aws

USER aws:aws
COPY --chown=aws:aws --chmod=0544 ./entry_script.sh /

ENTRYPOINT ["/bin/bash", "-c", "/entry_script.sh"]
#!/bin/bash

# This file is part of aws-cwl-exporter <https://github.com/StevenJDH/aws-cwl-exporter>.
# Copyright (C) 2022-2023 Steven Jenkins De Haro.
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

if [[ "$EXPORT_PERIOD" != 'daily' ]]; then
    MODE=HOURLY
    FROM=$(($(date -d "$(date +%Y/%m/%d' '%H:00:00 -d '1 hour ago' -u)" -u +%s) * 1000))
    TO=$(($(date -d "$(date +%Y/%m/%d' '%H:59:59 -d '1 hour ago' -u)" -u +%s) * 1000))
else
    MODE=DAILY
    FROM=$(($(date -d 'yesterday 00:00:00' -u +%s) * 1000))
    TO=$(($(date -d 'yesterday 23:59:59' -u +%s) * 1000))
fi

FROM_TS=$(date -d @$((FROM / 1000)) +%F'T'%T'Z' -u)
TO_TS=$(date -d @$((TO / 1000)) +%F'T'%T'Z' -u)

echo -e "\nCreating [$MODE][$FROM_TS to $TO_TS] export task request..."

RESPONSE=$(aws logs create-export-task --task-name log-group-$(($(date -u +%s) * 1000)) \
    --log-group-name "$LOG_GROUP_NAME" \
    --from "$FROM" \
    --to "$TO" \
    --destination "$S3_BUCKET_NAME" \
    --destination-prefix "$EXPORT_PREFIX" \
    --output json)

TASK_ID=$(jq -r '.taskId' <<< "$RESPONSE")

if [[ "$TASK_ID" == null || -z "$TASK_ID" ]]; then
    echo "$RESPONSE"
    exit 1
else
    echo "
----------------------------------------------------
|                 CreateExportTask                 |
+--------+-----------------------------------------+
|  taskId|  $TASK_ID   |
+--------+-----------------------------------------+
"
    echo -e "To track the task progress, use:\n"
    echo "aws logs describe-export-tasks --task-id $TASK_ID --output table"
fi
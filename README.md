# AWS CloudWatch Log Exporter

[![build](https://github.com/StevenJDH/aws-cwl-exporter/actions/workflows/generic-container-workflow.yml/badge.svg?branch=main)](https://github.com/StevenJDH/aws-cwl-exporter/actions/workflows/generic-container-workflow.yml)
![GitHub release (latest by date including pre-releases)](https://img.shields.io/github/v/release/StevenJDH/aws-cwl-exporter?include_prereleases)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/820cb5ee5c3a44a2bc63eecdbc55d08a)](https://www.codacy.com/gh/StevenJDH/aws-cwl-exporter/dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=StevenJDH/aws-cwl-exporter&amp;utm_campaign=Badge_Grade)
![Maintenance](https://img.shields.io/maintenance/yes/2024)
![GitHub](https://img.shields.io/github/license/StevenJDH/aws-cwl-exporter)

AWS CloudWatch Log Exporter is a productivity tool that makes it easy to schedule automated log exports to an AWS S3 Bucket. Currently in AWS, exporting logs is a manual task that is done using tools like Log Insights and the AWS CLI. None of these options provide a way to export logs to an S3 Bucket where additional features like storage classes, lifecycle policies, and legal holds can be leveraged. As a result, those desiring some form of automation will create a custom solution using something like a Lambda function to achieve this, but there are many approaches available that are written in different programming languages, and not everyone is a programmer. AWS CloudWatch Log Exporter is built ready to go, and can be quickly deployed as a CronJob or Scheduled Task to any cluster, or as a container directly.

[![Buy me a coffee](https://img.shields.io/static/v1?label=Buy%20me%20a&message=coffee&color=important&style=flat&logo=buy-me-a-coffee&logoColor=white)](https://www.buymeacoffee.com/stevenjdh)

## Features
* Export CloudWatch logs on an hourly or daily basis to an S3 Bucket.
* Automatic calculation of the needed time period being exported.
* Enable access by leveraging the AWS Credential Provider Chain. IRSA (IAM Roles for Service Accounts) is recommended.
* Can be deployed to EKS, ECS, and other managed and self-managed clusters.

## Prerequisites
* [Docker](https://www.docker.com/products/docker-desktop)/[Rancher](https://rancherdesktop.io) Desktop or Kubernetes for running the container.

## Container registries
AWS CloudWatch Log Exporter container images are currently hosted on the following platforms:

* [Docker Hub](https://hub.docker.com/r/stevenjdh/aws-cwl-exporter)
* [Amazon Elastic Container Registry (ECR)](https://gallery.ecr.aws/stevenjdh/aws-cwl-exporter)
* [GitHub Container Registry](https://github.com/users/StevenJDH/packages/container/package/aws-cwl-exporter)

For production use cases, it is not recommended to pull an image with the `:latest` tag, or no tag since these are equivalent.

## Helm chart
AWS CloudWatch Log Exporter can be optionally deployed to a Kubernetes cluster using the [AWS CloudWatch Log Exporter Helm Chart](https://github.com/StevenJDH/helm-charts/tree/main/charts/aws-cwl-exporter) that is managed in a separate repository. All of the features described below and more are supported by this chart.

## Usage
To run the application directly in a non-Kubernetes environment, use the approach below. Both `nerdctl` and `docker` CLIs are interchangeable here:

```bash
nerdctl run --rm --name aws-cwl-exporter \
    -e AWS_ACCESS_KEY_ID=xxxxxx \
    -e AWS_SECRET_ACCESS_KEY=xxxxxx \
    -e AWS_DEFAULT_REGION=eu-west-3  \
    -e LOG_GROUP_NAME="/aws/lambda/hello-world-dev" \
    -e S3_BUCKET_NAME=s3-example-log-exports \
    -e EXPORT_PREFIX=export-task-output \
    -e EXPORT_PERIOD=hourly \
    stevenjdh/aws-cwl-exporter:latest
```

If successful, the output will look similar to the following:

```text
Creating [HOURLY][2022-10-27T02:00:00Z to 2022-10-27T02:59:59Z] export task request...

----------------------------------------------------
|                 CreateExportTask                 |
+--------+-----------------------------------------+
|  taskId|  00000000-0000-0000-0000-000000000000   |
+--------+-----------------------------------------+

To track the task progress, use:

aws logs describe-export-tasks --task-id 00000000-0000-0000-0000-000000000000 --output table
```

The `aws logs describe-export-tasks` command can be used to track the progress of long running tasks. For example, using the command provides the following details:

```text
--------------------------------------------------------------------------------
|                              DescribeExportTasks                             |
+------------------------------------------------------------------------------+
||                                 exportTasks                                ||
|+--------------------+-------------------------------------------------------+|
||  destination       |  s3-example-log-exports                               ||
||  destinationPrefix |  export-task-output                                   ||
||  from              |  1666836000000                                        ||
||  logGroupName      |  /aws/lambda/hello-world-dev                          ||
||  taskId            |  00000000-0000-0000-0000-000000000000                 ||
||  taskName          |  log-group-1666839900000                              ||
||  to                |  1666839599000                                        ||
|+--------------------+-------------------------------------------------------+|
|||                               executionInfo                              |||
||+-------------------------------------+------------------------------------+||
|||  completionTime                     |  1666840020000                     |||
|||  creationTime                       |  1666839900000                     |||
||+-------------------------------------+------------------------------------+||
|||                                  status                                  |||
||+---------------------+----------------------------------------------------+||
|||  code               |  COMPLETED                                         |||
|||  message            |  Completed successfully                            |||
||+---------------------+----------------------------------------------------+||
```

> 📝**NOTE:** There is a limit of "one active (running or pending) export task at a time, per account. This quota can't be changed." See [CloudWatch Logs quotas](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/cloudwatch_limits_cwl.html) for more information.

## Configuration
The following environment variables are used to store the needed configuration. For access, the AWS Credential Provider Chain is used, which supports providing static credentials like below, or the recommended approach, enabling role based access via IRSA (IAM Roles for Service Accounts).

|   Environment variable | Description                                                                                               |
|-----------------------:|:----------------------------------------------------------------------------------------------------------|
|        LOG_GROUP_NAME: | Required. The name of the log group source for exporting logs from.                                       |
|        S3_BUCKET_NAME: | Required. The name of S3 bucket storing the exported log data. The bucket must be in the same AWS region. |
|         EXPORT_PREFIX: | Required. The prefix used as the start of the key for every object exported.                              |
|         EXPORT_PERIOD: | Optional. The `hourly` or `daily` period used for collecting logs. Not required unless set to `daily`.    |
|     AWS_ACCESS_KEY_ID: | Optional. The AWS access key associated with an IAM user or role. Not required when using [IRSA].         |
| AWS_SECRET_ACCESS_KEY: | Optional. The AWS secret key associated with the access key. Not required when using [IRSA].              |
|    AWS_DEFAULT_REGION: | Optional. The AWS Region to use for requests. Must match log group and S3 bucket region. Not required when using [IRSA].|

[IRSA]: https://github.com/StevenJDH/Terraform-Modules/tree/main/aws/irsa

## Policies
The following policies define the permissions that are needed for exporting CloudWatch logs and storing them in S3.

### IAM Identity policy
This policy example grants `logs:CreateExportTask` rights to the User or IRSA role (Recommended) associated with the application.

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "CWLGrantCreateExportTaskRights",
            "Effect": "Allow",
            "Action": "logs:CreateExportTask",
            "Resource": "arn:aws:logs:eu-west-3:000000000000:*"
        }
    ]
}
```

### S3 Bucket resource policy
This policy example grants write access to the `logs.eu-west-3.amazonaws.com` service. See [Set permissions on an Amazon S3 bucket](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/S3ExportTasksConsole.html#S3PermissionsConsole) for additional information.

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "logs.eu-west-3.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::s3-example-log-exports"
        },
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "logs.eu-west-3.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::s3-example-log-exports/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
```

## Contributing
Thanks for your interest in contributing! There are many ways to contribute to this project. Get started [here](https://github.com/StevenJDH/.github/blob/main/docs/CONTRIBUTING.md).

## Do you have any questions?
Many commonly asked questions are answered in the FAQ:
[https://github.com/StevenJDH/aws-cwl-exporter/wiki/FAQ](https://github.com/StevenJDH/aws-cwl-exporter/wiki/FAQ)

## Want to show your support?

|Method          | Address                                                                                   |
|---------------:|:------------------------------------------------------------------------------------------|
|PayPal:         | [https://www.paypal.me/stevenjdh](https://www.paypal.me/stevenjdh "Steven's Paypal Page") |
|Cryptocurrency: | [Supported options](https://github.com/StevenJDH/StevenJDH/wiki/Donate-Cryptocurrency)    |


// Steven Jenkins De Haro ("StevenJDH" on GitHub)

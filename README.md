# AWS CloudWatch Log Exporter

[![build](https://github.com/StevenJDH/aws-cwl-exporter/actions/workflows/generic-container-workflow.yml/badge.svg?branch=main)](https://github.com/StevenJDH/aws-cwl-exporter/actions/workflows/generic-container-workflow.yml)
![GitHub release (latest by date including pre-releases)](https://img.shields.io/github/v/release/StevenJDH/aws-cwl-exporter?include_prereleases)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/820cb5ee5c3a44a2bc63eecdbc55d08a)](https://www.codacy.com/gh/StevenJDH/aws-cwl-exporter/dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=StevenJDH/aws-cwl-exporter&amp;utm_campaign=Badge_Grade)
![Maintenance](https://img.shields.io/maintenance/yes/2022)
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

* [Amazon Elastic Container Registry (ECR)](https://gallery.ecr.aws/stevenjdh/aws-cwl-exporter)
* [GitHub Container Registry](https://github.com/users/StevenJDH/packages/container/package/aws-cwl-exporter)
* [Docker Hub](https://hub.docker.com/r/stevenjdh/aws-cwl-exporter)

For production use cases, it is not recommended to pull an image with the `:latest` tag, or no tag since these are equivalent.

## Helm chart
AWS CloudWatch Log Exporter can be optionally deployed to a Kubernetes cluster using the [AWS CloudWatch Log Exporter Helm Chart](https://github.com/StevenJDH/helm-charts/tree/main/charts/aws-cwl-exporter) that is managed in a separate repository. All of the features described below and more are supported by this chart.

## Usage
To run the application directly in a non-Kubernetes environment, use the approach below. Both `nerdctl` and `docker` CLIs are interchangeable here:

```bash
nerdctl run --rm --name aws-cwl-exporter \
    -e AWS_ACCESS_KEY_ID=xxxxxx \ # Not required when using roles.
    -e AWS_SECRET_ACCESS_KEY=xxxxxx \ # Not required when using roles.
    -e AWS_DEFAULT_REGION=eu-west-3  \
    -e LOG_GROUP_NAME="/aws/lambda/hello-world-dev" \
    -e S3_BUCKET_NAME=s3-example-log-exports \
    -e EXPORT_PREFIX=export-task-output \
    -e EXPORT_PERIOD=hourly \ # Not required unless set to 'daily'.
    stevenjdh/aws-cwl-exporter:latest
```

If successful, the output will look similar to the following:

```text
Creating [HOURLY][1666836000000-1666839599000] export task request...

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

## S3 Bucket resource policy
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

|Method       | Address                                                                                                    |
|------------:|:-----------------------------------------------------------------------------------------------------------|
|PayPal:      | [https://www.paypal.me/stevenjdh](https://www.paypal.me/stevenjdh "Steven's Paypal Page")                  |
|Bitcoin:     | 3GyeQvN6imXEHVcdwrZwKHLZNGdnXeDfw2                                                                         |
|Litecoin:    | MAJtR4ccdyUQtiiBpg9PwF2AZ6Xbk5ioLm                                                                         |
|Ethereum:    | 0xa62b53c1d49f9C481e20E5675fbffDab2Fcda82E                                                                 |
|Dash:        | Xw5bDL93fFNHe9FAGHV4hjoGfDpfwsqAAj                                                                         |
|Zcash:       | t1a2Kr3jFv8WksgPBcMZFwiYM8Hn5QCMAs5                                                                        |
|PIVX:        | DQq2qeny1TveZDcZFWwQVGdKchFGtzeieU                                                                         |
|Ripple:      | rLHzPsX6oXkzU2qL12kHCH8G8cnZv1rBJh<br />Destination Tag: 2357564055                                        |
|Monero:      | 4GdoN7NCTi8a5gZug7PrwZNKjvHFmKeV11L6pNJPgj5QNEHsN6eeX3D<br />&#8618;aAQFwZ1ufD4LYCZKArktt113W7QjWvQ7CWDXrwM8yCGgEdhV3Wt|


// Steven Jenkins De Haro ("StevenJDH" on GitHub)

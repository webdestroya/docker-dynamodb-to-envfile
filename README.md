
# dynamodb-to-envfile

[![](https://badge.imagelayers.io/webdestroya/dynamodb-to-envfile:latest.svg)](https://imagelayers.io/?images=webdestroya/dynamodb-to-envfile:latest 'Get your own badge on imagelayers.io')

This container can be used to easily create an environment file using key-value pairs from an [Amazon DynamoDB](http://aws.amazon.com/dynamodb/) table.

## Environment Variables

* `DYNAMODB_TABLE` **required**
  * The table that you want to pull the environment file from.
* `DYNAMODB_REGION` *(default: `us-east-1`)*
  * The region where the DynamoDB table is located.
* `KEY_ATTRIBUTE` *(default: `Variable`)*
  * The name of the attribute to use as the environment variable name
* `VALUE_ATTRIBUTE` *(default: `Value`)*
  * The name of the attribute to use as the environment variable value
* `OUTPUT_FILE` *(default: `environment`)*
  * The name of the file to write the environment variables to. This will be placed in the `/output` folder which should be mapped to your host.


The easiest way to configure permissions is by using an IAM instance role, and granting the instance running the container the ability to `Scan` the specified DynamoDB table. If that is not possible, then you can provide your credentials using the following environment variables:

* `AWS_ACCESS_KEY`
* `AWS_SECRET_KEY`

## Usage
This is best used as a `ExecStartPre` call to build an environment file that can be used with an `--env-file` parameter to another container.

```
# some-application.service
[Unit]
Description=My Application Container

[Service]
TimeoutStartSec=0
Restart=always
ExecStartPre=-/usr/bin/docker kill %p
ExecStartPre=-/usr/bin/docker rm %p

# This will write the environment file to `/etc/container_environments/%p`
ExecStartPre=/usr/bin/docker run --rm=true \
            --volume /etc/container_environments:/output \
            -e DYNAMODB_TABLE=MyAppEnvironmentVars \
            -e DYNAMODB_REGION=us-east-1 \
            -e OUTPUT_FILE=%p \
            webdestroya/dynamodb-to-envfile

ExecStartPre=/usr/bin/docker pull myapplication:latest

ExecStart=/usr/bin/docker run --name %p \
          --env-file /etc/container_environments/%p \
          myapplication \

ExecStop=/usr/bin/docker stop %p

[Install]
WantedBy=multi-user.target
```

## Roadmap

* Filtering to specific items based on criteria
* Ability to provide a 'default' environment file that is appended first

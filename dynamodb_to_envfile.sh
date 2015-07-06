#!/bin/bash

set -o pipefail

dynamo_table=${DYNAMODB_TABLE?"You must provide a table name"}
dynamo_region=${DYNAMODB_REGION-"us-east-1"}

out_file=${OUTPUT_FILE-"environment"}

access_key=${AWS_ACCESS_KEY-none}
secret_key=${AWS_SECRET_KEY-none}

if [[ $access_key != "none" && $secret_key != "none" ]]; then
  aws configure set aws_access_key_id $access_key
  aws configure set aws_secret_access_key $secret_key
else
  # Set these to prevent things from timing out
  # default is 1 for timeout and 1 for attempts
  #
  # On EC2, these should not fail, so be generous with the attempts
  aws configure set metadata_service_timeout ${EC2_METADATA_TIMEOUT-8}
  aws configure set metadata_service_num_attempts ${EC2_METADATA_ATTEMPTS-10}
fi

# Set the region
aws configure set default.region $dynamo_region

key_name=${KEY_ATTRIBUTE-Variable}
value_name=${VALUE_ATTRIBUTE-Value}

# only 25 put/delete requests per BatchWrite

echo -n > /tmp/exported_env

echo "# Exported by dynamodb-to-envfile on $(date)" > /tmp/exported_env

aws dynamodb scan --region $dynamo_region --table-name $dynamo_table --color off --output json \
  | jq --raw-output ".Items | map(.${key_name}.S + \"=\" + .${value_name}.S) | .[]" \
  >> /tmp/exported_env
retval=$?

if [[ $retval -eq 0 ]]; then
  cp /tmp/exported_env /output/$out_file
  rm -f /tmp/exported_env
  echo "Environment variables exported to '/output/$out_file'"
  exit 0
else
  echo "ERROR: Failed to create environment file"
  exit $retval
fi

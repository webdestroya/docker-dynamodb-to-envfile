#!/bin/bash

set -o pipefail

dynamo_table=${DYNAMODB_TABLE?"You must provide a table name"}

out_file=${OUTPUT_FILE-"environment"}

export AWS_DEFAULT_REGION=${DYNAMODB_REGION-"us-east-1"}

aws_access_key=${AWS_ACCESS_KEY-none}
aws_secret_key=${AWS_SECRET_KEY-none}

if [[ $aws_access_key != "none" && $aws_secret_key != "none" ]]; then
  export AWS_ACCESS_KEY_ID=$aws_access_key
  export AWS_SECRET_ACCESS_KEY=$aws_secret_key
fi

key_name=${KEY_ATTRIBUTE-Variable}
value_name=${VALUE_ATTRIBUTE-Value}

# only 25 put/delete requests per BatchWrite

echo -n > /tmp/exported_env

echo "# Exported by dynamodb-to-envfile on $(date)" > /tmp/exported_env

aws dynamodb scan --region $AWS_DEFAULT_REGION --table-name $dynamo_table --color off --output json \
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

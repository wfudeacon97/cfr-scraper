#!/bin/bash

source scripts/functions.sh

if [ -z $1 ] && [ -z $2 ] && [ -z $3 ]; then
  echo "Expects at least one param: [env PROD | TEST]"
  exit 1
fi

environment=$1

if [ "${environment}" == "test" ] || [ "${environment}" == "Test" ] || [ "${environment}" == "TEST" ]; then
  echo "Uploading to ${environment}"
  source ${connectDir}connect-test.sh
elif [ "${environment}" == "prod" ] || [ "${environment}" == "Prod" ] || [ "${environment}" == "PROD" ]; then
#  echo "Uploading to ${environment} -DISABLED"
#  exit 1
  echo "Uploading to ${environment}"
  source connect/connect-prod.sh

else
  echo "Invalid environment: ${environment}"
  exit 1
fi

TODO:  Load from Wordpress/ Mongo

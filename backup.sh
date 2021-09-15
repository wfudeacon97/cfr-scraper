#!/bin/bash

source scripts/functions.sh

environment="test"

#====================================================#
############ Parse Parameters      ###################
#====================================================#
if [ -z $1 ] ; then
  echo "Expects ONE param: ChapterList (Integer- comma-delimited). "
  exit 1
fi

chapters=$1
dt=$(date '+%Y-%m-%d')

#====================================================#
############ Load connection info  ###################
#====================================================#
if [ "${environment}" == "prod" ] ; then
  #source connect/connect-prod.sh
  echo "Not set up to run from Prod"
  exit 1
  ### For Mongo
else
  source connect/connect-test.sh
fi

#==================================================#
############ Process Supplements ###################
#==================================================#
for ch in ${chapters//,/ }; do
  getNameForChapter ${ch}
  agencyDisplayname=$(echo ${agencyName} | tr [:lower:] [:upper:])

  echo "======================================="
  echo "=====   ${agencyDisplayname} (agencyId: ${agencyId})"
  echo "======================================="

  echo "aws s3 cp s3://${bucketName}/${agencyName}/ s3://${bucketName}/${agencyName}-bkp-${dt}/ --region ${awsRegion} --recursive"
  aws s3 cp s3://${bucketName}/${agencyName}/ s3://${bucketName}/${agencyName}-bkp-${dt}/ --region ${awsRegion} --recursive

  query="db.federaldocuments.find({\"agencies.agencyId\":${agencyId}});"
  echo "query: ${query}"
  #echo "mongo $url --username=$user --password=$pswd --quiet --eval \"DBQuery.shellBatchSize = 10000; ${query}\"| tail +6"
  mongo $url --username=$user --password=$pswd --quiet --eval "DBQuery.shellBatchSize = 10000; ${query}"| tail +6 > tmp/mongo-bkp-chapter-${ch}.json
  echo "aws s3 cp tmp/mongo-bkp-chapter-${ch}.json s3://${bucketName}/${agencyName}-bkp-${dt}/ --region ${awsRegion}"
  aws s3 cp tmp/mongo-bkp-chapter-${ch}.json s3://${bucketName}/${agencyName}-bkp-${dt}/ --region ${awsRegion}
  echo "======================================="
  echo ""
done

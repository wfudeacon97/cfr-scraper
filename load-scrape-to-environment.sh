#!/bin/bash

#./load-scrape-to-environment.sh [cfr-date YYYY-MM-DD] [env PROD | TEST] [comma-delimited list of agency #'s]
source scripts/functions.sh
if [ -z $1 ] && [ -z $2 ] && [ -z $3 ]; then
  echo "Expects at least three params: [cfr-date YYYY-MM-DD], [env PROD | TEST], [comma-delimited list of agency #'s]"
  exit 1
fi

cfrDate=$1
environment=$2
chapters=$3

if [ "${environment}" == "test" ] || [ "${environment}" == "Test" ] || [ "${environment}" == "TEST" ]; then
  echo "Uploading to ${environment}"
  source connect/connect-test.sh
elif [ "${environment}" == "prod" ] || [ "${environment}" == "Prod" ] || [ "${environment}" == "PROD" ]; then
  echo "Uploading to ${environment} -DISABLED"
  exit 1
#  source connect/connect-prod.sh
else
  echo "Invalid environment: ${environment}"
  exit 1
fi

#====================================================#
############ Reset to scrape from s3  ################
#====================================================#
./reload-scrape.sh ${cfrDate}
result=$?
if [ "$result" != "0" ] ; then
  exit 1
fi

if [ -f tmp/chapters.meta ]; then
  scrapeChapters=$(cat tmp/chapters.meta)
else
  echo "tmp/chapters.meta does not exist... there is no scrape to re-load"
  exit 1
fi

#=================================================#
############ Upload Supplements ###################
#=================================================#
for ch in ${chapters//,/ }; do
  upload=N
  ## Check that the scrapes chapter is in the list to load
  for scrapeCh in ${scrapeChapters//,/ }; do
    if [ "${ch}" == "${scrapeCh}" ] ; then
      upload=Y
    fi
  done
  getNameForChapter ${ch}
  if [ "${ch}" != "1" ] && [ "${upload}" == "Y" ]; then
    echo " - Upload mongo records for ${agencyName}"
    mongo $url --username=$user --password=$pswd --quiet --eval "DBQuery.shellBatchSize = 10000; db.federaldocuments.deleteMany({\"agencies.agencyId\" : ${agencyId}})" | tail +6
    mongoimport -u $user  -p $pswd -d ${dbName} -c ${collectionName} --uri ${url} < results/mongo-chapter-${ch}.json

    # Remove old html for that directory in S3
    echo "- Remove old html for ${agencyName}"
    echo "aws s3 rm s3://${bucketName}/${agencyName}/ --region ${awsRegion}"
    aws s3 rm s3://${bucketName}/${agencyName}/ --region ${awsRegion}

    #Upload new S3 files
    echo "- Upload html to s3://${bucketName}/${agencyName}/ for ${agencyName}"
    echo "aws s3 sync html/${agencyName}/ s3://${bucketName}/${agencyName}/ --region ${awsRegion}"
    aws s3 sync html/${agencyName}/ s3://${bucketName}/${agencyName}/ --region ${awsRegion}
  else
    echo " - Skipping upload of chapter: ${ch} (${agencyName}) because it was not included in upload list ${chapters}"
  fi
done

#==========================================#
############ Upload FAR ###################
#==========================================#
#TOOD:  Finish the mongo.json for the FAR and upload to Mongo
for ch in ${chapters//,/ }; do
  upload=N
  ## Check that the scrapes chapter is in the list to load
  for scrapeCh in ${scrapeChapters//,/ }; do
    if [ "${ch}" == "${scrapeCh}" ] ; then
      upload=Y
    fi
  done
  getNameForChapter ${ch}
  if [ "${ch}" == "1" ] ; then
    if [ "${upload}" == "Y" ] ; then
      echo "======================================="
      echo "=====   Upload FAR (agencyId: ${agencyId})"
      echo "======================================="
      echo " - TODO: Finish upload of FAR artifacts"
      echo "======================================="
    else
      echo " - Skipping upload of chapter: ${ch} (${agencyName}) because it was not included in upload list ${chapters}"
    fi
  fi
done

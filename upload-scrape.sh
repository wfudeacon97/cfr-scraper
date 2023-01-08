#!/bin/bash

DATE=$(date -u +'%FT%TZ')
awsRegion=us-east-2
bucketName=cfr-scraper
source scripts/functions.sh
files=N

if [ -f ${resultsDir}cfr-date.meta ]; then
  cfrDate=$(cat ${resultsDir}cfr-date.meta)
else
  echo "${resultsDir}cfr-date.meta does not exist... there is no scrape to upload"
  exit 1
fi
#chapters=$(cat ${resultsDir}chapters.meta)
echo "Available chapters are: ${chapters}"
for i in $(ls  -d results/*/); do echo "${i/results\//}" ; done

#TODO:  Do we want to prevent this if there is a previous scrape with the same cfr-date?
aws s3 rm s3://${bucketName}/${cfrDate}/ --recursive --region ${awsRegion}
aws s3 sync ${resultsDir} s3://${bucketName}/${cfrDate}/ --region ${awsRegion} --exclude "*" --include "*.meta" --include "*.xml"

for i in $(ls  -d results/*/); do
  agencyDir=${i/results\//}
  agencyName=${agencyDir/\//}
#for ch in ${chapters//,/ }; do

  supplResultsDir=${resultsDir}${agencyDir}/
  files=Y
  echo "======================================="
  echo "=====   Uploading: $i"
  echo "======================================="
  #Tar up the file
  tar -zcf ${tmpDir}${agencyName}-${cfrDate}.tar.gz ${supplResultsDir}
  status=$?
  if [ "$status" == "0" ]; then
    aws s3 rm s3://${bucketName}/${cfrDate}/${agencyDir} --region ${awsRegion}

    echo "aws s3 cp ${tmpDir}${agencyName}-${cfrDate}.tar.gz s3://${bucketName}/${cfrDate}/${agencyDir} --region ${awsRegion}"
    aws s3 cp ${tmpDir}${agencyName}-${cfrDate}.tar.gz s3://${bucketName}/${cfrDate}/${agencyDir} --region ${awsRegion}
  else
    echo "Failed to tar result files for ${agencyName}"
  fi
done

if [ "${files}" == "Y" ] ; then
  tar -zcf ${tmpDir}raw-${cfrDate}.tar.gz ${tmpDir}raw-${cfrDate}.xml
  status=$?
  if [ "$status" == "0" ]; then
    aws s3 cp ${tmpDir}raw-${cfrDate}.tar.gz s3://${bucketName}/${cfrDate}/ --region ${awsRegion}
  else
    echo "Failed to tar raw XML file"
  fi
fi

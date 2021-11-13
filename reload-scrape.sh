#!/bin/bash

if [ -z $1 ] ; then
  echo "Expects at least one param: cfr-date (Date YYYY-MM-DD)"
  exit 1
fi

cfrDate=$1
awsRegion=us-east-2
bucketName=cfr-scraper
source scripts/functions.sh
echo "Reloading scrape from  ${cfrDate}"

./reset.sh

aws s3 sync  s3://${bucketName}/${cfrDate}/far/ ${resultsDir} --region ${awsRegion} --exclude "*" --include "*.meta"

for dir in $(aws s3 ls s3://${bucketName}/${cfrDate}/ --recursive --human-readable --summarize | awk '{print $5}' | grep -v meta | grep -v "raw-${cfrDate}.tar.gz"); do

  fullFile=${dir/${cfrDate}\//}
  agencyName=$(cut -d'/' -f1 <<< "$fullFile")

  echo "======================================="
  echo "=====   ${agencyName}"
  echo "======================================="
  echo "Processing directory: ${dir}"
  aws s3 cp s3://${bucketName}/${cfrDate}/${agencyName}/${agencyName}-${cfrDate}.tar.gz ${tmpDir}${agencyName}-${cfrDate}.tar.gz  --region ${awsRegion}

  tar -zxf ${tmpDir}${agencyName}-${cfrDate}.tar.gz -C .

done

aws s3 cp s3://${bucketName}/${cfrDate}/raw-${cfrDate}.tar.gz ${tmpDir}raw-${cfrDate}.tar.gz  --region ${awsRegion}
tar -zxf ${tmpDir}raw-${cfrDate}.tar.gz -C .
rm -f ${tmpDir}*.tar.gz

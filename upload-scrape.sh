#!/bin/bash

DATE=$(date -u +'%FT%TZ')
awsRegion=us-east-2
bucketName=cfr-scraper
source scripts/functions.sh
files=N

if [ -f tmp/cfr-date.meta ]; then
  cfrDate=$(cat tmp/cfr-date.meta)
else
  echo "tmp/cfr-date.meta does not exist... there is no scrape to upload"
  exit 1
fi
chapters=$(cat tmp/chapters.meta)

#TODO:  Do we want to prevent this if there is a previous scrape with the same cfr-date?
aws s3 rm s3://${bucketName}/${cfrDate}/ --region ${awsRegion}

for ch in ${chapters//,/ }; do
  getNameForChapter ${ch}
  files=Y
  if [ "${ch}" == "1" ] ; then
    echo "======================================="
    echo "=====   FAR"
    echo "======================================="
    aws s3 cp results/mongo-chapter-1.json s3://${bucketName}/${cfrDate}/far/mongo-chapter-1.json --region ${awsRegion}
    aws s3 cp results/elastic-chapter-1.json s3://${bucketName}/${cfrDate}/far/elastic-chapter-1.json  --region ${awsRegion}
    aws s3 cp results/scrape-1.json s3://${bucketName}/${cfrDate}/far/scrape-1.json  --region ${awsRegion}
    aws s3 sync html/far/ s3://${bucketName}/${cfrDate}/far/html/ --region ${awsRegion} --exclude "*" --include "*.html"
    #TODO: Upload Elastic json as well

  else
    echo "======================================="
    echo "=====   Supplement: ${agencyName} "
    echo "======================================="
    aws s3 cp results/mongo-chapter-${ch}.json s3://${bucketName}/${cfrDate}/${agencyName}/mongo-chapter-${ch}.json --region ${awsRegion}
    aws s3 cp results/scrape-${ch}.json s3://${bucketName}/${cfrDate}/${agencyName}/scrape-${ch}.json  --region ${awsRegion}
    aws s3 sync html/${agencyName}/ s3://${bucketName}/${cfrDate}/${agencyName}/html/ --region ${awsRegion} --exclude "*" --include "*.html"
  fi
done

if [ "${files}" == "Y" ] ; then
  aws s3 sync tmp/ s3://${bucketName}/${cfrDate} --region ${awsRegion} --exclude "*" --include "*.meta"
  aws s3 cp tmp/raw-${cfrDate}.xml s3://${bucketName}/${cfrDate}/raw-${cfrDate}.xml --region ${awsRegion}
fi

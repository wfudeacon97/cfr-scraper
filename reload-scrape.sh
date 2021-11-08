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

aws s3 sync  s3://${bucketName}/${cfrDate} tmp/ --region ${awsRegion} --exclude "*" --include "*.meta"

if [ -f tmp/chapters.meta ]; then
  chapters=$(cat tmp/chapters.meta)
else
  echo "tmp/chapters.meta does not exist... there is no scrape to re-load"
  exit 1
fi

for ch in ${chapters//,/ }; do
  getNameForChapter ${ch}
  files=Y
  if [ "${ch}" == "1" ] ; then
    echo "======================================="
    echo "=====   FAR"
    echo "======================================="
    aws s3 cp s3://${bucketName}/${cfrDate}/far/mongo-chapter-1.json results/mongo-chapter-1.json  --region ${awsRegion}
    aws s3 cp s3://${bucketName}/${cfrDate}/far/elastic-chapter-1.json results/elastic-chapter-1.json  --region ${awsRegion}
    aws s3 cp s3://${bucketName}/${cfrDate}/far/scrape-1.json results/scrape-1.json --region ${awsRegion}
    aws s3 sync s3://${bucketName}/${cfrDate}/far/html/ html/far/  --region ${awsRegion} --exclude "*" --include "*.html" --quiet

  else
    echo "======================================="
    echo "=====   Supplement: ${agencyName} "
    echo "======================================="
    aws s3 cp s3://${bucketName}/${cfrDate}/${agencyName}/mongo-chapter-${ch}.json results/mongo-chapter-${ch}.json  --region ${awsRegion}
    aws s3 cp s3://${bucketName}/${cfrDate}/${agencyName}/scrape-${ch}.json results/scrape-${ch}.json --region ${awsRegion}
    aws s3 sync s3://${bucketName}/${cfrDate}/${agencyName}/html/ html/${agencyName}/  --region ${awsRegion} --exclude "*" --include "*.html"  --quiet
  fi
done

if [ "${files}" == "Y" ] ; then
  aws s3 cp s3://${bucketName}/${cfrDate}/raw-${cfrDate}.xml tmp/raw-${cfrDate}.xml  --region ${awsRegion}
fi

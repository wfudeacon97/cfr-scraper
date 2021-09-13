#!/bin/bash

source functions.sh
if [ -z $1 ] ; then
  echo "Expects at least one param: ChapterList (Integer- comma-delimited).  Second Param (Date YYYY-MM-DD) is optional"
  echo "NOTE: you do NOT need to include Chapter 1 (FAR) in the chapter list- it will automatically be included"
  exit 1
fi

#Used in generating the Mongo Records
DATE=$(date -u +'%FT%TZ')

environment="test"
if [ "${environment}" == "test" ] ; then
  ### For Mongo
  url="mongodb+srv://far-db-cluster-vsvtb.mongodb.net/test"
  user="testing"
  pswd="2MuchT3sti1ng"
  dbName="test"
  collectionName="federaldocuments"
  #indexName="fartestindex"

  ### For HTML Files
  bucketName="test.openthefar.com"
  awsRegion="us-east-2"
fi

includeFAR=N
upload=Y
chapters=$1
if [ -z $2 ] ; then
  dt=$(date '+%Y-%m-%d')
else
  dt=$2
fi
echo "Processing thru date $dt"

## Clean up from prior Run
rm -rf html/*
rm -rf tmp/*.json
rm -rf results/*

mkdir -p tmp
mkdir -p results
mkdir -p html/far

########---- if necessary, download raw file for all xml from ecfr website-----##########
if [ -f tmp/raw-${dt}.xml ]; then
  echo "Skipping download because tmp/raw-${dt}.xml already exists"
else
  #https://www.ecfr.gov/api/versioner/v1/full/2021-09-11/title-48.xml
  curl -X GET "https://www.ecfr.gov/api/versioner/v1/full/${dt}/title-48.xml" -H "accept: application/xml" > tmp/raw-${dt}.xml
#  https://www.ecfr.gov
#  curl -X GET "https://ecfr.federalregister.gov/api/versioner/v1/full/${dt}/title-48.xml" -H "accept: application/xml" > tmp/raw-${dt}.xml
fi

#==========================================#
############ Process FAR ###################
#==========================================#
if [ "${includeFAR}" == "Y" ] ; then
  ########---- decompose raw file into chapter specific json -----##########
  # Uses a sax parser to generate tmp/raw-title-${chapter}.json
  echo "====== Generate json for Mongo/ Elastic for FAR"
  ./gen-rawjson-py.sh tmp/raw-${dt}.xml 1

  echo "   - Chapters: $(cat tmp/raw-subchapter-1.json | jq . -c | wc -l)"
  echo "   - Subparts: $(cat tmp/raw-subpart-1.json | jq . -c | wc -l)"
  echo "   - Section: $(cat tmp/raw-section-1.json | jq . -c | wc -l)"

  agencyId=539
  ### Clean up JSON for uploading to Mongo
  cat tmp/raw-subpart-1.json |
    jq --argjson json "`<agencies/agency-${agencyId}.json`" '. + {agencies: $json}' |\
    jq --arg DATE "$DATE"  '.createdAt += {"$date": $DATE}' | \
    jq --arg DATE "$DATE"  '.updatedAt += {"$date": $DATE}' -c |
    jq 'del(.content )' | \
    jq '. + {content: ""}' -c  \
    > results/mongo-chapter-1.json

  echo "   - Total: $(cat results/mongo-chapter-1.json | jq . -c | wc -l)"

  ########---- decompose raw file into different html files for FAR-----##########
  echo "====== Generate html for FAR"
  ./gen-far-subpart-html-py.sh tmp/raw-${dt}.xml html/far 1
  ./gen-far-part-html-py.sh tmp/raw-${dt}.xml html/far 1
else
  echo "Skipping FAR because 'includeFar' is ${includeFAR}"
fi

#==================================================#
############ Process Supplements ###################
#==================================================#
for ch in ${chapters//,/ }; do
  # This assigns the "agencyName" variable
  getNameForChapter ${ch}
  agencyDisplayname=$(echo ${agencyName} | tr [:lower:] [:upper:])

  echo "====== Generate json for Mongo/ Elastic for ${agencyDisplayname}: _id: " + ${agencyId}
  ./gen-rawjson-py.sh tmp/raw-${dt}.xml ${ch}

  echo "   - Chapters: $(cat tmp/raw-subchapter-${ch}.json | jq . -c | wc -l)"
  echo "   - Subparts: $(cat tmp/raw-subpart-${ch}.json | jq . -c | wc -l)"
  echo "   - Section: $(cat tmp/raw-section-${ch}.json | jq . -c | wc -l)"

  ### Clean up JSON for uploading to Mongo
  cat tmp/raw-subchapter-${ch}.json |
    jq --argjson json "`<agencies/agency-${agencyId}.json`" '. + {agencies: $json}' |\
    jq --arg DATE "$DATE"  '.createdAt += {"$date": $DATE}' | \
    jq --arg DATE "$DATE"  '.updatedAt += {"$date": $DATE}' -c |
    jq 'del(.content )' | \
    jq '. + {content: ""}' -c  \
    > results/mongo-chapter-${ch}.json

  ### Clean up JSON for uploading to Mongo
  cat tmp/raw-subpart-${ch}.json |
    jq --argjson json "`<agencies/agency-${agencyId}.json`" '. + {agencies: $json}' |\
    jq --arg DATE "$DATE"  '.createdAt += {"$date": $DATE}' | \
    jq --arg DATE "$DATE"  '.updatedAt += {"$date": $DATE}' -c |
    jq 'del(.content )' | \
    jq '. + {content: ""}' -c  \
    >> results/mongo-chapter-${ch}.json

  ### Clean up JSON for uploading to Mongo
  cat tmp/raw-section-${ch}.json |
    jq --argjson json "`<agencies/agency-${agencyId}.json`" '. + {agencies: $json}' |\
    jq --arg DATE "$DATE"  '.createdAt += {"$date": $DATE}' | \
    jq --arg DATE "$DATE"  '.updatedAt += {"$date": $DATE}' -c |
    jq 'del(.content )' | \
    jq '. + {content: ""}' -c  \
    >> results/mongo-chapter-${ch}.json

  echo "   - Total: $(cat results/mongo-chapter-${ch}.json | jq . -c | wc -l)"

  echo "====== Generate html for ${agencyDisplayname}"
  mkdir -p html/${agencyName}
  echo "-Top"
  ./gen-supplement-part-html-top-py.sh tmp/raw-${dt}.xml  html/${agencyName} ${ch}
  echo "-Bottom"
  ./gen-supplement-part-html-bottom-py.sh tmp/raw-${dt}.xml  html/${agencyName} ${ch}

  ## Perform th uploads to Mongo/ S3 if 'upload' == Y
  if [ "${upload}" == "Y" ] ; then
    mongo $url --username=$user --password=$pswd --quiet --eval "DBQuery.shellBatchSize = 10000; db.federaldocuments.deleteMany({\"agencies.agencyId\" : ${agencyId}})" | tail +6
    mongoimport -u $user  -p $pswd -d ${dbName} -c ${collectionName} --uri ${url} < results/mongo-chapter-${ch}.json

    # Remove old html for that directory in S3
    echo "aws s3 rm s3://${bucketName}/${agencyName}/ --region ${awsRegion}"
    aws s3 rm s3://${bucketName}/${agencyName}/ --region ${awsRegion}

    #Upload new S3 files
    echo "aws s3 sync html/${agencyName}/ s3://${bucketName}/${agencyName}/ --region ${awsRegion}"
    aws s3 sync html/${agencyName}/ s3://${bucketName}/${agencyName}/ --region ${awsRegion}
  else
    echo "Skipping upload of ${agencyName} because 'upload' is ${upload}"
  fi
done

#==========================================#
############ Upload FAR ###################
#==========================================#
#TOOD:  Finish the mongo.json for the FAR and upload to Mongo
if [ "${upload}" == "Y" ] ; then
    echo "TODO: Finish upload of FAR artifacts"
else
  echo "Skipping upload of FAR because 'upload' is ${upload}"
fi

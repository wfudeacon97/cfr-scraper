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
#Used in generating the Mongo Records
DATE=$(date -u +'%FT%TZ')

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
    #==================================================#
    ### Remove and reinsert  Mongo records
    ### - Uses:
    ###      - results/mongo-chapter-${ch}.json
    #==================================================#
    echo " - Upload mongo records for ${agencyName}"
    mongo $url --username=$user --password=$pswd --quiet --eval "DBQuery.shellBatchSize = 10000; db.federaldocuments.deleteMany({\"agencies.agencyId\" : ${agencyId}})" | tail +6
    mongoimport -u $user  -p $pswd -d ${dbName} -c ${collectionName} --uri ${url} < results/mongo-chapter-${ch}.json

    cat results/scrape-${ch}.json | jq --arg DATE "$DATE"  '.uploadedAt += {"$date": $DATE}' -c > tmp/scrape-${ch}.json
    mongoimport -u $user  -p $pswd -d ${dbName} -c ${scraperCollectionName} --uri ${url} < tmp/scrape-${ch}.json

    #==================================================#
    ### Remove old html records
    #==================================================#
    echo "- Remove old html for ${agencyName}"
    echo "aws s3 rm s3://${bucketName}/${agencyName}/ --region ${awsRegion}"
    aws s3 rm s3://${bucketName}/${agencyName}/ --region ${awsRegion}

    #==================================================#
    ### Upload new html records
    #==================================================#
    echo "- Upload html to s3://${bucketName}/${agencyName}/ for ${agencyName}"
    echo "aws s3 sync html/${agencyName}/ s3://${bucketName}/${agencyName}/ --region ${awsRegion}"
    aws s3 sync html/${agencyName}/ s3://${bucketName}/${agencyName}/ --region ${awsRegion} --quiet
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
      #==================================================#
      ### Remove and reinsert  Mongo records
      ### - Uses:
      ###      - results/mongo-chapter-${ch}.json
      #==================================================#
      echo " - Upload mongo records for ${agencyName}"
      mongo $url --username=$user --password=$pswd --quiet --eval "DBQuery.shellBatchSize = 10000; db.federaldocuments.deleteMany({\"agencies.agencyId\" : ${agencyId}})" | tail +6
      mongoimport -u $user  -p $pswd -d ${dbName} -c ${collectionName} --uri ${url} < results/mongo-chapter-${ch}.json

      cat results/scrape-${ch}.json | jq --arg DATE "$DATE"  '.uploadedAt += {"$date": $DATE}' -c > tmp/scrape-${ch}.json
      mongoimport -u $user  -p $pswd -d ${dbName} -c ${scraperCollectionName} --uri ${url} < tmp/scrape-${ch}.json

      #==================================================#
      ### Remove old html records
      #==================================================#
      echo "- Remove old html for ${agencyName}"
      echo "aws s3 rm s3://${bucketName}/${agencyName}/ --region ${awsRegion}"
      aws s3 rm s3://${bucketName}/${agencyName}/ --region ${awsRegion}

      #==================================================#
      ### Upload new html records
      #==================================================#
      echo "- Upload html to s3://${bucketName}/${agencyName}/ for ${agencyName}"
      echo "aws s3 sync html/${agencyName}/ s3://${bucketName}/${agencyName}/ --region ${awsRegion}"
      aws s3 sync html/${agencyName}/ s3://${bucketName}/${agencyName}/ --region ${awsRegion} --quiet

      #==================================================#
      ### Upload Elastic
      ### - Uses:
      ###      - results/elastic-chapter-${ch}.json
      #==================================================#
      if [ "${indexName}" != "" ] && [ -f results/elastic-chapter-${ch}.json ]; then

          echo "- indexName=${indexName}"
          #==================================================#
          ### Delete prior Elastic indexed docments
          #==================================================#
          echo "- Remove old indexed documents from Elastic for ${agencyName}"
          curl -s -XPOST "https://search-far-elasticsearch-xqucmrm5ng7d43q55be2rk7hm4.us-east-2.es.amazonaws.com/${indexName}/_delete_by_query?conflicts=proceed&pretty" -H 'Content-Type: application/json' -d'{ "query": { "match_all": {} } }'

          # Confirm 0 indexed docments
          curl -s https://search-far-elasticsearch-xqucmrm5ng7d43q55be2rk7hm4.us-east-2.es.amazonaws.com:443/${indexName}/_stats?pretty | jq '._all.primaries.docs'

          #==================================================#
          ### Upload new Elastic indexed docments
          #==================================================#
          echo "- Upload new indexed documents from Elastic for ${agencyName} to index ${indexName}"
          idx=0
          while read j; do
            idx=$((idx+1))

            request=$(echo $j | jq 'del(._id)' -c)
            id=$(echo $j | jq '"\(._id)"' -r)
            output=$(curl -s -X PUT  https://search-far-elasticsearch-xqucmrm5ng7d43q55be2rk7hm4.us-east-2.es.amazonaws.com:443/${indexName}/_doc/${id} -H 'Content-Type: application/json' -d "$request")
            status=$?

            if [ "$status" != "0" ] ; then
              echo "Problem on line: ${idx}: ${id}"
            fi
          done < <(cat results/elastic-chapter-${ch}.json | jq '.' -c  )

          echo "Completed Sending to Elastic: $(date)"

          #==================================================#
          ### Confirm Indexed Documents prior Elastic indexed docments
          #==================================================#
          echo "- Total documents indexed: $(curl -s https://search-far-elasticsearch-xqucmrm5ng7d43q55be2rk7hm4.us-east-2.es.amazonaws.com:443/${indexName}/_stats?pretty | jq '._all.primaries.docs')"
      else
        echo "load-scrape-to-environment.sh-... skipping Elastic Upload"
      fi

      echo "======================================="
    else
      echo " - Skipping upload of chapter: ${ch} (${agencyName}) because it was not included in upload list ${chapters}"
    fi
  fi
done

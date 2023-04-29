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
UPLOAD_DATE=$(date -u +'%FT%TZ')

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

#====================================================#
############ Reset to scrape from s3  ################
#====================================================#
echo "########################################"
echo "-- Reloading Scrape Data from S3"
echo "########################################"
./reload-scrape.sh ${cfrDate}
result=$?
if [ "$result" != "0" ] ; then
  exit 1
fi

#=================================================#
############ Upload Supplements ###################
#=================================================#
echo ""
echo "########################################"
echo "-- Uploading Data for Supplements"
echo "########################################"
for ch in ${chapters//,/ }; do
  upload=N
  getNameForChapter ${ch}
  ## Check that the scrapes chapter is in the list to load
  if [ -d ${resultsDir}${agencyName} ]; then
      upload=Y
  else
    echo "No scrape exists for chapter ${ch}: ${agencyName}"
  fi
  supplResultsDir=${resultsDir}${agencyName}/
  if [ "${ch}" != "1" ] && [ "${upload}" == "Y" ]; then

    #==================================================#
    ### Remove and reinsert Agency Mongo records
    ### - Uses:
    ###      - results/vaar/mongo-chapter-${ch}.json
    #==================================================#
    echo " - Refresh agency record for ${agencyName}"
    cat ${supplResultsDir}agency-chapter-${ch}.json | jq '.[]' -c |\
      jq --arg DATE "$UPLOAD_DATE"  '.updatedAt += {"$date": $DATE}' -c \
      > ${supplResultsDir}/mongo-agency-chapter-${ch}.json

    mongo $url --username=$user --password=$pswd --quiet --eval "DBQuery.shellBatchSize = 10000; db.${agencyCollectionName}.deleteMany({\"agencyId\" : ${agencyId}})" | tail +6
    mongoimport -u $user  -p $pswd -d ${dbName} -c ${agencyCollectionName} --uri ${url} < ${supplResultsDir}/mongo-agency-chapter-${ch}.json

    #==================================================#
    ### Remove and reinsert  Mongo records
    ### - Uses:
    ###      - results/vaar/mongo-chapter-${ch}.json
    #==================================================#
    echo " - Update mongo records with dates/ agency for ${agencyName}"
    # Add the createdDate/ uploadDate/ Agencies to the json for Mongo
    CREATED_DATE=$(cat ${supplResultsDir}created-date.meta)
    cat ${supplResultsDir}mongo-chapter-${ch}.json |\
      jq --argjson json "`<${supplResultsDir}/agency-chapter-${ch}-doc.json`" '. + {agencies: $json}' |\
      jq --arg DATE "$CREATED_DATE"  '.createdAt += {"$date": $DATE}' | \
      jq --arg DATE "$UPLOAD_DATE"  '.updatedAt += {"$date": $DATE}' -c \
      > ${supplResultsDir}/mongo-federaldocuments-chapter-${ch}.json

    echo " - Upload mongo records for ${agencyName}"
    mongo $url --username=$user --password=$pswd --quiet --eval "DBQuery.shellBatchSize = 10000; db.${collectionName}.deleteMany({\"agencies.agencyId\" : ${agencyId}})" | tail +6
    mongoimport -u $user  -p $pswd -d ${dbName} -c ${collectionName} --uri ${url} < ${supplResultsDir}/mongo-federaldocuments-chapter-${ch}.json

    cat ${supplResultsDir}scrape-${ch}.json | jq --arg DATE "$UPLOAD_DATE"  '.uploadedAt += {"$date": $DATE}' -c > ${supplResultsDir}mongo-scrape-${ch}.json
    mongoimport -u $user  -p $pswd -d ${dbName} -c ${scraperCollectionName} --uri ${url} < ${supplResultsDir}mongo-scrape-${ch}.json

    #==================================================#
    ### Google Ad tracker -> Html for Production environment
    #==================================================#
    if [ "${environment}" == "prod" ] || [ "${environment}" == "Prod" ] || [ "${environment}" == "PROD" ]; then
      echo "Production: Adding Google Ad tracker to html"

      sed -i '' -e '/<!-- GOOGLE-ADD -->/r connect/googleads.txt' ${supplResultsDir}html/*.html

    else
      echo "${environment}: Skipping Google Ad tracker "
    fi
    #==================================================#
    ### Google ADSENSE -> Html for Production environment
    #==================================================#
    if [ "$enableAdSenseSuppl" == "Y" ]; then
      if [ "${environment}" == "prod" ] || [ "${environment}" == "Prod" ] || [ "${environment}" == "PROD" ]; then
        echo "Production: Adding Google AdSense to html"

        sed -i '' -e '/<!-- AD_SENSE -->/r connect/ad-sense.txt' ${supplResultsDir}html/*.html

      else
        echo "${environment}: Skipping Google AdSense "
      fi
    else
      echo "${environment}: Skipping Google AdSense (enableAdSenseSuppl disabled in scripts/functions.sh)"
    fi

    #==================================================#
    ### Remove old html records
    #==================================================#
    echo "- Remove old html for ${agencyName}"
    echo "aws s3 rm s3://${bucketName}/${agencyName}/ --recursive  --region ${awsRegion}"
    aws s3 rm s3://${bucketName}/${agencyName}/ --recursive --region ${awsRegion}

    #==================================================#
    ### Upload new html records
    #==================================================#
    echo "- Upload html to s3://${bucketName}/${agencyName}/ for ${agencyName}"
    echo "aws s3 sync ${supplResultsDir}html/ s3://${bucketName}/${agencyName}/ --region ${awsRegion}"
    aws s3 sync ${supplResultsDir}html/ s3://${bucketName}/${agencyName}/ --region ${awsRegion} --quiet
  else
    echo " - Skipping upload of chapter: ${ch} (${agencyName}) because it was not included in upload list ${chapters}"
  fi
done

#==========================================#
############ Upload FAR ###################
#==========================================#
echo ""
echo "########################################"
echo "-- Uploading FAR Data"
echo "########################################"
for ch in ${chapters//,/ }; do
  upload=N
  getNameForChapter ${ch}
  ## Check that the scrapes chapter is in the list to load
  if [ -d ${resultsDir}${agencyName} ]; then
      upload=Y
  else
    echo "No scrape exists for chapter ${ch}: ${agencyName}"
  fi

  if [ "${ch}" == "1" ] ; then
    farResultsDir=${resultsDir}${agencyName}/
    if [ "${upload}" == "Y" ] ; then
      echo "======================================="
      echo "=====   Upload FAR (agencyId: ${agencyId})"
      echo "======================================="

      #==================================================#
      ### Remove and reinsert Agency Mongo records
      ### - Uses:
      ###      - results/vaar/mongo-chapter-${ch}.json
      #==================================================#
      echo " - Refresh agency record for ${agencyName}"
      cat ${farResultsDir}agency-chapter-${ch}.json | jq '.[]' -c |\
        jq --arg DATE "$UPLOAD_DATE"  '.updatedAt += {"$date": $DATE}' -c \
        > ${farResultsDir}/mongo-agency-chapter-${ch}.json

      mongo $url --username=$user --password=$pswd --quiet --eval "DBQuery.shellBatchSize = 10000; db.${agencyCollectionName}.deleteMany({\"agencyId\" : ${agencyId}})" | tail +6
      mongoimport -u $user  -p $pswd -d ${dbName} -c ${agencyCollectionName} --uri ${url} < ${farResultsDir}/mongo-agency-chapter-${ch}.json

      #==================================================#
      ### Remove and reinsert  Mongo records
      ### - Uses:
      ###      - ${farResultsDir}mongo-chapter-${ch}.json
      #==================================================#
      echo " - Update mongo records with dates/ agency for ${agencyName}"
      # Add the createdDate/ uploadDate/ Agencies to the json for Mongo
      CREATED_DATE=$(cat ${farResultsDir}created-date.meta)
      cat ${farResultsDir}mongo-chapter-${ch}.json |\
        jq --argjson json "`<${farResultsDir}/agency-chapter-${ch}-doc.json`" '. + {agencies: $json}' |\
        jq --arg DATE "$CREATED_DATE"  '.createdAt += {"$date": $DATE}' | \
        jq --arg DATE "$UPLOAD_DATE"  '.updatedAt += {"$date": $DATE}' -c \
        > ${farResultsDir}/mongo-federaldocuments-chapter-${ch}.json

      echo " - Upload mongo records for ${agencyName}"
      mongo $url --username=$user --password=$pswd --quiet --eval "DBQuery.shellBatchSize = 10000; db.${collectionName}.deleteMany({\"agencies.agencyId\" : ${agencyId}})" | tail +6
      mongoimport -u $user  -p $pswd -d ${dbName} -c ${collectionName} --uri ${url} < ${farResultsDir}/mongo-federaldocuments-chapter-${ch}.json

      cat ${farResultsDir}scrape-${ch}.json | jq --arg DATE "$UPLOAD_DATE"  '.uploadedAt += {"$date": $DATE}' -c > ${farResultsDir}mongo-scrape-${ch}.json
      mongoimport -u $user  -p $pswd -d ${dbName} -c ${scraperCollectionName} --uri ${url} < ${farResultsDir}mongo-scrape-${ch}.json

      #==================================================#
      ### Google Ad tracker -> Html for Production environment
      #==================================================#
      if [ "${environment}" == "prod" ] || [ "${environment}" == "Prod" ] || [ "${environment}" == "PROD" ]; then
        echo "Production: Adding Google Ad tracker to html"

        sed -i '' -e '/<!-- GOOGLE-ADD -->/r connect/googleads.txt' ${farResultsDir}html/*.html

      else
        echo "${environment}: Skipping Google Ad tracker "
      fi

      #==================================================#
      ### Google ADSENSE -> Html for Production environment
      #==================================================#
      if [ "$enableAdSense" == "Y" ]; then
        if [ "${environment}" == "prod" ] || [ "${environment}" == "Prod" ] || [ "${environment}" == "PROD" ]; then
          echo "Production: Adding Google AdSense to html"

          sed -i '' -e '/<!-- AD_SENSE -->/r connect/ad-sense.txt' ${farResultsDir}html/*.html

        else
          echo "${environment}: Skipping Google AdSense "
        fi
      else
        echo "${environment}: Skipping Google AdSense (enableAdSense disabled in scripts/functions.sh)"
      fi

      #==================================================#
      ### Remove old html records
      #==================================================#
      echo "- Remove old html for ${agencyName}"
      echo "aws s3 rm s3://${bucketName}/${agencyName}/  --recursive --region ${awsRegion}"
      aws s3 rm s3://${bucketName}/${agencyName}/ --recursive --region ${awsRegion}

      #==================================================#
      ### Upload new html records
      #==================================================#
      echo "- Upload html to s3://${bucketName}/${agencyName}/ for ${agencyName}"
      echo "aws s3 sync ${farResultsDir}html/ s3://${bucketName}/${agencyName}/ --region ${awsRegion}"
      aws s3 sync ${farResultsDir}html/ s3://${bucketName}/${agencyName}/ --region ${awsRegion} --quiet

      #==================================================#
      ### Add Blog entries to Sitemap
      #==================================================#
      ## TODO: Update this from Wordpress
      sed -i  -e "s/<\/urlset>//g" ${resultsDir}/sitemap.xml
      echo "<url><loc>https://blog.openthefar.com/simplified-acquisition-procedures-for-government-contracting/</loc><lastmod>2023-01-01</lastmod><changefreq>monthly</changefreq><priority>1.0</priority></url>" >> ${resultsDir}/sitemap.xml
      echo "<url><loc>https://blog.openthefar.com/the-mission-of-the-department-of-veterans-affairs-and-what-the-future-holds/</loc><lastmod>2023-01-01</lastmod><changefreq>monthly</changefreq><priority>1.0</priority></url>" >> ${resultsDir}/sitemap.xml
      echo "<url><loc>https://blog.openthefar.com/federal-acquisition-regulations-on-business-practices-and-conflicts-of-interest-part-2/</loc><lastmod>2023-01-01</lastmod><changefreq>monthly</changefreq><priority>1.0</priority></url>" >> ${resultsDir}/sitemap.xml
      echo "<url><loc>https://blog.openthefar.com/federal-acquisition-regulations-on-business-practices-and-conflicts-of-interest-part-1/</loc><lastmod>2023-01-01</lastmod><changefreq>monthly</changefreq><priority>1.0</priority></url>" >> ${resultsDir}/sitemap.xml
      echo "<url><loc>https://blog.openthefar.com/a-quick-reference-guide-to-far-2-101-definitions/</loc><lastmod>2023-01-01</lastmod><changefreq>monthly</changefreq><priority>1.0</priority></url>" >> ${resultsDir}/sitemap.xml
      echo "<url><loc>https://blog.openthefar.com/what-is-fob-origin/</loc><lastmod>2023-01-01</lastmod><changefreq>monthly</changefreq><priority>1.0</priority></url>" >> ${resultsDir}/sitemap.xml
      echo "<url><loc>https://blog.openthefar.com/far-part-12-and-far-part-15/</loc><lastmod>2023-01-01</lastmod><changefreq>monthly</changefreq><priority>1.0</priority></url>" >> ${resultsDir}/sitemap.xml
      echo "</urlset>" >> ${resultsDir}/sitemap.xml
      #==================================================#
      ### Upload Sitemap
      #==================================================#
      echo "- Remove old sitemap for ${agencyName}"
      echo "aws s3 cp ${resultsDir}/sitemap.xml s3://${bucketName}/sitemap.xml --region ${awsRegion}"
      aws s3 cp ${resultsDir}/sitemap.xml s3://${bucketName}/sitemap.xml --region ${awsRegion}
      if [ "${environment}" == "prod" ] || [ "${environment}" == "Prod" ] || [ "${environment}" == "PROD" ]; then
        curl https://www.google.com/webmasters/sitemaps/ping?sitemap=https://openthefar.com/sitemap.xml
      else
        echo "${environment}: Skipping Sitemap notification"
      fi

      #==================================================#
      ### Upload Elastic
      ### - Uses:
      ###      - results/elastic-chapter-${ch}.json
      #==================================================#
      if [ "${indexName}" != "" ] && [ -f ${farResultsDir}elastic-chapter-${ch}.json ]; then

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
          echo "   Started at: $(date)"
          idx=0
          while read j; do
            idx=$((idx+1))

            request=$(echo $j | jq 'del(._id)' -c)
            id=$(echo $j | jq '"\(._id)"' -r)
            #echo "curl -s -X PUT  https://search-far-elasticsearch-xqucmrm5ng7d43q55be2rk7hm4.us-east-2.es.amazonaws.com:443/${indexName}/_doc/${id} -H 'Content-Type: application/json' -d \"$request\""
            output=$(curl -s -X PUT  https://search-far-elasticsearch-xqucmrm5ng7d43q55be2rk7hm4.us-east-2.es.amazonaws.com:443/${indexName}/_doc/${id} -H 'Content-Type: application/json' -d "$request")
            status=$?
            #echo "$output"
            #echo "${status}"

            if [ "${status}" != "0" ] ; then
              echo "Problem on line: ${idx}: ${id}"
            fi
            #echo ""
          # Read from the elastic-chapter file and add the agency block to it.
          done < <(cat ${farResultsDir}elastic-chapter-${ch}.json | jq '. | select (.content == "" | not)' -c | jq --argjson json "`<${farResultsDir}/agency-chapter-${ch}-doc.json`" '. + {agencies: $json}' -c  )

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

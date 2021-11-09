#!/bin/bash

################# Control Variables ##################
#Used in generating the Mongo Records
DATE=$(date -u +'%FT%TZ')
######################################################
source scripts/functions.sh

#====================================================#
############ Parse Parameters      ###################
#====================================================#
if [ -z $1 ] ; then
  echo "Expects at least one param: ChapterList (Integer- comma-delimited).  Second Param (Date YYYY-MM-DD) is optional"
  exit 1
fi

chapters=$1
if [ -z $2 ] ; then
  dt=$(date '+%Y-%m-%d')
else
  dt=$2
fi
echo "Processing thru date $dt"

for ch in ${chapters//,/ }; do
  if [ "${ch}" == "1" ] ; then
    includeFAR=Y
  fi
done

#====================================================#
############ Cleanup prior runs    ###################
#====================================================#
./reset.sh

#====================================================#
############ Metadata              ###################
#====================================================#
echo "${chapters}" > tmp/chapters.meta
echo "${dt}" > tmp/cfr-date.meta
echo "$(date)" > tmp/run-date.meta
echo $(git log -1 | head -1 | awk '{print $2}') > tmp/git.meta

#====================================================#
############ Download new XML File ###################
#====================================================#
if [ -f tmp/raw-${dt}.xml ]; then
  echo "Skipping download because tmp/raw-${dt}.xml already exists"
else
  #https://www.ecfr.gov/api/versioner/v1/full/2021-09-11/title-48.xml
  curl -X GET "https://www.ecfr.gov/api/versioner/v1/full/${dt}/title-48.xml" -H "accept: application/xml" > tmp/raw-${dt}.xml
#  https://www.ecfr.gov
#  curl -X GET "https://ecfr.federalregister.gov/api/versioner/v1/full/${dt}/title-48.xml" -H "accept: application/xml" > tmp/raw-${dt}.xml
fi

## These may both be MAC specific
fileSize=$(stat -f "%z" tmp/raw-${dt}.xml)
fileSha=$(openssl dgst -sha256 tmp/raw-2021-11-08.xml | cut -d" " -f2)
#==========================================#
############ Process FAR ###################
#==========================================#
if [ "${includeFAR}" == "Y" ] ; then
  agencyId=539
  ch=1
  echo "======================================="
  echo "=====   FAR: (agencyId: ${agencyId})"
  echo "======================================="

  echo "{\"title\":48,\"chapter\":${ch},\"agencyName\":\"FAR\",\"cfrDate\":\"${dt}\",\"url\":\"https://www.ecfr.gov/api/versioner/v1/full/${dt}/title-48.xml\",\"gitHash\":\"$(cat tmp/git.meta)\",\"scrapeDate\":{\"\$date\": \"$DATE\"},\"size\":${fileSize},\"sha\":\"${fileSha}\"}" > results/scrape-${ch}.json

  #==================================================#
  ### Generate Raw JSON from XML
  ### - Creates:
  ###      - tmp/raw-subchapter-1.json
  ###      - tmp/raw-subpart-1.json
  ###      - tmp/raw-section-1.json
  #==================================================#
  echo " - Generate json for Mongo for FAR"
  ./scripts/gen-rawjson-far-py.sh tmp/raw-${dt}.xml ${ch}
  echo "   - Results:"
  echo "       - SubChapters (type=1): $(cat tmp/raw-subchapter-${ch}.json | jq . -c | wc -l)"
  echo "       - Parts (type=2): $(cat tmp/raw-part-${ch}.json | jq . -c | wc -l)"
  echo "       - Subparts (type=3): $(cat tmp/raw-subpart-${ch}.json | jq . -c | wc -l)"
  echo "       - Appendix/ Preambles (type=4): NA"
  echo "       - Section (type=5): $(cat tmp/raw-section-${ch}.json | jq . -c | wc -l)"

  #==================================================#
  ### Clean up JSON for uploading to Mongo
  ### - Creates:
  ###      - results/mongo-chapter-1.json
  ##    - Remove the content field
  ##    - Add the createdAt and updatedAt fields
  ##    - Add the Agency field from the agencies/ folder
  #==================================================#
  ## Type 1
  cat tmp/raw-subchapter-${ch}.json |
    jq --argjson json "`<agencies/agency-${agencyId}.json`" '. + {agencies: $json}' |\
    jq --arg DATE "$DATE"  '.createdAt += {"$date": $DATE}' | \
    jq --arg DATE "$DATE"  '.updatedAt += {"$date": $DATE}' -c |
    jq 'del(.content )' | \
    jq '. + {content: ""}' -c  \
    > results/mongo-chapter-${ch}.json

  ## Type 2
  cat tmp/raw-part-${ch}.json |
    jq --argjson json "`<agencies/agency-${agencyId}.json`" '. + {agencies: $json}' |\
    jq --arg DATE "$DATE"  '.createdAt += {"$date": $DATE}' | \
    jq --arg DATE "$DATE"  '.updatedAt += {"$date": $DATE}' -c |
    jq 'del(.content )' | \
    jq '. + {content: ""}' -c  \
    >> results/mongo-chapter-${ch}.json

  ## Type 3
  cat tmp/raw-subpart-${ch}.json |
    jq --argjson json "`<agencies/agency-${agencyId}.json`" '. + {agencies: $json}' |\
    jq --arg DATE "$DATE"  '.createdAt += {"$date": $DATE}' | \
    jq --arg DATE "$DATE"  '.updatedAt += {"$date": $DATE}' -c |
    jq 'del(.content )' | \
    jq '. + {content: ""}' -c  \
    >> results/mongo-chapter-${ch}.json

  ## Type 5
  cat tmp/raw-section-${ch}.json |
    jq --argjson json "`<agencies/agency-${agencyId}.json`" '. + {agencies: $json}' |\
    jq --arg DATE "$DATE"  '.createdAt += {"$date": $DATE}' | \
    jq --arg DATE "$DATE"  '.updatedAt += {"$date": $DATE}' -c |
    jq 'del(.content )' | \
    jq '. + {content: ""}' -c  \
    >> results/mongo-chapter-${ch}.json
  echo "       - Total: $(cat results/mongo-chapter-1.json | jq . -c | wc -l)"

  #==================================================#
  ### Clean up JSON for uploading to Elastic
  ### - Creates:
  ###      - results/elastic-chapter-1.json
  #==================================================#
  echo " - Generate json for Elastic for FAR"
  cat tmp/raw-subchapter-${ch}.json | \
    jq '{_id, title, htmlUrl, content, cfrIdentifier, agencies, type}' -c \
    > results/elastic-chapter-${ch}.json

  cat tmp/raw-part-${ch}.json | \
    jq '{_id, title, htmlUrl, content, cfrIdentifier, agencies, type}' -c \
    >> results/elastic-chapter-${ch}.json

  cat tmp/raw-subpart-${ch}.json | \
    jq '{_id, title, htmlUrl, content, cfrIdentifier, agencies, type}' -c \
    >> results/elastic-chapter-${ch}.json

  cat tmp/raw-section-${ch}.json | \
    jq '{_id, title, htmlUrl, content, cfrIdentifier, agencies, type}' -c \
    >> results/elastic-chapter-${ch}.json

  echo "   - Results: results/elastic-chapter-${ch}.json : $(cat results/elastic-chapter-${ch}.json | jq '.' -c | wc -l)"

  #==================================================#
  ### Create Html for FAR from raw xml
  ### - Creates:
  ###      - html/${agencyName}/*.html
  #==================================================#
  echo " - Generate html for FAR"
  #Div4
  ./scripts/gen-far-subchapter-html-py.sh tmp/raw-${dt}.xml html/far 1
  #Div5
  ./scripts/gen-far-part-html-py.sh tmp/raw-${dt}.xml html/far 1
  #Div6
  ./scripts/gen-far-subpart-html-py.sh tmp/raw-${dt}.xml html/far 1

  echo "    - Total files $(ls -Al html/far/ | tail +2 | wc -l)"
  echo "======================================="
  echo ""
else
  echo "Skipping FAR because 'includeFar' is ${includeFAR}"
fi

#==================================================#
############ Process Supplements ###################
#==================================================#
for ch in ${chapters//,/ }; do
  if [ "${ch}" != "1" ] ; then
    # This assigns the "agencyName" variable
    getNameForChapter ${ch}
    agencyDisplayname=$(echo ${agencyName} | tr [:lower:] [:upper:])

    echo "{\"title\":48,\"chapter\":${ch},\"agencyName\":\"${agencyDisplayname}\",\"cfrDate\":\"${dt}\",\"url\":\"https://www.ecfr.gov/api/versioner/v1/full/${dt}/title-48.xml\",\"gitHash\":\"$(cat tmp/git.meta)\",\"scrapeDate\":{\"\$date\": \"$DATE\"},\"size\":${fileSize},\"sha\":\"${fileSha}\"}" > results/scrape-${ch}.json

    #==================================================#
    ### Generate Raw JSON from XML
    ### - Creates:
    ###      - tmp/raw-subchapter-${ch}.json
    ###      - tmp/raw-subpart-${ch}.json
    ###      - tmp/raw-section-${ch}.json
    #==================================================#
    echo "======================================="
    echo "=====   ${agencyDisplayname} (agencyId: ${agencyId})"
    echo "======================================="
    echo " - Generate json for Mongo/ Elastic"
    ./scripts/gen-rawjson-suppl-py.sh tmp/raw-${dt}.xml ${ch}
    echo "   - Results: "
    echo "        - SubChapters: $(cat tmp/raw-subchapter-${ch}.json | jq . -c | wc -l)"
    echo "        - Parts: $(cat tmp/raw-part-${ch}.json | jq . -c | wc -l)"
    echo "        - Subparts: $(cat tmp/raw-subpart-${ch}.json | jq . -c | wc -l)"
    echo "        - Section: $(cat tmp/raw-section-${ch}.json | jq . -c | wc -l)"

    #==================================================#
    ### Clean up JSON for uploading to Mongo
    ### - Creates:
    ###      - results/mongo-chapter-${ch}.json
    ##    - Remove the content field
    ##    - Add the createdAt and updatedAt fields
    ##    - Add the Agency field from the agencies/ folder
    #==================================================#
    ## Type 1-
    #cat tmp/raw-subchapter-${ch}.json |
    #  jq --argjson json "`<agencies/agency-${agencyId}.json`" '. + {agencies: $json}' |\
    #  jq --arg DATE "$DATE"  '.createdAt += {"$date": $DATE}' | \
    #  jq --arg DATE "$DATE"  '.updatedAt += {"$date": $DATE}' -c |
    #  jq 'del(.content )' | \
    #  jq '. + {content: ""}' -c  \
    #  > results/mongo-chapter-${ch}.json

    ## Type 2-  Removing this, because it breaks the expandable chapter list on the first page
    #cat tmp/raw-part-${ch}.json |
    #  jq --argjson json "`<agencies/agency-${agencyId}.json`" '. + {agencies: $json}' |\
    #  jq --arg DATE "$DATE"  '.createdAt += {"$date": $DATE}' | \
    #  jq --arg DATE "$DATE"  '.updatedAt += {"$date": $DATE}' -c |
    #  jq 'del(.content )' | \
    #  jq '. + {content: ""}' -c  \
    #  >> results/mongo-chapter-${ch}.json

    ## Type 3
    cat tmp/raw-subpart-${ch}.json |
      jq --argjson json "`<agencies/agency-${agencyId}.json`" '. + {agencies: $json}' |\
      jq --arg DATE "$DATE"  '.createdAt += {"$date": $DATE}' | \
      jq --arg DATE "$DATE"  '.updatedAt += {"$date": $DATE}' -c |
      jq 'del(.content )' | \
      jq '. + {content: ""}' -c  \
      >> results/mongo-chapter-${ch}.json

    ## Type 5
    cat tmp/raw-section-${ch}.json |
      jq --argjson json "`<agencies/agency-${agencyId}.json`" '. + {agencies: $json}' |\
      jq --arg DATE "$DATE"  '.createdAt += {"$date": $DATE}' | \
      jq --arg DATE "$DATE"  '.updatedAt += {"$date": $DATE}' -c |
      jq 'del(.content )' | \
      jq '. + {content: ""}' -c  \
      >> results/mongo-chapter-${ch}.json

    echo "        - Total: $(cat results/mongo-chapter-${ch}.json | jq . -c | wc -l)"

    ###################################################################
    #==================================================#
    ### Create Html for Supplement from raw xml
    ### - Creates:
    ###      - html/${agencyName}/*.html
    #==================================================#
    echo " - Generate html for ${agencyDisplayname}"
    mkdir -p html/${agencyName}
    echo "   - Generating HTML Top"
    ./scripts/gen-supplement-part-html-top-py.sh tmp/raw-${dt}.xml  html/${agencyName} ${ch}
    echo "   - Generating HTML Bottom"
    ./scripts/gen-supplement-part-html-bottom-py.sh tmp/raw-${dt}.xml  html/${agencyName} ${ch}
    echo "    - Total files $(ls -Al html/${agencyName}/ | tail +2 | wc -l)"

    echo " - Update citations to internal links"
    ./replaceCitation-far.sh

    echo "======================================="
    echo ""
  fi
done

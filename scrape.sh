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

#==========================================#
############ Process FAR ###################
#==========================================#
if [ "${includeFAR}" == "Y" ] ; then
  agencyId=539
  ch=1
  ########---- decompose raw file into chapter specific json -----##########
  # Uses a sax parser to generate tmp/raw-title-${chapter}.json
  echo "======================================="
  echo "=====   FAR: (agencyId: ${agencyId})"
  echo "======================================="
  echo " - Generate json for Mongo/ Elastic for FAR"
  ./scripts/gen-rawjson-py.sh tmp/raw-${dt}.xml ${ch}
  echo "   - Results:"
  echo "       - SubChapters (type=1): $(cat tmp/raw-subchapter-${ch}.json | jq . -c | wc -l)"
  echo "       - Parts (type=2): 0  (TODO: Needs its own html as well)"
  echo "       - Subparts (type=3): $(cat tmp/raw-subpart-${ch}.json | jq . -c | wc -l)"
  echo "       - Appendix/ Preambles (type=4): NA"
  echo "       - Section (type=5): $(cat tmp/raw-section-${ch}.json | jq . -c | wc -l)"

  ###################################################################
  ### Clean up JSON for uploading to Mongo
  ##    - Remove the content field
  ##    - Add the createdAt and updatedAt fields
  ##    - Add the Agency field from the agencies/ folder
  cat tmp/raw-subchapter-${ch}.json |
    jq --argjson json "`<agencies/agency-${agencyId}.json`" '. + {agencies: $json}' |\
    jq --arg DATE "$DATE"  '.createdAt += {"$date": $DATE}' | \
    jq --arg DATE "$DATE"  '.updatedAt += {"$date": $DATE}' -c |
    jq 'del(.content )' | \
    jq '. + {content: ""}' -c  \
    > results/mongo-chapter-${ch}.json

  cat tmp/raw-subpart-${ch}.json |
    jq --argjson json "`<agencies/agency-${agencyId}.json`" '. + {agencies: $json}' |\
    jq --arg DATE "$DATE"  '.createdAt += {"$date": $DATE}' | \
    jq --arg DATE "$DATE"  '.updatedAt += {"$date": $DATE}' -c |
    jq 'del(.content )' | \
    jq '. + {content: ""}' -c  \
    >> results/mongo-chapter-${ch}.json

  cat tmp/raw-section-${ch}.json |
    jq --argjson json "`<agencies/agency-${agencyId}.json`" '. + {agencies: $json}' |\
    jq --arg DATE "$DATE"  '.createdAt += {"$date": $DATE}' | \
    jq --arg DATE "$DATE"  '.updatedAt += {"$date": $DATE}' -c |
    jq 'del(.content )' | \
    jq '. + {content: ""}' -c  \
    >> results/mongo-chapter-${ch}.json
  echo "       - Total: $(cat results/mongo-chapter-1.json | jq . -c | wc -l)"

  ###################################################################
  ########---- decompose raw file into different html files for FAR-----##########
  echo " - Generate html for FAR"
  ./scripts/gen-far-subpart-html-py.sh tmp/raw-${dt}.xml html/far 1
  ./scripts/gen-far-part-html-py.sh tmp/raw-${dt}.xml html/far 1

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

    echo "======================================="
    echo "=====   ${agencyDisplayname} (agencyId: ${agencyId})"
    echo "======================================="
    echo " - Generate json for Mongo/ Elastic"
    ./scripts/gen-rawjson-py.sh tmp/raw-${dt}.xml ${ch}
    echo "   - Results: "
    echo "        - SubChapters: $(cat tmp/raw-subchapter-${ch}.json | jq . -c | wc -l)"
    echo "        - Subparts: $(cat tmp/raw-subpart-${ch}.json | jq . -c | wc -l)"
    echo "        - Section: $(cat tmp/raw-section-${ch}.json | jq . -c | wc -l)"

    ### Clean up JSON for uploading to Mongo
    ##    - Remove the content field
    ##    - Add the createdAt and updatedAt fields
    ##    - Add the Agency field from the agencies/ folder
    cat tmp/raw-subchapter-${ch}.json |
      jq --argjson json "`<agencies/agency-${agencyId}.json`" '. + {agencies: $json}' |\
      jq --arg DATE "$DATE"  '.createdAt += {"$date": $DATE}' | \
      jq --arg DATE "$DATE"  '.updatedAt += {"$date": $DATE}' -c |
      jq 'del(.content )' | \
      jq '. + {content: ""}' -c  \
      > results/mongo-chapter-${ch}.json

    cat tmp/raw-subpart-${ch}.json |
      jq --argjson json "`<agencies/agency-${agencyId}.json`" '. + {agencies: $json}' |\
      jq --arg DATE "$DATE"  '.createdAt += {"$date": $DATE}' | \
      jq --arg DATE "$DATE"  '.updatedAt += {"$date": $DATE}' -c |
      jq 'del(.content )' | \
      jq '. + {content: ""}' -c  \
      >> results/mongo-chapter-${ch}.json

    cat tmp/raw-section-${ch}.json |
      jq --argjson json "`<agencies/agency-${agencyId}.json`" '. + {agencies: $json}' |\
      jq --arg DATE "$DATE"  '.createdAt += {"$date": $DATE}' | \
      jq --arg DATE "$DATE"  '.updatedAt += {"$date": $DATE}' -c |
      jq 'del(.content )' | \
      jq '. + {content: ""}' -c  \
      >> results/mongo-chapter-${ch}.json

    echo "        - Total: $(cat results/mongo-chapter-${ch}.json | jq . -c | wc -l)"

    ###################################################################

    echo " - Generate html for ${agencyDisplayname}"
    mkdir -p html/${agencyName}
    echo "   - Generating HTML Top"
    ./scripts/gen-supplement-part-html-top-py.sh tmp/raw-${dt}.xml  html/${agencyName} ${ch}
    echo "   - Generating HTML Bottom"
    ./scripts/gen-supplement-part-html-bottom-py.sh tmp/raw-${dt}.xml  html/${agencyName} ${ch}

    echo "    - Total files $(ls -Al html/${agencyName}/ | tail +2 | wc -l)"

    echo "======================================="
    echo ""
  fi
done

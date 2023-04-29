#!/bin/bash
source scripts/functions.sh

#====================================================#
############ Parse Parameters      ###################
#====================================================#
if [ -z $1 ] ; then
  echo "Expects at least one param: ChapterList (Integer- comma-delimited).  Second Param (Date YYYY-MM-DD) is optional"
  echo "Available Agencies are: "
  for agency in $(ls agencies/); do
    agencyName=$(cat agencies/${agency} | jq '.[0]' | jq '.shortName' -r)
    id=$(cat agencies/${agency} | jq '.[0]' | jq '._id' -r | cut -d . -f2)
    echo "${id}: ${agencyName}"
  done
  exit 1
fi
python  --version
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
  if [ ! -f agencies/agency-chapter-${ch}.json ]; then
    echo "ERROR There is no agency configuration for chapter ${ch} (agencies/agency-chapter-${ch}.json) "
    exit 1
  fi
  getNameForChapter ${ch}
  mkdir -p results/${agencyName}/
  echo "Scraping ${agencyName} as id: ${agencyId}"
done

#====================================================#
############ Cleanup prior runs    ###################
#====================================================#
./reset.sh

#====================================================#
############ Download new XML File ###################
#====================================================#
if [ -f ${tmpDir}raw-${dt}.xml ]; then
  echo "Skipping download because ${tmpDir}raw-${dt}.xml already exists"
else
  #https://www.ecfr.gov/api/versioner/v1/full/2021-09-11/title-48.xml
  curl -X GET "https://www.ecfr.gov/api/versioner/v1/full/${dt}/title-48.xml" -H "accept: application/xml" > ${tmpDir}raw-${dt}.xml

#  https://www.ecfr.gov
#  curl -X GET "https://ecfr.federalregister.gov/api/versioner/v1/full/${dt}/title-48.xml" -H "accept: application/xml" > ${tmpDir}raw-${dt}.xml
fi

size=$(wc -c ${tmpDir}raw-${dt}.xml | awk '{print $1}')
if [ ${size} == "160" ]; then
  echo "There is no valid file for ${tmpDir}raw-${dt}.xml!!"
  echo "You can check here for other files:  https://www.ecfr.gov/api/versioner/v1/full/${dt}/title-48.xml"
  cat ${tmpDir}raw-${dt}.xml
  echo ""
  exit 1
else
  sed -i 's/—/-/g' ${tmpDir}raw-${dt}.xml 
fi

#====================================================#
############ Metadata              ###################
#====================================================#
echo "${chapters}" > ${resultsDir}chapters.meta
echo "${dt}" > ${resultsDir}cfr-date.meta
echo "$(date)" > ${resultsDir}run-date.meta
echo $(git log -1 | head -1 | awk '{print $2}') > ${resultsDir}git.meta
## These may both be MAC specific
fileSize=$(stat -f "%z" ${tmpDir}raw-${dt}.xml)
fileSha=$(openssl dgst -sha256 ${tmpDir}raw-${dt}.xml | cut -d" " -f2)
DATE=$(date -u +'%FT%TZ')
echo $DATE > ${resultsDir}created-date.meta

#==========================================#
############ Process FAR ###################
#==========================================#
if [ "${includeFAR}" == "Y" ] ; then
  ch=1
  getNameForChapter ${ch}
  farResultsDir=${resultsDir}${agencyName}/
  mkdir -p ${resultsDir}${agencyName}/html/

  echo "======================================="
  echo "=====   ${agencyDisplayname}: (agencyId: ${agencyId})"
  echo "======================================="

  echo "{\"title\":48,\"chapter\":${ch},\"agencyName\":\"FAR\",\"cfrDate\":\"${dt}\",\"url\":\"https://www.ecfr.gov/api/versioner/v1/full/${dt}/title-48.xml\",\"gitHash\":\"$(cat ${resultsDir}git.meta)\",\"scrapeDate\":{\"\$date\": \"$DATE\"},\"size\":${fileSize},\"sha\":\"${fileSha}\"}" > ${farResultsDir}scrape-${ch}.json

  #==================================================#
  ### Generate Agency JSON
  ### - Creates:
  ###      - ${farResultsDir}/agency-chapter-${ch}.json
  ###      - ${farResultsDir}/agency-chapter-${ch}-doc.json
  #==================================================#
  #TODO:  Add Created Date to this
  cp agencies/agency-chapter-${ch}.json ${farResultsDir}

  agencyJsonForDoc=${farResultsDir}/agency-chapter-${ch}-doc.json
  cat agencies/agency-chapter-${ch}.json | jq '.[0]' | jq '[{_id,agencyId,name,shortName,chapter}]' -c > ${agencyJsonForDoc}

  #==================================================#
  ### Generate Raw JSON from XML
  ### - Creates:
  ###      - ${tmpDir}raw-subchapter-1.json
  ###      - ${tmpDir}raw-subpart-1.json
  ###      - ${tmpDir}raw-section-1.json
  #==================================================#
  echo " - Generate json for Mongo for FAR"
  python ${scriptsDir}gen-rawjson-far-py.sh ${tmpDir}raw-${dt}.xml ${ch}
  echo "   - Results:"
  echo "       - SubChapters (type=1): $(cat ${tmpDir}raw-subchapter-${ch}.json | jq . -c | wc -l)"
  echo "       - Parts (type=2): $(cat ${tmpDir}raw-part-${ch}.json | jq . -c | wc -l)"
  echo "       - Subparts (type=3): $(cat ${tmpDir}raw-subpart-${ch}.json | jq . -c | wc -l)"
  echo "       - Appendix/ Preambles (type=4): NA"
  echo "       - Section (type=5): $(cat ${tmpDir}raw-section-${ch}.json | jq . -c | wc -l)"

  #==================================================#
  ### Clean up JSON for uploading to Mongo
  ### - Creates:
  ###      - ${farResultsDir}mongo-chapter-1.json
  ##    - Remove the content field
  ##    -  createdAt/ updatedAt and Agency fields are added at upload time
  #==================================================#
  ## Type 1
  cat ${tmpDir}raw-subchapter-${ch}.json | \
    jq 'del(.content )' |  jq '. + {content: ""}' -c  \
    > ${farResultsDir}mongo-chapter-${ch}.json

  ## Type 2
  cat ${tmpDir}raw-part-${ch}.json | \
    jq 'del(.content )' |  jq '. + {content: ""}' -c  \
    >> ${farResultsDir}mongo-chapter-${ch}.json

  ## Type 3
  cat ${tmpDir}raw-subpart-${ch}.json | \
    jq 'del(.content )' |  jq '. + {content: ""}' -c  \
    >> ${farResultsDir}mongo-chapter-${ch}.json

  ## Type 5  -> 3
  cat ${tmpDir}raw-section-${ch}.json | \
    jq 'del(.content )' |  jq '. + {content: ""}' -c  \
    >> ${farResultsDir}mongo-chapter-${ch}.json
  echo "       - Total: $(cat ${farResultsDir}mongo-chapter-1.json | jq . -c | wc -l)"

  #==================================================#
  ### Clean up JSON for uploading to Elastic
  ### The agency block gets added at upload time
  ### - Creates:
  ###      - ${farResultsDir}elastic-chapter-1.json
  #==================================================#
  echo " - Generate json for Elastic for FAR"
  cat ${tmpDir}raw-subchapter-${ch}.json \
    | jq '{_id, title, htmlUrl, content, cfrIdentifier, type}' -c \
    | jq '. | select (.content == "" | not)' -c \
    > ${farResultsDir}elastic-chapter-${ch}.json

  cat ${tmpDir}raw-part-${ch}.json  \
    | jq '{_id, title, htmlUrl, content, cfrIdentifier, type}' -c \
    | jq '. | select (.content == "" | not)' -c \
    >> ${farResultsDir}elastic-chapter-${ch}.json

  cat ${tmpDir}raw-subpart-${ch}.json  \
    | jq '{_id, title, htmlUrl, content, cfrIdentifier, type}' -c \
    | jq '. | select (.content == "" | not)' -c \
    >> ${farResultsDir}elastic-chapter-${ch}.json

  cat ${tmpDir}raw-section-${ch}.json  \
    | jq '{_id, title, htmlUrl, content, cfrIdentifier, type}' -c \
    | jq '. | select (.content == "" | not)' -c \
    >> ${farResultsDir}elastic-chapter-${ch}.json

  echo "   - Results: ${farResultsDir}elastic-chapter-${ch}.json : $(cat ${farResultsDir}elastic-chapter-${ch}.json | jq '.' -c | wc -l)"

  #==================================================#
  ### Create Html for FAR from raw xml
  ### - Creates:
  ###      - results/${agencyName}/html/*.html
  #==================================================#
  echo " - Generate html for FAR"
  #Div4
  python ${scriptsDir}gen-far-subchapter-html-py.sh ${tmpDir}raw-${dt}.xml ${farResultsDir}html 1
  #Div5
  python ${scriptsDir}gen-far-part-html-py.sh ${tmpDir}raw-${dt}.xml ${farResultsDir}html 1
  #Div6
  #48.1.10.x.html
  python ${scriptsDir}gen-far-subpart-html-py.sh ${tmpDir}raw-${dt}.xml ${farResultsDir}html 1

  echo "    - Total files $(ls -Al ${farResultsDir}html/ | tail +2 | wc -l)"

  #==================================================#
  ### Create Internal links to other FAR pages
  ### - Creates:
  ###      - results/far/replace-far.sh
  #==================================================#
  echo ""
  echo " - Update citations to internal links"
  ${scriptsDir}replaceCitation-far.sh

  echo ""
  echo " - Generate sitemap.xml"
  ${scriptsDir}generate-site-map.sh ${dt}
  echo "======================================="

  cp ${resultsDir}*.meta ${farResultsDir}
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

    supplResultsDir=${resultsDir}${agencyName}/
    mkdir -p ${supplResultsDir}

    echo "{\"title\":48,\"chapter\":${ch},\"agencyName\":\"${agencyDisplayname}\",\"cfrDate\":\"${dt}\",\"url\":\"https://www.ecfr.gov/api/versioner/v1/full/${dt}/title-48.xml\",\"gitHash\":\"$(cat ${resultsDir}git.meta)\",\"scrapeDate\":{\"\$date\": \"$DATE\"},\"size\":${fileSize},\"sha\":\"${fileSha}\"}" > ${supplResultsDir}scrape-${ch}.json

    #==================================================#
    ### Generate Agency JSON
    ### - Creates:
    ###      - ${supplResultsDir}/agency-chapter-${ch}.json
    ###      - ${supplResultsDir}/agency-chapter-${ch}-doc.json
    #==================================================#
    #TODO:  Add Created Date to this
    cp agencies/agency-chapter-${ch}.json ${supplResultsDir}

    agencyJsonForDoc=${supplResultsDir}/agency-chapter-${ch}-doc.json
    cat agencies/agency-chapter-${ch}.json | jq '.[0]' | jq '[{_id,agencyId,name,shortName,chapter}]' -c > ${agencyJsonForDoc}

    #==================================================#
    ### Generate Raw JSON from XML
    ### - Creates:
    ###      - ${tmpDir}raw-subchapter-${ch}.json
    ###      - ${tmpDir}raw-subpart-${ch}.json
    ###      - ${tmpDir}raw-section-${ch}.json
    #==================================================#
    echo "======================================="
    echo "=====   ${agencyDisplayname} -agencyId: ${agencyId}"
    echo "======================================="
    echo " - Generate json for Mongo/ Elastic"
    python ${scriptsDir}gen-rawjson-suppl-py.sh ${tmpDir}raw-${dt}.xml ${ch}
    echo "   - Results: "
    echo "        - SubChapters: $(cat ${tmpDir}raw-subchapter-${ch}.json | jq . -c | wc -l)"
    echo "        - Parts: $(cat ${tmpDir}raw-part-${ch}.json | jq . -c | wc -l)"
    echo "        - Subparts: $(cat ${tmpDir}raw-subpart-${ch}.json | jq . -c | wc -l)"
    echo "        - Section: $(cat ${tmpDir}raw-section-${ch}.json | jq . -c | wc -l)"

    #==================================================#
    ### Clean up JSON for uploading to Mongo
    ### - Creates:
    ###      - ${resultsDir}mongo-chapter-${ch}.json
    ##    - Remove the content field
    ##    -  createdAt/ updatedAt and Agency fields are added at upload time
    #==================================================#
    ## Type 1-
    #cat ${tmpDir}raw-subchapter-${ch}.json |
    #  jq 'del(.content )' |  jq '. + {content: ""}' -c  \
    #  > ${resultsDir}mongo-chapter-${ch}.json

    ## Type 2-  Removing this, because it breaks the expandable chapter list on the first page
    #cat ${tmpDir}raw-part-${ch}.json |
    #  jq 'del(.content )' |  jq '. + {content: ""}' -c  \
    #  >> ${resultsDir}mongo-chapter-${ch}.json

    ## Type 3
    cat ${tmpDir}raw-subpart-${ch}.json |
      jq 'del(.content )' | jq '. + {content: ""}' -c  \
      >> ${supplResultsDir}mongo-chapter-${ch}.json

    ## Type 5
    cat ${tmpDir}raw-section-${ch}.json |
      jq 'del(.content )' | jq '. + {content: ""}' -c  \
      >> ${supplResultsDir}mongo-chapter-${ch}.json

    echo "        - Total: $(cat ${supplResultsDir}mongo-chapter-${ch}.json | jq . -c | wc -l)"

    #==================================================#
    ### Clean up JSON for uploading to Elastic
    ### The agency block gets added at upload time
    ### - Creates:
    ###      - ${farResultsDir}elastic-chapter-1.json
    #==================================================#
    echo " - Generate json for Elastic for ${agencyDisplayname}"
    cat ${tmpDir}raw-subchapter-${ch}.json \
      | jq '{_id, title, htmlUrl, content, cfrIdentifier, type}' -c \
      | jq '. | select (.content == "" | not)' -c \
      > ${supplResultsDir}elastic-chapter-${ch}.json

    cat ${tmpDir}raw-part-${ch}.json  \
      | jq '{_id, title, htmlUrl, content, cfrIdentifier, type}' -c \
      | jq '. | select (.content == "" | not)' -c \
      >> ${supplResultsDir}elastic-chapter-${ch}.json

    cat ${tmpDir}raw-subpart-${ch}.json  \
      | jq '{_id, title, htmlUrl, content, cfrIdentifier, type}' -c \
      | jq '. | select (.content == "" | not)' -c \
      >> ${supplResultsDir}elastic-chapter-${ch}.json

    cat ${tmpDir}raw-section-${ch}.json  \
      | jq '{_id, title, htmlUrl, content, cfrIdentifier, type}' -c \
      | jq '. | select (.content == "" | not)' -c \
      >> ${supplResultsDir}elastic-chapter-${ch}.json

    echo "   - Results: ${supplResultsDir}elastic-chapter-${ch}.json : $(cat ${supplResultsDir}elastic-chapter-${ch}.json | jq '.' -c | wc -l)"

    ###################################################################
    #==================================================#
    ### Create Html for Supplement from raw xml
    ### - Creates:
    ###      - html/${agencyName}/*.html
    #==================================================#
    echo " - Generate html for ${agencyDisplayname}"
    mkdir -p ${supplResultsDir}html
    echo "   - Generating HTML Top"
    python ${scriptsDir}gen-supplement-part-html-top-py.sh ${tmpDir}raw-${dt}.xml  ${supplResultsDir}html ${ch}
    echo "   - Generating HTML Bottom"
    python ${scriptsDir}gen-supplement-part-html-bottom-py.sh ${tmpDir}raw-${dt}.xml  ${supplResultsDir}html ${ch}
    echo "    - Total files $(ls -Al ${supplResultsDir}html | tail +2 | wc -l)"

    cp ${resultsDir}*.meta ${supplResultsDir}
    echo "======================================="
    echo ""
  fi
done

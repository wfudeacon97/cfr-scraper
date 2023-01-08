#!/bin/bash

#./generate-site-map.sh [cfr-date YYYY-MM-DD]
source scripts/functions.sh
if [ -z $1 ] ; then
  echo "Expects at least three params: [cfr-date YYYY-MM-DD]]"
  exit 1
fi

outputfile=${resultsDir}sitemap.xml
cfrDate=${1}
baseUrl=https://openthefar.com
# HEADER
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" > ${outputfile}
echo "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">"  >> ${outputfile}

for i in $(ls ${resultsDir}far/html/); do
  section=$(echo ${i}|cut -d. -f3);
  inner=$(echo ${i}|cut -d. -f4);
  # echo "${i}    ${section}"

    if [ "$section" == "A" ] ||
       [ "$section" == "B" ] ||
       [ "$section" == "C" ] ||
       [ "$section" == "D" ] ||
       [ "$section" == "E" ] ||
       [ "$section" == "F" ] ||
       [ "$section" == "G" ] ||
       [ "$section" == "H" ] ||
       [[ $i == *"-"* ]]; then
         echo "Sitemap- skipping file $i"

      else
        score="0.8"
        if [ "$inner" == "html" ]; then
          score="0.1"
        elif [ "$inner" == "0" ]; then
          score="0.1"
        fi
        #Link to site within Javascript framework
        url=${baseUrl}/regulations/539/${section}/${i}
        #Link to internal page only
        #url=${baseUrl}/far/${i}

        echo "<url><loc>${url}</loc><lastmod>${cfrDate}</lastmod> <changefreq>weekly</changefreq><priority>${score}</priority></url>" >> ${outputfile}
      fi
done

#FOOTER
echo "</urlset>"  >> ${outputfile}

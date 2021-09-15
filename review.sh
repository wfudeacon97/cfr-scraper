
prodFiles=$(ls -Al prod-data/  | tail +2 | wc -l)

if [ ${prodFiles} -gt 0 ] ; then
  echo "Files already exist, no need to repull them from Prod-Mongo"
else
  source connect/connect-prod.sh
  mongo $url --username=$user --password=$pswd --quiet --eval "DBQuery.shellBatchSize = 10000; $(cat mongo/type1.js)"| tail +6 | grep Subchapter -i | jq '.docTitle |= ascii_upcase' -c |  sort > prod-data/prod-type1.json
  mongo $url --username=$user --password=$pswd --quiet --eval "DBQuery.shellBatchSize = 10000; $(cat mongo/type2.js)"| tail +6 | jq '.' -c | sort > prod-data/prod-type2.json
  mongo $url --username=$user --password=$pswd --quiet --eval "DBQuery.shellBatchSize = 10000; $(cat mongo/type3.js)"| tail +6 | jq '.' -c | sort > prod-data/prod-type3.json
  mongo $url --username=$user --password=$pswd --quiet --eval "DBQuery.shellBatchSize = 10000; $(cat mongo/type4.js)"| tail +6 | jq '.' -c | sort > prod-data/prod-type4.json
  mongo $url --username=$user --password=$pswd --quiet --eval "DBQuery.shellBatchSize = 10000; $(cat mongo/type5.js)"| tail +6 | jq '.' -c | sort > prod-data/prod-type5.json

  mongo $url --username=$user --password=$pswd --quiet --eval "DBQuery.shellBatchSize = 10000; $(cat mongo/type1-full.js)"| tail +6 | grep Subchapter -i | jq '.title |= ascii_upcase' -c -S  | sort > prod-data/prodfull-type1.json
  mongo $url --username=$user --password=$pswd --quiet --eval "DBQuery.shellBatchSize = 10000; $(cat mongo/type2-full.js)"| tail +6 | jq '.' -S -c | sort > prod-data/prodfull-type2.json
  mongo $url --username=$user --password=$pswd --quiet --eval "DBQuery.shellBatchSize = 10000; $(cat mongo/type3-full.js)"| tail +6 | jq '.' -S -c | sort > prod-data/prodfull-type3.json
  mongo $url --username=$user --password=$pswd --quiet --eval "DBQuery.shellBatchSize = 10000; $(cat mongo/type4-full.js)"| tail +6 | jq '.' -S -c | sort > prod-data/prodfull-type4.json
  mongo $url --username=$user --password=$pswd --quiet --eval "DBQuery.shellBatchSize = 10000; $(cat mongo/type5-full.js)"| tail +6 | jq '.' -S -c | sort > prod-data/prodfull-type5.json
fi
#cat data/prodfull-type1.json data/prodfull-type2.json data/prodfull-type3.json data/prodfull-type4.json data/prodfull-type5.json > data/prodfull-all.json

# Break out into files by type for debugging and easier comparison
mongo/type-1.sh | grep Subchapter -i | sort > tmp/scraper-type1.json
mongo/type-2.sh | sort > tmp/scraper-type2.json
mongo/type-3.sh | sort > tmp/scraper-type3.json
mongo/type-4.sh | sort > tmp/scraper-type4.json
mongo/type-5.sh | sort > tmp/scraper-type5.json

mongo/full-type1.sh | grep Subchapter -i | sort > tmp/scraperfull-type1.json
mongo/full-type2.sh | sort > tmp/scraperfull-type2.json
mongo/full-type3.sh | sort > tmp/scraperfull-type3.json
mongo/full-type4.sh | sort > tmp/scraperfull-type4.json
mongo/full-type5.sh | sort > tmp/scraperfull-type5.json

# summary
echo "Scrape Results"
echo "========="
echo "type-1: $(cat tmp/scraper-type1.json | jq -r '[.htmlUrl,.cfrIdentifier.chapter,.cfrIdentifier.part] |join(",")' | wc -l)"
echo "type-2:   $(cat tmp/scraper-type2.json | jq -r '[.htmlUrl,.cfrIdentifier.chapter,.cfrIdentifier.part] |join(",")' | wc -l)"
echo "type-3:      $(cat tmp/scraper-type3.json | jq -r '[.htmlUrl,.cfrIdentifier.chapter,.cfrIdentifier.part] |join(",")' | wc -l)"
echo "type-4:   $(cat tmp/scraper-type4.json | jq -r '[.htmlUrl,.cfrIdentifier.chapter,.cfrIdentifier.part] |join(",")' | wc -l)"
echo "type-5:  $(cat tmp/scraper-type5.json | jq -r '[.htmlUrl,.cfrIdentifier.chapter,.cfrIdentifier.part] |join(",")' | wc -l)"
echo "========="
echo "all docs:  $(cat results/mongo-chapter-1.json | jq -r '[.htmlUrl,.cfrIdentifier.chapter,.cfrIdentifier.part] |join(",")' | wc -l)"

echo "Prod"
echo "========="
echo "type-1: $(cat prod-data/prod-type1.json | jq -r '[.htmlUrl,.chapter,.part] |join(",")' | wc -l)"
echo "type-2:   $(cat prod-data/prod-type2.json | jq -r '[.htmlUrl,.chapter,.part] |join(",")' | wc -l)"
echo "type-3:      $(cat prod-data/prod-type3.json | jq -r '[.htmlUrl,.chapter,.part] |join(",")' | wc -l)"
echo "type-4:   $(cat prod-data/prod-type4.json | jq -r '[.htmlUrl,.chapter,.part] |join(",")' | wc -l)"
echo "type-5:  $(cat prod-data/prod-type5.json | jq -r '[.htmlUrl,.chapter,.part] |join(",")' | wc -l)"

echo ""
echo "============================"
echo "Comparing output files:"
echo "type 1"
cmp tmp/scraper-type1.json prod-data/prod-type1.json -b
cmp tmp/scraperfull-type1.json prod-data/prodfull-type1.json -b
echo "type 2"
cmp tmp/scraper-type2.json prod-data/prod-type2.json -b
cmp tmp/scraperfull-type2.json prod-data/prodfull-type2.json -b
echo "type 3"
cmp tmp/scraper-type3.json prod-data/prod-type3.json -b
cmp tmp/scraperfull-type3.json prod-data/prodfull-type3.json -b
echo "type 4"
cmp tmp/scraper-type4.json prod-data/prod-type4.json -b
cmp tmp/scraperfull-type4.json prod-data/prodfull-type4.json -b
echo "type 5"
cmp tmp/scraper-type5.json prod-data/prod-type5.json -b
cmp tmp/scraperfull-type5.json prod-data/prodfull-type5.json -b

# cfr-scraper

## Usage
- ./scrape.sh [comma-delimited list of agency #'s] - This will scrape the listed agencies and leave all html/ json in files locally
- ./reset.sh - This will clear out and reset any temporary directories
- ./review.sh- This will compare the local scrape against the production data pulled from Mongo
- ./upload-scrape.sh - This will save the local scrape to the cfr-scraper bucket for re-use later
- ./reload-scrape.sh [cfr-date YYYY-MM-DD]- this will reset the local environment and pull the scrape files from the cfr-scraper bucket
-./load-scrape-to-environment.sh [cfr-date YYYY-MM-DD] [env PROD | TEST] [comma-delimited list of agency #'s]- this will load a scrape from the cfr-scraper bucket into the corresponding environment

## To add a new agency
- Update the functions.sh
- add the corresponding agency to the agencies folder

## Permanent Folders
- agencies- contains a file with the json fragment for each agency
- mongo- pre-written mongo queries

## Temporary Folders (added to .gitignore)
- tmp- temporary files used during the scraper process
- results- the generated mongo and elastic json files. These are uploaded to mongo and elastic, respectively, at the end of the scraper process
- html- the generated html files.  These are copied to S3 at the end of the scraper process
- connect- this has the connection information for the individual environments
- prod-data- this has data pulled from prod for comparing the scraper results to

##Adding an Agency

#### (1) Find the Agency Json

First, you need to get the Agency JSON from the federalregister.gov.  This will need to be both (a) inserted to the agencies collection in Mongo as well as (b) written as a list '[]' in agencies/agency-[id].json

```
curl https://www.federalregister.gov/api/v1/agencies | jq '.[]  ' -c
curl https://www.federalregister.gov/api/v1/agencies | jq '.[] | {id, name,json_url,parent_id,slug} ' -c | sort | jq '.' -c | grep -i Defense
```
#### (2) Update scripts/functions.sh


## Tools
- /bin/bash
- python
- jq
- mongo (command line) and mongo import
- curl
- aws cli

## 2021-11-28

- Refactor Agency Logic to:
    - Use smaller json fragments in Mongo/ elastic
    - Reduce scraping of new agency to adding agency json file to agencies directory
    - Use id in format of 'Title.chapter'
    - Refresh agencies collection with each upload
- Scrape JSON for Elastic for each supplement (Not yet being uploaded to Elastic)
- Start process of on-boarding new agencies

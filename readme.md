# Contexte
On ne peut pas récupérer les données de la prod, en particulier les cubes Beyond au format IVT ne sont pas exploitables.
On va donc scraper le site avec Selenium.

# Methodologie

- scraper un tableau : `download_one_ivt.R`
- boucle sur tous les tableaux : `scrape_tableauIVT_selenium.R`
- scraper la metadata d'un tableau (hierarchie et position des variables) : `get_metadata_one_ivt.R`
- boucle de recupération des métadata : `scrape_metadataIVT_selenium.R`

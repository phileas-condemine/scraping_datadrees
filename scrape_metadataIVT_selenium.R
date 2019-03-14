library(rvest)
library(dplyr)
library(tidyr)
library(V8)
library(xml2)
library(magrittr)
library(RSelenium)
library(data.table)

##### TOUS LES DOSSIERS
folders=read_html("hierarchie.html",encoding = "utf-8")
scripts_to_open=folders%>%html_nodes("a")%>%
{data.frame(href=html_attr(.,"href"),txt=html_text(.))}%>%
{.[grep("OnFolderClick",.$href),]}%>%
  mutate(href=gsub(pattern = "javascript:",replacement = "return ",x = href))%>%
  filter(!txt=="")%>%
  unique%>%data.table





eCaps <- list(
  chromeOptions = 
    list(prefs = list(
      "profile.default_content_settings.popups" = 0L,
      "profile.default_content_setting_values.notifications" = 2L,
      "download.prompt_for_download" = FALSE,"download.directory_upgrade"= T,#"handlesAlerts"=F,
      "safebrowsing.enabled"= T,#"unexpectedAlertBehaviour"="dismiss",
      "download.default_directory" = paste0(getwd(),"/downloads")
    )
    )
)

rD <- rsDriver(browser = "chrome",extraCapabilities = eCaps,check=F)
remDr <- rD[["client"]]
remDr$navigate("http://www.data.drees.sante.gouv.fr/ReportFolders/reportFolders.aspx")

# source("scrape_tableauIVT_selenium.R")
load("folders_with_IVT.RData")
source("get_metadata_one_ivt.R")

metadata_IVT=vector("list",length=nrow(folders_with_IVT))
names(metadata_IVT) <- folders_with_IVT$href

index_ivt=sample(length(metadata_IVT),1)
already_done_ivts= 3
stop_at=length(metadata_IVT)
index_ivt=18
for (index_ivt in already_done_ivts:stop_at){
  print(index_ivt)
  get_IVT=NULL
  while(is.null(get_IVT)){
    get_IVT=tryCatch({get_metadata_one_ivt(index_ivt)},
      error = function(e) {
                print(e)
                return(NULL)
    })
  }
}

remDr$close()
rD[["server"]]$stop() 


save(metadata_IVT,file="metadata_IVT.RData")

# RETELECHARGER CERTAINS CAS AVEC NIVEAUX 3,4 MANQUANTS 
# TABLEAU 2. EFFECTIFS DES PEDICURES-PODOLOGUES par secteur d'activité, mode d'exercice global, zone d'activité principale, sexe et tranche d'âge Documentation du tableau (s’ouvre dans une nouvelle fenêtre)





##### Pour récupérer la table dans le html
##### On ne charge que 29 lignes à la fois...
# full_html=remDr$getPageSource()
# full_html=read_html(full_html[[1]])
# ivt_table=full_html%>%
#   html_nodes(css = ".TVDataTable")%>%
#   html_table(fill=T)
# ivt_table=ivt_table[[1]]
# colnames(ivt_table) <- ivt_table[1,]
# ivt_table=ivt_table[-1,]
# View(ivt_table)
# remDr$executeScript("imgClick(1,this,event);")
# remDr$findElement(using = "css selector",value = ".TVDataTable")
# remDr$element
# for (i in 1:29)
#   remDr$sendKeysToActiveElement(list(key="down_arrow"))





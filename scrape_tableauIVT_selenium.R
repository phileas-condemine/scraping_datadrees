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

# source("get_list_IVT_selenium.R")
load("list_ivt_links.RData")
# folders_with_IVT$file_nm=NA
source("download_one_ivt.R")
View(folders_with_IVT)
index_ivt=sample(nrow(folders_with_IVT),1)
already_done_ivts= 105
stop_at=113#nrow(folders_with_IVT)
index_ivt=67
for (index_ivt in already_done_ivts:stop_at){
  print(index_ivt)
  get_IVT=NULL
  while(is.null(get_IVT)){
    get_IVT=tryCatch({download_one_ivt(index_ivt)},
      error = function(e) {
                print(e)
                return(NULL)
    })
  }
}

remDr$close()
rD[["server"]]$stop() 


save(folders_with_IVT,file="folders_with_IVT.RData")
fwrite(folders_with_IVT,file="folders_with_IVT.csv")


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





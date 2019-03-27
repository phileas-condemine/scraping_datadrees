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
source("get_dimension_one_ivt.R")

# dimension_lib=vector("list",length=nrow(folders_with_IVT))
# names(dimension_lib) <- folders_with_IVT$href
load("dimension_lib.RData")
index_ivt=sample(length(dimension_lib),1)
# which(unlist(lapply(dimension_lib,is.null)))
already_done_ivts= 1
stop_at=length(dimension_lib)
index_ivt=1
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
  save(dimension_lib,file="dimension_lib.RData")
}

remDr$close()
rD[["server"]]$stop() 

load("dimension_lib.RData")
dimension_lib[["return OnReportClick(3303,1,3303);"]]
elem=dimension_lib[[10]]

dimension_lib2=pbapply::pblapply(1:length(dimension_lib),function(elem_id){
  elem=dimension_lib[[elem_id]]
  href=names(dimension_lib)[elem_id]
  tableSummary=elem[grepl("OnTableSummary",names(elem))]
  tableSummary=data.table(tableSummary[[1]])
  print(sum(grepl("OnDimensionSummary",names(elem))))
  if(sum(grepl("OnDimensionSummary",names(elem)))>0){
    tableSummary$Description=NULL#Moins bonne qualité ou redondante avec celle de DimSummary
    DimSummaries=do.call("rbind",
                       lapply(
                         elem[grepl("OnDimensionSummary",names(elem))],
                         function(x){
                           desc=x$description
                           res=desc$contenu
                           names(res)<-desc$type
                           res
                           }
                         ))
  nm=rownames(DimSummaries)
  DimSummaries=data.table(DimSummaries)
  # View(DimSummaries)
  DimSummaries=merge(tableSummary,DimSummaries,all.x=T,
                     by.y="Nom de la dimension",by.x="Dimension")
  DimSummaries$href=href
  DimSummaries
  } else {
    print("fail")
    NULL
  }
  
})
dimension_lib2=do.call("rbind",dimension_lib2)
# dimension_lib2=bind_rows(dimension_lib2,.id = "id")
dimension_lib2=data.table(dimension_lib2)
dimension_lib2[,"Cube":=list(Cube[!is.na(Cube)][1]),by="href"]
# View(dimension_lib2)

dimension_lib2[href=="return OnReportClick(3303,1,3303);"]


save(dimension_lib2,file="dimension_lib2.RData")




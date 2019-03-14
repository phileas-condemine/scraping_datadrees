get_metadata_one_ivt=function(index_ivt){  
  metadata=list()
  one_ivt=names(metadata_IVT)[index_ivt]
  ivt_name=folders_with_IVT[href==one_ivt]$title
  folder_name=folders_with_IVT[href==one_ivt]$folder_name
  remDr$navigate("http://www.data.drees.sante.gouv.fr/ReportFolders/reportFolders.aspx")
  ivt_name=iconv(ivt_name,from="UTF-8",to="ASCII//TRANSLIT")
  ivt_name=gsub('"',"'",ivt_name)
  ivt_name=gsub("-","",ivt_name)
  ivt_name=gsub(":","",ivt_name)
  ivt_name=gsub("\\/","",ivt_name)
  ivt_name=gsub("\\","",ivt_name,fixed=T)
  ivt_name=gsub(" ","_",ivt_name)
  ivt_name=substr(ivt_name,1,90)
  if(!dir.exists(paste0("downloads/",folder_name))){
    dir.create(paste0("downloads/",folder_name))
  }
  remDr$executeScript(one_ivt)
  Sys.sleep(.2)
  remDr$executeScript("return ShowView(1);")
  Sys.sleep(.2)
  remDr$executeScript("OnDimOrder(ObjWdsForm);")
  Sys.sleep(.5)
  full_html=remDr$getPageSource()
  full_html=read_html(full_html[[1]])
  vars_in_cols=full_html%>%
    html_nodes("#WD_SelId0 > option")%>%
    {data.frame(value=html_attr(x = .,name = "value"),
                txt=html_text(x = .),
                stringsAsFactors = F)}
  vars_in_rows=full_html%>%
    html_nodes("#WD_SelId1 > option")%>%
    {data.frame(value=html_attr(x = .,name = "value"),
                txt=html_text(x = .),
                stringsAsFactors = F)}
  vars_in_others=full_html%>%
    html_nodes("#WD_SelId2 > option")%>%
    {data.frame(value=html_attr(x = .,name = "value"),
                txt=html_text(x = .),
                stringsAsFactors = F)}
  metadata$vars_in_cols=vars_in_cols
  metadata$vars_in_rows=vars_in_rows
  metadata$vars_in_others=vars_in_others
  vars=rbind(vars_in_cols,vars_in_rows,vars_in_others)
  Sys.sleep(.1)
  remDr$findElement(using = "name",value = "WD_Cancel")$clickElement()
  Sys.sleep(.1)
  hierarchies=list()
  # i=3
  for (i in 1:nrow(vars)){
    remDr$executeScript(sprintf("return ShowDim('%s');",vars$value[i]))
    Sys.sleep(.5)
    full_html=remDr$getPageSource()
    full_html=read_html(full_html[[1]])
    to_expand=full_html%>%html_nodes("img")%>%html_attr("src")%>%grep(pattern = "nodeplus.gif")
    if (length(to_expand)>0){
      remDr$executeScript("ExpandAll(true);")
      Sys.sleep(.5)
      full_html=remDr$getPageSource()
      full_html=read_html(full_html[[1]])
    }
    hierarchie_sub=full_html%>%html_nodes("#ItemsTable")%>%html_table(fill=T)%>%.[[1]]
    hierarchie_sub=data.table(hierarchie_sub)
    hierarchie=hierarchie_sub
    if (nrow(hierarchie_sub)>=29){
      avancement=full_html%>%html_nodes("#vScrollTD > img")%>%.[[4]]%>%html_attr("height")
      while(avancement>0){
        print(nrow(hierarchie_sub))
        for (click in 1:29){
          remDr$sendKeysToActiveElement(list(key="down_arrow"))
        }
        full_html=remDr$getPageSource()
        full_html=read_html(full_html[[1]])
        hierarchie_sub=full_html%>%html_nodes("#ItemsTable")%>%html_table(fill=T)%>%.[[1]]
        hierarchie_sub=data.table(hierarchie_sub)
        hierarchie=rbind(hierarchie,hierarchie_sub)
        avancement=full_html%>%html_nodes("#vScrollTD > img")%>%.[[4]]%>%html_attr("height")
      }
    }
    
    
    
    full_NA=sapply(hierarchie,function(x)sum(is.na(x))/nrow(hierarchie))==1
    hierarchie=hierarchie[,!full_NA,with=F]
    hierarchies[[vars$value[i]]]<-hierarchie
  }
  metadata$hierarchies=hierarchies
  metadata_IVT[[one_ivt]] <<- metadata
  remDr$executeScript("return OnDataBank();")
  Sys.sleep(.1)
  return("OK")
}
get_metadata_one_ivt=function(index_ivt){  
  # index_ivt=4
  one_ivt=names(dimension_lib)[index_ivt]
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
  remDr$executeScript("return ShowView(1);")
  remDr$executeScript("OnDimOrder(ObjWdsForm);")
  
  remDr$sendKeysToActiveElement(list(key="tab"))
  
  vars_in_cols=T
  while(vars_in_cols){
    full_html=remDr$getPageSource()
    full_html=read_html(full_html[[1]])
    filtres_autre=full_html%>%
      html_nodes("#WD_SelId0 > option")%>%
      {data.frame(value=html_attr(x = .,name = "value"),
                  txt=html_text(x = .),
                  stringsAsFactors = F)}
    
    children_to_move=which(!grepl("DONNEES",filtres_autre$txt))
    
    
    if (length(children_to_move)>0){
      for (i in 1:children_to_move[1])
        remDr$sendKeysToActiveElement(list(key="down_arrow"))
      remDr$executeScript("OnMoveDim(0,1);")
    } else{
      vars_in_cols=F
    }
  }
  Sys.sleep(.1)
  for (i in 1:5)
    remDr$sendKeysToActiveElement(list(key="tab"))
  for (i in 1:10)#ON S'ASSURE QU'ON EST TOUT EN HAUT
    remDr$sendKeysToActiveElement(list(key="up_arrow"))
  full_html=remDr$getPageSource()
  full_html=read_html(full_html[[1]])
  filtres_autre=full_html%>%
    html_nodes("#WD_SelId1 > option")%>%
    {data.frame(value=html_attr(x = .,name = "value"),
                txt=html_text(x = .),
                stringsAsFactors = F)}
  children_to_move=grep("DONNEES",filtres_autre$txt)-1#
  
  if (length(children_to_move)>0){
    if(children_to_move>0){#On se déplace jusqu'à DONNEES
      for (i in 1:children_to_move)
        remDr$sendKeysToActiveElement(list(key="down_arrow"))
    }
    Sys.sleep(.1)
    remDr$executeScript("OnMoveDim(1,0);")
  }
  
  for (i in 1:5)
    remDr$sendKeysToActiveElement(list(key="tab"))
  
  
  
  full_html=remDr$getPageSource()
  full_html=read_html(full_html[[1]])
  filtres_autre=full_html%>%
    html_nodes("#WD_SelId2 > option")%>%
    {data.frame(value=html_attr(x = .,name = "value"),
                txt=html_text(x = .),
                stringsAsFactors = F)}
  children_to_move=grep("DONNEES",filtres_autre$txt)
  
  if (length(children_to_move)>0){
    for (i in 1:children_to_move)
      remDr$sendKeysToActiveElement(list(key="down_arrow"))
    remDr$executeScript("OnMoveDim(2,1);")
    Sys.sleep(.1)
    remDr$executeScript("OnMoveDim(1,0);")
  }
  
  vars_in_others=T
  while(vars_in_others){
    
    full_html=remDr$getPageSource()
    full_html=read_html(full_html[[1]])
    filtres_autre=full_html%>%
      html_nodes("#WD_SelId2 > option")%>%
      {data.frame(value=html_attr(x = .,name = "value"),
                  txt=html_text(x = .),
                  stringsAsFactors = F)}
    children_to_move=which(!grepl("DONNEES",filtres_autre$txt))
    
    if (length(children_to_move)>0){
      for (i in 1:children_to_move[1])
        remDr$sendKeysToActiveElement(list(key="down_arrow"))
      remDr$executeScript("OnMoveDim(2,1);")
    } else{
      vars_in_others=F
    }
  }
  Sys.sleep(.1)
  remDr$findElement(using = "css selector",value = "#ApplyBtn")$clickElement()

  
  Sys.sleep(.2)
  full_html=remDr$getPageSource()
  full_html=read_html(full_html[[1]])
  
  
  
  
  
  get_dims <- function(node){
    node %>%
    {data.frame(href=html_nodes(.,"a")%>%html_attr(name = "href")%>%
                  paste(collapse="|"),
                txt=html_text(x = .),
                src=html_attr(x = html_node(.,"a > img"),name = "src"),
                stringsAsFactors = F)} %>%{
                  .[grepl("info.gif",.$src),]
                }%>%{
                  .[grepl("OnTableSummary|OnDimensionSummary",.$href),]
                }
  }
  
  # get_dims <- purrr::safely(get_dims)
  
  dimensionsSummaries=purrr::map(.x = full_html%>%
         html_nodes(xpath = "//a/.."),.f = get_dims)
  
  dimensionsSummaries=dimensionsSummaries[sapply(dimensionsSummaries,nrow)>0]
  
  dimensionsSummaries=lapply(dimensionsSummaries,function(x){
    all_href=strsplit(x$href,"\\|")[[1]]
    href=all_href[grepl(pattern = "OnDimensionSummary|OnTableSummary",
          all_href)]
    list(href=href,txt=x$txt)
    
  })
  dimensionsSummaries=do.call("rbind",dimensionsSummaries)
  dimensionsSummaries=data.table(dimensionsSummaries)
  dimension_metadata=vector("list",length=nrow(dimensionsSummaries))
  names(dimension_metadata) <- dimensionsSummaries$href
  
  i=2
  for (i in 1:nrow(dimensionsSummaries)){
    print(i)
    remDr$executeScript(dimensionsSummaries$href[i]%>%gsub(pattern = "javascript:",replacement = ""))
    Sys.sleep(.2)
    curr_window=remDr$getCurrentWindowHandle()[[1]]
    windows=unlist(remDr$getWindowHandles())
    remDr$switchToWindow(setdiff(windows,curr_window))
    Sys.sleep(.2)
    if(grepl(pattern = "OnTableSummary",x = dimensionsSummaries$href[i])){
      full_html=remDr$getPageSource()
      full_html=read_html(full_html[[1]])
      table_dimension=full_html%>%html_nodes("table .CatalogTable")%>%html_table()%>%.[[1]]
      full_text=full_html%>%html_text()%>%gsub(pattern = "\t|\n",replacement = "")
      full_text=stringr::str_extract(full_text,"(Documentation )([:print:]+)(Dimension)")
      full_text=gsub("Documentation|Dimension","",full_text)
      full_text=strsplit(full_text,split = "Titre :|Auteur :|Notes :")
      full_text=tm::stripWhitespace(full_text[[1]])
      full_text=gsub("^ | $","",full_text)
      full_text=data.table(type=c("Documentation","Nom de la dimension","Description","Notes"),
                           contenu=full_text)
      dimension_metadata[i] <- list(dimension=table_dimension,description=full_text)
    } else if (grepl(pattern = "OnDimensionSummary",x = dimensionsSummaries$href[i])){
      full_html=remDr$getPageSource()
      full_html=read_html(full_html[[1]])
      full_text=full_html%>%html_text()%>%gsub(pattern = "\t|\n",replacement = "")
      full_text=stringr::str_extract(full_text,"(Documentation )([:print:]+)$")
      full_text=gsub("Documentation","",full_text)
      full_text=strsplit(full_text,split = "Nom de la dimension :|Description :|Notes :")
      full_text=tm::stripWhitespace(full_text[[1]])
      full_text=gsub("^ | $","",full_text)
      full_text=data.table(type=c("Cube","Nom de la dimension","Description","Notes"),
                           contenu=full_text)
      dimension_metadata[[i]] <- list(dimension=NULL,description=full_text)
    }
    print(full_text)
    remDr$closeWindow()
    remDr$switchToWindow(curr_window)
  }
  
  remDr$executeScript("return OnDataBank();")
  dimension_metadata
  dimension_lib[[one_ivt]] <<- dimension_metadata
  
  
}
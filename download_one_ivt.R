download_one_ivt=function(index_ivt){  
  one_ivt=folders_with_IVT[index_ivt]$href
  ivt_name=folders_with_IVT[index_ivt]$title
  folder_name=folders_with_IVT[index_ivt]$folder_name
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
  Sys.sleep(.1)
  remDr$executeScript("onDownload(2);")
  curr_window=remDr$getCurrentWindowHandle()[[1]]
  windows=unlist(remDr$getWindowHandles())
  remDr$switchToWindow(setdiff(windows,curr_window))
  download_button <-NULL
  timer=0
  start_=Sys.time()
  filtres_autre=data.table()
  while(nrow(filtres_autre)==0&timer<60){
      full_html=remDr$getPageSource(setdiff(windows,curr_window))
      full_html=read_html(full_html[[1]])
      filtres_autre=full_html%>%
        html_nodes(css = "input")%>%
        {data.frame(href=html_attr(.,"onclick"),txt=html_attr(.,"value"),stringsAsFactors = F)}%>%
        {.[grep("OnDownload",.$href),]}%>%
        mutate(href=gsub(pattern = "javascript:",replacement = "return ",x = href))%>%
        filter(!txt=="")%>%
        unique%>%data.table
    timer=difftime(Sys.time(),start_,units = "secs")
  }
  filtres_autre
  if (nrow(filtres_autre)==0){
    print("fichier probablement trop lourd pour l'export, à gérer plus tard en ajoutant des variables en colonnes")
    folders_with_IVT$file_nm[index_ivt] <<- "too_big_to_dl"
    
    } else {
    remDr$executeScript(filtres_autre$href)
    while(sum(grepl("crdownload",list.files("downloads")))){
      print("still downloading, check crdownload files")
      Sys.sleep(.1)
    }
    file_nm=filtres_autre$href
    file_nm=gsub("return OnDownload\\(\"/temp/","",file_nm)
    file_nm=gsub("\");","",file_nm)
    file_nm %in% list.files("downloads/")
    # folders_with_IVT[index_ivt,file_nm:=file_nm]
    folders_with_IVT$file_nm[index_ivt] <<- file_nm
  }
  remDr$closeWindow()
  remDr$switchToWindow(curr_window)
  remDr$executeScript("return OnDataBank();")
  return("OK")
}
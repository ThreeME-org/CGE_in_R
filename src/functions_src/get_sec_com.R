## Extract sectors/commodities from lists
library(tidyverse)
get_sec_com <- function(list.mdl = file.path("src","model","threeme",paste0("R_lists_",iso3,"_",classification,".mdl")), 
                        sectors = TRUE, commodities = TRUE){
 
  list_sec <- NULL
  list_com <- NULL
  
  mdl <- readLines(list.mdl)
  
  if(sectors == TRUE){
    list_sec <- mdl[which(grepl("%list_sec\\s*:=",mdl))] %>% 
      str_remove("%list_sec\\s*:=") %>% 
      str_replace_all("\\s+","@") %>% 
      str_remove("^@") %>% str_remove("@$")  %>% 
      str_split("@") %>%  unlist()
  }
  if(commodities == TRUE){
    list_com <- mdl[which(grepl("%list_com\\s*:=",mdl))] %>% 
      str_remove("%list_com\\s*:=") %>% 
      str_replace_all("\\s+","@") %>% 
      str_remove("^@") %>% str_remove("@$")  %>% 
      str_split("@") %>%  unlist()
  }
  
  res.list <- list(sectors = list_sec, commodities = list_com)
  res.list
}



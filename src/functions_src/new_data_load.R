
### ### ### ### ### ### ### ### 
### ### Create basic base  ### 
### ### ### ### ### ### ### ### 
read_3me_eviews_csv <- function(csv.file.path = file.path("csv", "ct1.csv"), 
                                variables_selection = variables_to_keep,
                                scenario_label = NULL){
  
  ### Checks ###
  if(is.null(scenario_label)){
    scenario_label <- str_remove(basename(csv.file.path),"\\.csv$")
  }
  
  data_read <- data.table::fread(input = csv.file.path,
                                 data.table = TRUE) |> stats::na.omit()
  ### ### ### ### ### ### ###
  
  
  n_scen <- names(data_read |> select(-V1)) |> str_replace("^.+_(\\d+)$","\\1") |> unique() 
  nb <- length(n_scen)
  
  if(length(scenario_label) < (nb-1) ){
    scenario_label <- stringr::str_c("scen", c(1:(nb-1)))
  }else{
    scenario_label<- scenario_label[1:(nb-1)]
  }
  
  n_scen <- purrr::set_names(n_scen,c("baseline",scenario_label ))
  
  
  ### Variable Selection ###
  if(!is.null(variables_selection)){
    
    data_read <- data_read |> select (any_of(c("V1" , map(variables_selection,~str_c(.x,n_scen,sep = "_")) |> unlist()  ) ) )
    
  }
  ### ### ### ### ### ### ###
  
  
  
  nn <- names(data_read)
  sel <- map(n_scen, function(s)keep(nn, str_detect(nn, str_c("_", s,"$") )))
  
  suppressWarnings({
    
    data_long3<- data_read |> data.table::melt(id.vars = "V1",
                                               measure= sel,
                                               variable.factor = TRUE
    ) 
  })
  
  nsel <- sel[[1]] |> str_remove('_0$')
  data_res <- data_long3[, variable_n := nsel[variable]] |> 
    select(-variable) |> rename(variable = variable_n, year = V1) |> relocate(variable, .after = year) |> 
    # mutate(sector = NA_character_, commodity = NA_character_) |> 
    as.data.frame() 
  
  
  
}

### ### ### ### ### ### ### ### ### ### ### ### ### ### 
### ### Function to add sector commodidity names ### ### 
### ### ### ### ### ### ### ### ### ### ### ### ### ### 



add_com_sec_names<- function(data = data_full , 
                             commodities_names = names_commodities,
                             sectors_names = names_sectors ,
                             exception_s_c = c("CONS","CONT")
){
  
  
  ## Function to add sector and commodity names via a codename file
  
  
  ## 1 Check sectors and commodities present in database
  
  ### This functions supposes that commodities or sectors appear only once in a variable name (ie VAR_C, var_S or var_C_S )
  
  variable_frame <- data.frame(variable = data[,"variable"] |> unique() |> toupper() , 
                               unit = 1) |> 
    
    mutate(s_code = str_extract(variable,"_(S[0-9A-Za-z]{3})$", group=1 ),
           c_code = str_extract(variable,"_(C[0-9A-Za-z]{3})(_S|$)", group=1  )
    ) |> as.data.frame()
  
  variable_frame[variable_frame == ''] <- NA
  variable_frame$c_code[variable_frame$c_code %in% exception_s_c] <- NA
  variable_frame$s_code[variable_frame$s_code %in% exception_s_c] <- NA
  
  ## 2. link to the names data base
  
  s_names <- sectors_names |> rename_all(~str_c("s_",.x)) |> mutate(s_code = toupper(s_code) , s_id =1)
  c_names <- commodities_names |> rename_all(~str_c("c_",.x))|> mutate(c_code = toupper(c_code), c_id =1)
  
  variable_id = variable_frame |>  left_join(s_names, by = "s_code") |> left_join(c_names, by = "c_code") |> 
    mutate( unidentified_c = ifelse((!is.na(c_code) & is.na(c_id)), 1 , 0 ),
            unidentified_s = ifelse((!is.na(s_code) & is.na(s_id)), 1 , 0 )
    )
  
  unidentified <- sum(variable_id$unidentified_c) + sum(variable_id$unidentified_s) 
  
  
  if( unidentified > 0 ){
    message_warning(" The following sector/commodity codes could not be identified. Either add them to the bridge and code names for the chosen classification or add them to argument `exception_codes` ")
    
    cat("\n Unidentified sector codes:\n ")
    vars_s <- variable_id |> filter(unidentified_s ==1) |> select(variable, s_code)
    vars_s$s_code |> unique() |>cat(sep = "  ")
    
    cat("\n Found on the following variables: \n")
    vars_s$variable |> cat(sep = "\n")
    
    cat("\n\n Unidentified commodities codes:\n ")
    vars_c<-variable_id |> filter(unidentified_c == 1 ) |> select(variable, c_code )
    vars_c$c_code |> unique() |>cat(sep = "  ")
    
    cat("\n Found on the following variables: \n")
    
    vars_c$variable |> cat(sep = "  ")
  }
  
  
  
  ###. add to full data
  
  data_res <- data |> left_join(variable_id |> select(variable, s_name,s_code), by = "variable") |> 
    left_join(variable_id |> select(variable, c_name, c_code), by = "variable") |> 
    mutate(sector = ifelse(is.na(s_name), s_code,s_name),
           commodity = ifelse(is.na(c_name), s_code,c_name)
    ) |>  
    select(-s_name, -c_name,  -c_code, -s_code)
  
  
}
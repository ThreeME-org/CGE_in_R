eviews_model_solver<- function(config_file = configuration,
                               before_solving_data = data_for_solver, 
                               overwrite_eviews = path_eviews_exe){
  
  
  list2env(config_file,envir = environment())
  list2env(config_file$input,envir = environment())
  list2env(config_file$input$advanced_config,envir = environment())
  path_eviews_exe = overwrite_eviews 
  
  compil = "dynamo"
  data_for_solver <- before_solving_data
  
  ## Run ThreeMe
  ## 1 Edit eviews run file
  # Define the path of Eviews default directory
  eviews_default_path <- str_c(getwd(), "/src/EViews/")
  
  
  # Rewrite run_main_from_R.prg
  readLines("src/EViews/run_main_from_R.prg") %>%
    str_replace_all("(^%iso3\\s*=\\s*).*$", str_c("\\1\\\"", iso3, "\\\"")) %>%
    str_replace_all("(^%path_eviews_default\\s*=\\s*).*$", str_c("\\1\\\"", eviews_default_path,"\\\"")) %>%
    
    str_replace_all("(^%warning\\s*=\\s*).*$", str_c("\\1\\\"", warning, "\\\"")) %>%
    str_replace_all("(^%compil\\s*=\\s*).*$",replacement =paste0("\\1\\\"", compil,"\\\"")) %>%
    
    str_replace_all("(^%firstyear\\s*=\\s*).*$", str_c("\\1\\\"", firstyear, "\\\"")) %>%
    str_replace_all("(^%baseyear\\s*=\\s*).*$", str_c("\\1\\\"", baseyear, "\\\"")) %>%
    str_replace_all("(^%tolerance_calib_check\\s*=\\s*).*$", str_c("\\1\\\"", tolerance_calib_check, "\\\"")) %>%
    
    str_replace_all("(^%lastyear\\s*=\\s*).*$", str_c("\\1\\\"", lastyear, "\\\"")) %>%
    str_replace_all("(^%recompile_model\\s*=\\s*).*$", str_c("\\1\\\"", recompile_model, "\\\"")) %>%
    
    str_replace_all("(^%save_files_res\\s*=\\s*).*$", str_c("\\1\\\"", save_files_res, "\\\"")) %>%
    
    writeLines("src/EViews/run_main_from_R.prg")
  
  if (recompile_model){
    
    
    # Splits calib.csv in 2 files: to get around Eviews limitation regarding loading big csv files
    cat(str_c("Loading calib.csv file. Size: ", round(file.size("src/compiler/calib.csv")/1000000,3), " MB\n"))
    
    calib <- fread("src/compiler/calib.csv", data.table = FALSE) %>% 
      select(-baseyear) %>% 
      mutate(year = year + baseyear) 
    
    limit.size.calib.cvs <- 12 
    nb_calib.files <- ceiling(file.size("src/compiler/calib.csv")/1000000/limit.size.calib.cvs)
    
    if (file.size("src/compiler/calib.csv")/1000000 > limit.size.calib.cvs) {    
      
      (paste("calib.csv is larger than", limit.size.calib.cvs, "MB (EViews limit when importing cvs files). Splitting csv into", nb_calib.files,"files:")) %>% message_warning()
      calib1 <- calib %>% select(.,1                     :round(ncol(.)/2,0))
      calib2 <- calib %>% select(.,(round(ncol(.)/2,0)+1):ncol(.)           )
      
      ("Saving calib1.csv") %>% message_save()
      write.csv(calib1,file.path("src","compiler","calib1.csv"))
      
      ("Saving calib2.csv")%>% message_save()
      write.csv(calib2,file.path("src","compiler","calib2.csv"))
    }
    
    
    
  }
  # Solving the model
  
  solved_data <- data_for_solver
  
  ## stock the results in solved_data
  shock_nb = 1
  for (scen in scenario){
    
    readLines("src/EViews/run_main_from_R.prg") %>%
      str_replace_all("(^%scenario\\s*=\\s*).*$", str_c("\\1\\\"",scen,"\\\"")) %>%
      
      writeLines("src/EViews/run_main_from_R.prg")
    
    if(shock_nb>1){
      readLines("src/EViews/run_main_from_R.prg") %>%
        str_replace_all("(^%warning\\s*=\\s*).*$", str_c("\\1\\\"", "FALSE", "\\\"")) %>%
        str_replace_all("(^%recompile_model\\s*=\\s*).*$", str_c("\\1\\\"", "FALSE", "\\\"")) %>%
        
        writeLines("src/EViews/run_main_from_R.prg")
      
    }  
    
    
    # Run ThreeME in Eviews
    cat("Run ThreeME in Eviews\n")
    sys::exec_wait(normalizePath(path_eviews_exe), c(str_c(eviews_default_path, "run_main_from_R.prg")), timeout = eviews_timeout)
    
    shock_nb = shock_nb + 1
  }  
  
  
  # Removing calib1 and calib 2 files
  for (i in 1:2) {
    file <- str_c("src/compiler/calib",i,".csv")
    if (file.exists(file)) {
      cat(str_c("Removing file calib",i,".csv\n"))
      file.remove(file)
    }
  }
  

  
  
}
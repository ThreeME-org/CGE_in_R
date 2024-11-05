post_compiler_checks <- function(base_advanced_arguments){
   list2env(base_advanced_arguments,envir = environment())
  ## 1.  Checking that the calib.csv file has all the endogenous variables declared in the model.prg file
  
  ### Get all equations from the equation list
  mod_from_dynamo <- readLines(file.path("src", "compiler", "model.prg")) %>%
    str_remove_all("^a_3ME\\.append\\s")
  list_endo <- mod_from_dynamo %>%
    
    ### Remove basic common things and keep LHS of equations
    str_remove_all("\\s+") %>%
    str_remove_all("=.*$") %>%
    
    ### remove funcions
    str_remove_all("\\w+\\(") %>%
    str_replace_all("^|$","@") %>%
    str_replace_all("(\\+|-|\\*|/|\\(|\\)|\\^)","@") %>%
    
    ### remove numbers
    str_replace_all("@\\d+(\\.\\d+)?@","@") %>%
    
    ### clean up
    str_replace_all("@+","@") %>%
    
    ### remove extra variables
    str_replace_all("^(@\\w+\\@).*$","\\1") %>%
    str_remove_all("@")
  
  equation_table <- data.frame(endogenous = list_endo, equation = mod_from_dynamo)
  
  calib_vars <- data.table::fread("src/compiler/calib.csv", data.table = FALSE ) %>% names()
  
  missing_calibs <- setdiff(list_endo,calib_vars)
  
  if(length(missing_calibs) > 0){
    
    ("The following endogenous variables have not been calibrated in the calib.csv file:") %>% message_not_ok()
    
    plop <- equation_table %>% filter(endogenous %in% missing_calibs)
    cat(plop$endogenous, sep = "   ")
    cat("\n")  
  }else{
    
    ("All endogenous variables are present in the calib.csv file.") %>% message_ok()
    
  }

}

eviews_checks<- function(config_list = configuration){
  
  list2env(config_list,envir = environment())
  list2env(input,envir = environment())
  list2env(advanced_config,envir = environment())
  ## 2.  Check if EViews will be used
  if(file.size(file.path("src","compiler","model.prg")) > max_tresthor_capability *1000 & Rsolver == TRUE  ){
    Rsolver <- FALSE
    if (grepl("win", tolower(osVersion))){
      ("The model appears to be too large for current R solver capabilities, EViews should be used instead.") %>% message_warning()
    }else{
      ("The model appears to be too large for current R solver capabilities. EViews should be used instead, however running EViews requires a Windows OS.") %>% message_not_ok
      ("Stopping now") %>% message_stopbomb()
      stop(error ="Cannot run the specified configuration of ThreeME on this computer.")
    }
  }
  
  if( file.size(file.path("src", "compiler", "model.prg")) <= max_tresthor_capability * 1000 &
      grepl("win", tolower(osVersion)) == FALSE &
      Rsolver == FALSE
  ){
    ("It looks like you are not using Windows, EViews cannot be used on other OSs than Windows. \nHowever, since the model specified is not too large, the model will be solved through R.") %>% message_any("\U2757  \U1F914")
    
    Rsolver <- TRUE
    rcpp_option = TRUE 
    use.superlu = FALSE
  }
  
  
  ## 3. Checking and detecting automatically location of EViews.exe 
  
  ### Detect location of EViews.exe  
  if (grepl("win", tolower(osVersion)) & Rsolver == FALSE){
    
    if (file.exists(path_eviews_exe)) {
      paste0("Default EViews path: \nThe EViews path provided (",path_eviews_exe,") is correct.") %>% message_ok()
    } else {
      paste0("Default EViews path: \nThe EViews path provided (",path_eviews_exe,") is incorrect.") %>% message_warning()
      
      nb_eviews.exe <- 0
      for (progfolder in c("C:/Program Files","C:/Program Files (x86)")){  
        for (i in c(8:14)){
          # assign(paste0("eviews.exe.ver",i), paste0("C:/Program Files/EViews ",i,"/EViews",i,".exe"))
          path_eviews_exe_tested <- paste0(progfolder,"/EViews ",i,"/EViews",i,".exe")
          
          if (file.exists(path_eviews_exe_tested)) {
            path_eviews_exe <- path_eviews_exe_tested
            nb_eviews.exe <- nb_eviews.exe + 1
            paste0("Possible path: ", path_eviews_exe, ". \n") %>% message_ok()
            
            
          }  
          
          path_eviews_exe_tested <- paste0(progfolder,"/EViews ",i,"/EViews",i,"_x64.exe")
          if (file.exists(path_eviews_exe_tested)) {
            path_eviews_exe <- path_eviews_exe_tested
            nb_eviews.exe <- nb_eviews.exe + 1
            paste0("Possible path: ", path_eviews_exe, ". \n") %>% message_ok()
            
          } 
        }
      }
      if (nb_eviews.exe == 0) {
        ("No Eviews.exe found. \nCheck if Eviews is installed if you wish to use the EViews solver.") %>% message_not_ok()
        ("Stopping now") %>% message_stopbomb()
        stop(error = "Cannot find EViews.")
        
      }else{
        paste0(nb_eviews.exe, " path(s) found.\n","The following Eviews executable will be used: ",
               path_eviews_exe,
               ". \nChange manually if you wish to use another version.\n",
               "In the config file, change the following line: path_eviews_exe <- DESIRED PATH" ) %>% message_any("\U1F4A1")
        
      }
      
      
      ### Define the path of Eviews default directory
      path_eviews_default <- paste0(getwd(), "/src/EViews/")
    }
    ### (if issue) Define the absolute path of Eviews default directory
    # path_eviews_default <- "C:/Users/reynesfgd/GitHub/ThreeME_V3/src/EViews/"
  }

  eviewspath <- ifelse(file.exists(path_eviews_exe),normalizePath(path_eviews_exe) , "")
  return <- list(
    path_eviews_exe =   eviewspath, 
    Rsolver = Rsolver , 
    rcpp_option = rcpp_option , 
    use.superlu = use.superlu 
  )
  
}
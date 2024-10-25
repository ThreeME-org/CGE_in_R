### run dynamo 

run_dynamo <- function(config_list = configuration){
  
  list2env(config_list,envir = environment())
  list2env(input,envir = environment())
  
  dynamo_files_out <- c("calib.csv", "model.prg")
  
  lists_files <- file.path("model", model_folder, lists_files)
  calib_files <- file.path("model", model_folder, calib_files)
  model_files <- file.path("model", model_folder, model_files)
  
  
  readLines(file.path("src", last(lists_files))) %>%
    str_replace_all("(^\\s*%baseyear\\s*:=\\s*).*$", str_c("\\1", baseyear)) %>%
    # str_replace_all("(^include\\s+\\.\\\\R_lists).*$", str_c("\\1_", iso3)) %>%
    writeLines(file.path("src", last(lists_files)))
  
  ## A if no compiler needed
  if(advanced_config$skip_compiler == TRUE & advanced_config$recompile_model == TRUE){
    if(sum(file.exists(file.path("src","compiler", dynamo_files_out)) ) == length(dynamo_files_out) ){
      ("Found pre-existing dynamo output files") %>% message_ok()
      
    }else{
      ("Some of the compiler output files were not found in the src/compiler folder.\nPlease add them manually or change skip_compiler option to FALSE in the config to generate those files and try again.") %>% message_not_ok()
      
      ("Stopping now") %>% message_stopbomb()
      
      stop(error ="Compiler files not found.")
    }
    
  }else{
    
    ## B With a compiler
    
    ### B1. Remove existing dynamo output
    
    if(sum(file.exists(file.path("src","compiler",dynamo_files_out)) ) >0 ){
      ("Found pre-existing dynamo output files, deleting them.") %>% message_delete()
    }
    
    quietly(map)(dynamo_files_out , 
                 function(file = .x){ 
                   if(file.exists(file.path("src","compiler",file) ) ){
                     file.remove(file.path("src","compiler",file))
                   }
                 }
    )$result
    
    ### B2. Run the DynaMo compiler
    
    ermeeth::runDynaMo(iso3, baseyear, lastyear, calib_files, model_files, max_lags)
  }
  
  ### B3. Bug correction if dynamo doesn't put the files in the right place
  quietly(map)(dynamo_files_out,
               function(file = .x){
                 if(file.exists(file)){
                   file.copy(
                     from=file,
                     to = file.path("src","compiler",file),
                     overwrite = TRUE)
                   file.remove(file)
                 }
               }
  )$result
  
  
  ## C. Check if compiled successfully
  missing_files <- file.path("src","compiler",dynamo_files_out)[file.exists(file.path("src","compiler",dynamo_files_out)) == FALSE ] %>% basename()
  
  if(length(missing_files) == 0){
    
    ("DYNAMO succeeded, continuing...") %>% message_ok()
    
  }else{
    
    ("DYNAMO could not write the following files :")  %>% message_not_ok()
    str_c(missing_files,sep = "\n")  %>% message_not_ok()
    ("Stopping now") %>% message_stopbomb()
    
    stop(error = "Dynamo Error")
  }
  
  cat("\n")
}
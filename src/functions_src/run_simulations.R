run_simulations <- function(configuration = config,
                            export_scenarii_to_excel = FALSE){
  
  
  list2env(configuration,envir = environment())
  list2env(input,envir = environment())
  list2env(advanced_config,envir = environment())
  compil = "dynamo"
  ### PART 1 RUNNING DYNAMO 
  
  run_dynamo(config_list = configuration)

  post_compiler_checks(base_advanced_arguments = advanced_config )
  new_params_solver<- eviews_checks(config_list = configuration)
  
  list2env(new_params_solver,envir = environment())
  
  ### PART 2 SOURCING SCENARII CALIBRATION
  
  calib <- fread("src/compiler/calib.csv", data.table = FALSE) %>% 
    select(-all_of("baseyear")) %>% 
    mutate(year = year + baseyear) 
  
  OGcalib <- calib
  
  ## B Baseline shock calibration (ie deviating from the steady state at the baseline configuration)
  source(calib_baseline, local = TRUE)
  write.csv(baseline_ch, 
            file = file.path("configuration","scenarii_calib","calib_baseline.csv"),
            row.names = FALSE)
  
  ## C Modified calib to integrate potential baseline changes
  
  baseline_vars <- setdiff(names(baseline_ch), "year")
  
  calib_new_base <- OGcalib %>% 
    filter(year %in% c(firstyear:lastyear)) %>% 
    select(-all_of(baseline_vars)) %>% 
    full_join(baseline_ch, by= "year")
  ### calib_new_base now integrates changes with the baseline scenario and should be used to configure shock scenarii
  
  ## D Scenarii shock calibration
  if(automated_shocks == FALSE){
    shock_ch_scenarii <- scenario %>% 
      map(~source(file.path("configuration","scenarii_calib", str_c("2_calib_shock_",.x,".R")), local = TRUE )) %>% 
      map(~.x$value) %>% 
      set_names(scenario)
  }else{
    source(calib_scenario, local = TRUE)
    shock_ch_scenarii <- purrr::set_names(scenario)  %>% 
      map( ~safely(automated_calib_shock)(.x,calib_new_base, parameters_range)$results ) |> compact()
    failed_scen <- setdiff(scenario, names(shock_ch_scenarii))
    if(length(failed_scen)>0){
      message_warning("Some Scenarios could not be calibrated, dropping them..")
      
      cat(failed_scen,sep = "\n")
      scenario <- names(shock_ch_scenarii)
      
    }else{
      message_ok("All Scenarios were properly calibrated")
    }
    
  }
  
  if(Rsolver== FALSE){
    shock_ch_scenarii %>% imap(~write.csv(.x, 
                                          file = file.path("configuration","scenarii_calib",str_c("calib_shock_",.y,".csv")),
                                          row.names = FALSE))}
  
  all_scenarii <- append(shock_ch_scenarii,  list(baseline_ch) ) %>% set_names(c(scenario, "baseline"))
  
  
  ## E. Saving all scenarii to an Excel spreadsheet (it is only for ex-post checking purposes)
  ##### START  EXCEL SCENARIO SHOCK SAVE
  if(export_scenarii_to_excel){
  
  ### Save a summary of all scenarii to Excel
  xlsx.file = "configuration/scenarii_calib/summary_of_scenarii.xlsx"
  wb <- createWorkbook()
  
  addWorksheet(wb, "Sheet 1")
  saveWorkbook(wb, xlsx.file, overwrite = TRUE)
  
  ### Preparing the workbook
  wb <- loadWorkbook(xlsx.file)
  
  all_scenarii %>% imap(function(database, name) {
    if (!name %in% sheets(wb)){ 
      addWorksheet(wb,sheetName = name) 
    }else{
      removeWorksheet(wb,name)
      addWorksheet(wb,sheetName = name) 
    }
    
    n_cols <- ncol(database) - 1
    
    writeData(wb , t(database),    sheet = name, startCol = "B", startRow = 1, colNames = FALSE, rowNames = TRUE)
    writeData(wb , "" ,            sheet = name, startCol = "B", startRow = 1, colNames = FALSE, rowNames = FALSE)
    writeData(wb , n_cols ,        sheet = name, startCol = "A", startRow = 1, colNames = FALSE, rowNames = FALSE)
    writeData(wb , rep(1,n_cols) , sheet = name, startCol = "A", startRow = 2, colNames = FALSE, rowNames = FALSE)
    
  })
  
  ### saving 
  saveWorkbook(wb,xlsx.file,overwrite = TRUE)
  }
  ##### END EXCEL SCENARIO SHOCK SAVE
  
  
  data_for_solver <- all_scenarii %>% 
    map(~update_data_merge(calib_new_base , .x)) ##data_for solver contains the full databases needed to run the solver for each scenario
  
  ### PART 3 MODEL BUILDING AND SOLVING
  ### Prepare and store the databases in long format from EViews
  
  reagg_bool  = ifelse(length(intersect(output_saved, c("com","sec","sec_com") )) >0 , TRUE, FALSE ) 
  
  if(file.exists(paste0("src/bridges/bridge_",classification,".R")) & file.exists(paste0("src/bridges/codenames_",classification,".R"))){
    
    # source("src/functions_src/0_loadResults.R")
    source(paste0("src/bridges/bridge_",classification,".R"),local = TRUE)
    source(paste0("src/bridges/codenames_",classification,".R"),local = TRUE)
    bridge_check = TRUE
  }else{
    bridge_check = FALSE
    bridge_sectors = NULL
    bridge_commodities = NULL
    
    
    ### Commodities: c4
    names_commodities <- rbind(
      c('Industry','cind'),
      c('Transport','ctrp'),
      c('Services','cser'),
      c('Energy','cenj'),
      c('Industry','C001'),
      c('Transport','C002'),
      c('Services','C003'),
      c('Energy','C004')
    ) %>%
      as.data.frame() %>% rename(name = V1,code = V2)
    
    ### Sectors: s4
    names_sectors <- rbind(
      c('Industry','sind'),
      c('Transport','strp'),
      c('Services','sser'),
      c('Energy','senj'),
      c('Industry','s001'),
      c('Transport','s002'),
      c('Services','s003'),
      c('Energy','s004')
    ) %>%
      as.data.frame() %>% rename(name = V1,code = V2)
    
  } 
  
  #### 3.A R SOLVER
  
  if(Rsolver){
    
    data_full <- R_model_solver(
      config_file = configuration,
      before_solving_data = data_for_solver,
      cnb = calib_new_base
      )
    
    data_list <-  data_full |> 
      aggregate_com_sec(bridge_com = bridge_commodities ,bridge_sec = bridge_sectors ,by_com = reagg_bool ,by_sec = reagg_bool , scenarios =  c("baseline",scenario |> unname())) |> purrr::compact() |> 
      map(~as.data.frame(.x) |> add_com_sec_names(commodities_names = names_commodities,sectors_names = names_sectors) |> long_input())
    
  }

  
  #### 3.B EVIEWS SOLVER
  if(Rsolver == FALSE){
    eviews_model_solver(
      config_file = configuration,
      before_solving_data = data_for_solver,
      overwrite_eviews = path_eviews_exe)
    
    
    data_list <-purrr::set_names(scenario)  |> map(~read_3me_eviews_csv(file.path("data","temp","csv",str_c(.x,".csv") ) , variables_selection = variables_to_keep )) %>% 
      reduce(full_join, by = c("year", "variable","baseline")) |> 
      aggregate_com_sec(bridge_com = bridge_commodities ,bridge_sec = bridge_sectors ,by_com = reagg_bool ,by_sec = reagg_bool , scenarios =  c("baseline",scenario |> unname())) |> purrr::compact() |> 
      map(~ as.data.frame(.x) |> add_com_sec_names(commodities_names = names_commodities,sectors_names = names_sectors) |> long_input())
    
  }
  
  ### PART 4 SAVING DATABASE
  saveRDS(data_list[[1]] , file = file.path("data","output", paste0(project_name,".rds")))
  if("sec_com" %in% output_saved){
    saveRDS(data_list[[4]] , file = file.path("data","output", paste0(project_name,"_sec_com.rds")))}
  if("com" %in% output_saved){
    saveRDS(data_list[[2]] , file = file.path("data","output", paste0(project_name,"_com.rds")))}
  if("sec" %in% output_saved){
    saveRDS(data_list[[3]] , file = file.path("data","output", paste0(project_name,"_sec.rds")))}


  
  return(data_list[[1]])
  
  
}
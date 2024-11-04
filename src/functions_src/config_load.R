readconfig <- function(input_config_file = config_main ,
                       output_config_file = config_quarto){
  
  ## CHECKS HERE
  source(input_config_file,local = TRUE)
  source(output_config_file,local = TRUE)
  
  ### Check calib files exist
  
  
  
  if (automated_shocks){
    ## if automated shocks, generate range list using 
    source(file.path("configuration","scenarii_calib",str_c("3_automated_parameters_generator_",project_name,".R")))
    scenario <- parameters_range$name   ## if automated shocks , the names will be defined in 3_Automated_parameters_generator.R
  }
  
  ## Default Parameters:
  calib_baseline <- file.path("configuration","scenarii_calib",paste0("1_calib_",scenario_baseline,".R"))
  calib_scenario <- file.path("configuration","scenarii_calib",paste0("2_calib_shock_",scenario,".R"))
  
  if(automated_shocks){
    calib_scenario <- file.path("configuration","scenarii_calib",paste0("2_calib_shock_",project_name,".R")) ## One unique scenario file will be run  
  }
  
  # if(use.superlu == TRUE){ 
  #   Sys.setenv("CPATH"="/opt/homebrew/include")
  #   Sys.setenv("LIBRARY_PATH"="/opt/homebrew/lib")
  #   Sys.setenv("PKG_LIBS"="-lsuperlu")
  # }
  
  
  
  scenario_name <- paste(scenario, iso3, sep = "_") %>% tolower()
  shocks_nb <- length(scenario)
  max_tresthor_capability <- 300 # Max size in kb for a model that tresthor can handle
  path_main <- NULL
  save_files_res <-TRUE
  
  config <- list(
    input = list( 
      project_name = project_name,
      iso3 = tolower(iso3),
      classification = tolower(classification),
      model_folder = model_folder,
      automated_shocks = automated_shocks ,
      scenario_baseline = tolower(scenario_baseline) ,
      scenario = tolower(scenario) ,
      scenario_name = scenario_name,
      shocks_nb = shocks_nb ,
      baseyear = baseyear,
      lastyear = lastyear,
      shockyear = shockyear,
      max_lags = max_lags,
      firstyear = firstyear,
      variables_to_keep = variables_to_keep,
      lists_files = lists_files,
      calib_files = calib_files,
      model_files = model_files,
      calib_baseline = calib_baseline,
      calib_scenario = calib_scenario,
      
      advanced_config = list(
        Rsolver = Rsolver,
        path_eviews_exe = path_eviews_exe ,
        eviews_timeout = eviews_timeout  ,
        warning = warning ,    
        tolerance_calib_check = tolerance_calib_check ,
        skip_compiler = skip_compiler, 
        max_tresthor_capability = max_tresthor_capability,
        recompile_model = recompile_model, 
        rcpp_option = rcpp_option ,
        use.superlu = use.superlu ,
        save_files_res = save_files_res,
        path_main = path_main,
        output_saved = output_saved)
      
      
      ),
    output = list(
      quartos_to_render = quartos_to_render ,
      quartos_parameters = quartos_parameters
    )
  ) 
  
} 

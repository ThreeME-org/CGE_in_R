R_model_solver <- function(config_file = configuration,
                            before_solving_data = data_for_solver, 
                            overwrite_rcpp = rcpp_option,
                           cnb = calib_new_base){
  
  
  list2env(config_file,envir = environment())
  list2env(config_file$input,envir = environment())
  list2env(config_file$input$advanced_config,envir = environment())
  rcpp_option = overwrite_rcpp 
  calib_new_base = cnb
  data_for_solver <- before_solving_data
  
  if (recompile_model){
    ####### If model must be recompiled
    
    ### A.1 Transform model.prg file into tresthor syntax
    ("Translating model.prg file for tresthor format") %>% message_sub_step()
    model_to_build <- translate_modelprg(base.year = baseyear,last.year = lastyear)
    
    ### A.2 Build model and save
    ("Creating the model for simulations") %>% message_sub_step()
    tresthor::create_model(model_name = "themodel" ,
                           endogenous = model_to_build$endo,
                           exogenous = model_to_build$exo ,
                           coefficients = model_to_build$coef,
                           equations = model_to_build$equations, 
                           rcpp = rcpp_option ,rcpp_path = "src/R_solver_files/" ,
                           no_var_map = TRUE )
    
    ("Saving the model and dependencies for future usage") %>% message_sub_step()
    tresthor::export_model(themodel,filename = file.path("src","R_solver_files","model_thor.txt"))
    tresthor::save_model(themodel,folder_path  = file.path("src","R_solver_files/") )
    
    data_3me <- model_to_build$data %>%filter( year %in% c(firstyear:lastyear))
    saveRDS(data_3me,"src/R_solver_files/data_thor.rds")
    
  }else{
    ### A.3 Load model and calib
    tresthor::load_model(file = file.path("src","R_solver_files","themodel.rds"))
    data_3me <- readRDS(file.path("src","R_solver_files","data_thor.rds"))
  }
  
  ### A.4 Consolidating databases : adding the newly created variables elem variables to calib_new_base
  
  #### if new variables created for the Rsolver must be added to calib_new_base
  newly_created_variables <- setdiff(names(data_3me), names(calib_new_base) )
  if(length(newly_created_variables) > 0){
    calib_new_base <- calib_new_base %>% 
      full_join(data_3me %>% 
                  select(all_of(c("year",newly_created_variables))), by = "year" )
  }
  
  
  
  
  ### A.5 Check calibration at baseyear for calib.csv
  parts <- c("prologue", "heart", "epilogue")
  parts_list <- map(parts, 
                    function(part = .x){
                      list( 
                        part = part ,
                        bool = eval(parse(text = paste0("themodel@",part) )),
                        fun_check = eval(parse(text = paste0("themodel@",part,"_equations_f") )) )
                    }) %>% 
    purrr::set_names(parts)
  
  ("Calibration check at the base year with the calibration data") %>% message_sub_step()
  
  baseyear_index <- which(data_3me$year== baseyear)
  
  equations <- map(parts, 
                   function(section = .x){
                     if(parts_list[[section]]$bool == TRUE){
                       
                       equations <- themodel@equation_list %>% 
                         filter(part == section) %>% 
                         select(equation =name, formula = equation) %>% 
                         mutate(calib_test = parts_list[[section]]$fun_check(t = baseyear_index, t_data = data_3me)  )
                       
                     }else{equations<-NULL}
                   }) %>% compact() %>% reduce(rbind)
  
  equations_check <- equations %>% filter(abs(calib_test) >= tolerance_calib_check)
  
  
  if(nrow(equations_check) == 0 ){
    ("All equations appear to well calibrated at the baseyear with the calib.csv file.") %>% message_ok()
  }else{ 
    ("The following equations are not well calibrated for the baseline scenario:") %>% message_warning()
    print(equations_check)
    Sys.sleep(2)
    
    #### TODO : ADD OPTION / PROMPT to stop here
  }
  
  
  ##solver
  
  solved_data <- data_for_solver
  ## 1. Solving using R : loop needed while we work on parallelisation
  "Solving each scenario, please wait... \U23F1" %>%   message_main_step()
  scenar_order <- c("baseline", setdiff(names(data_for_solver), "baseline")) 
  tot_scen <- length(scenar_order)
  
  
  for (item_scen in 1:tot_scen){
    
    if(length(variables_to_keep)==0){
      variables_to_keep <- setdiff(names(data_for_solver[["baseline"]]), "year") %>% tolower
    }
    
    scenar_solved <- scenar_order[item_scen]
    str_c("Solving scenario ",scenar_solved ) %>% message_any(str_c(item_scen," / ", tot_scen))
    # browser()
    solved_data[[scenar_solved]] <- thor_solver(themodel,
                                                first_period = baseyear,last_period = lastyear,
                                                database = data_for_solver[[scenar_solved]],
                                                index_time = "year", rcpp = rcpp_option,skip_tests = TRUE) %>% 
      select(year, any_of(tolower(variables_to_keep)) )
    
  }
  
  ### Generate long format datafull
  
  data_full <- solved_data %>% imap(~pivot_longer(.x,cols = !year,names_to = "variable",values_to = .y) %>% 
                                      mutate(variable = toupper(variable))) %>% 
    reduce(full_join, by = c("year","variable")) %>% 
    mutate(sector = NA_character_,commodity = NA_character_) %>% as.data.frame()
  

  
}

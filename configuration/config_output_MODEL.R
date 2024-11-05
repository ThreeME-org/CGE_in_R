##config quarto

quartos_to_render <-list(
  
  basic_results = TRUE,
  texdoc = FALSE,
  model_info = FALSE,
  sectoral_results = FALSE
  
)

quartos_parameters <- list(
  
  basic_results = list(
    project_name = project_name,
    startyear = 2019,
    shockyear = shockyear,
    endyear = lastyear,
    scenarios = unname(scenario)  # List of scenarii to be plotted
  ),
  
  texdoc = list(
    
    project_name = project_name,
    texdoc_mdls = "default",
    texdoc_exovar = "03.1-exovar.mdl",
    model_files = model_files,
    mdl_folder = model_folder
  ),
  
  model_info = list(
    baseyear =  baseyear,
    lastyear = lastyear,
    classification = classification,
    scenario_baseline = scenario_baseline,
    shocks = scenario,
    calib_files = calib_files,
    model_files = model_files,
    rsolver =  Rsolver,
    project_name = project_name
  ),
  
  
  sectoral_results = list(
    project_name = project_name
  )

  
  
  )

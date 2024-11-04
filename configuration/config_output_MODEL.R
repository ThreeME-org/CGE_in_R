##config quarto

quartos_to_render <-list(
  
  basic_results = TRUE,
  # texdoc = TRUE,
  model_info = FALSE,
  sectoral_results = FALSE
  
)

quartos_parameters <- list(
  
  basic_results = list(
    project_name = project_name,
    # startyear = startyear,
    shockyear = shockyear,
    endyear = lastyear,
    # template_default = "ofce",
    scenarios = unname(scenario)  # List of scenarii to be plotted
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
    project_name = project_name,
    texdoc = FALSE,
    texdoc_mdls = "default",
    texdoc_exovar = NULL,
    mdl_folder = model_folder
  ),
  
  
  sectoral_results = list(
    project_name = project_name
  )

  
  
  )

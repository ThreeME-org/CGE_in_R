##config quarto

quartos_to_render <-list(
  
  basic_results = FALSE,
  template_pres = TRUE,
  equation_list = TRUE
  
)

quartos_parameters <- list(
  
  basic_results = list(
    project_name = project_name,
    startyear = 2019,
    endyear = lastyear,
    template_default = "ofce",
    country_name = "France",
    scenario = unname(scenario)  # List of scenarii to be plotted
  ),
  
  
  template_pres = list(
    project = project_name,
    shock_year = shockyear 
  ),
  
  equation_list = list(
    project_name = project_name,
    prefix =  "plop",
    mdl_files = model_files,
    exo = NULL ,
    model_path= model_folder,
    recompile_tex = 0
  )

  
  
  )

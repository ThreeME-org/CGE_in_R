# Main
## Help is available in user_guides

## 0. Setup
rm(list = ls())
source(file.path("src","setup.R"))


  config <- readconfig(input_config_file = file.path("configuration", "config_input_MODEL.R") ,
                      output_config_file = file.path("configuration", "config_output_MODEL.R")
                     )

## 1. OPTIONAL Prepare the baseline and/or shock calibration file , uncomment the lines

## >>>>>>> uncomment start
# calibration_bubble <- calibration_environment(baseline_calibration = FALSE)
# list2env(calibration_bubble, envir = globalenv())
# ### You may now open the relevant scenario config file to edit and test it
# rm(list = names(calibration_bubble))
## <<<<<<< uncomment end

## 2. Run simulations

data_full <- run_simulations(configuration = config)

# data_full |> filter(variable %in% c("Y")) |> ggplot(aes(y = (values/values_ref)-1,x = year)) +
  # geom_line(aes(linetype = scenario))

## 3. Les sorties 

### 3.A Compiler la documentation du model depuis les equations (version LaTeX et quarto)


### 3.B Sorties via quarto templates

produce_quartos(Show = TRUE,output_path = ".")

cleanup_output() #Pour nettoyer les fichiers html anciens

### 3.C Faire votre propre quarto 

# quarto::quarto_render("wp.qmd")
output_file = paste0("Results_",config$input$project_name,".html")

quarto::quarto_render(input = file.path("Mon_Quarto_LUNCH.qmd"),
                      output_file = output_file,
                      output_format = "typst",execute_params = list(scenario = config$input$scenario))

browseURL(file.path("results/quarto_render/", output_file) )

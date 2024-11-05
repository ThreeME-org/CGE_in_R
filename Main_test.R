# Main file to launch simulations

## 0. Setup
rm(list = ls())
source(file.path("src","setup.R"))


config <- readconfig(input_config_file = file.path("configuration", "config_input_MODEL.R") ,
                     output_config_file = file.path("configuration", "config_output_MODEL.R")
)

## 1. OPTIONAL Prepare the baseline and/or shock calibration file, uncomment the lines

## >>>>>>> uncomment start
# calibration_bubble <- calibration_environment(baseline_calibration = FALSE)
# list2env(calibration_bubble, envir = globalenv())
# ### You may now open the relevant scenario config file to edit and test it
# rm(list = names(calibration_bubble))
## <<<<<<< uncomment end

## 2. Running simulations

data_full <- run_simulations(configuration = config)

## 3. Results 

### 3.A Using templates 

produce_quartos(Show = TRUE,output_path = ".")

cleanup_output(render_dir = ".") # to clean older html renders, keeping the last versions only

### 3.B Your own quarto file

output_file = paste0("Results_",config$input$project_name,".html")

quarto::quarto_render(input = file.path("my_quarto.qmd"),
                      output_file = output_file,
                      output_format = "html",
                      execute_params = list(scenario = config$input$scenario)
)

browseURL(file.path("results/quarto_render/", output_file) )

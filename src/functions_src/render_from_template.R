
### Render quarto from template

render_from_template <- function(
    quarto_to_use = "basic_results.qmd",
    quartos_folder = file.path("results","quarto_templates"),
    interim_file_name = "main_results.qmd",
    
    output_file_name = str_c("main_results_","_",format(Sys.time(), "%Y-%m-%d_%H-%M")),
    
    quarto_parameters_list = list() ,
    
    render_folder = file.path("results","quarto_render"),
    
    browse = TRUE){
  
  ### 0 - function parameters check
  if(tools::file_ext(interim_file_name) == "" ){interim_file_name <- stringr::str_c(interim_file_name,".qmd")}
  if(tools::file_ext(output_file_name) == "" ){output_file_name <- stringr::str_c(output_file_name,".html")}
  
  ### 1 - copy quarto
  
  file.copy(from = file.path(quartos_folder,quarto_to_use),
            to = interim_file_name,
            overwrite = TRUE)

  ### 2 - render quarto
  
  
  quarto::quarto_render(input = interim_file_name,
                        output_file = output_file_name,
                        execute_params = quarto_parameters_list
  )
  
  ### 3 - remove quarto
  file.remove(interim_file_name)

  ### 4 - browse output
  if(browse == TRUE){
    browseURL(file.path(render_folder ,output_file_name ))
}
  
}

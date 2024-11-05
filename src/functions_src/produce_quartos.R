produce_quartos<- function(Show = TRUE,
                templates_selection = config$output$quartos_to_render,
                parameters = config$output$quartos_parameters,
                templates_path = file.path("results","quarto_templates"),
                output_path = file.path("results","quarto_render"),
                project_name = config$input$project_name ){

  templates_selection = config$output$quartos_to_render
  parameters = config$output$quartos_parameters
  templates_path = file.path("results","quarto_templates")
  
  quartos_to_produce <- names(templates_selection[which(templates_selection[]==TRUE)])
  
  quartos_infos <- parameters[quartos_to_produce]

  output_names <- purrr::set_names( str_c(project_name,"_",quartos_to_produce,"_",format(Sys.time(), "%Y-%m-%d_%H-%M") ),
                                    quartos_to_produce)
    imap(quartos_infos,
      ~render_from_template(quarto_to_use = str_c(.y,".qmd"),
                             quartos_folder = templates_path,
                             interim_file_name = str_c(.y,"_temp.qmd") ,
                             output_file_name = output_names[.y],
                             quarto_parameters_list =.x,
                             browse = FALSE)
      )
    
    if(Show){
      str_c(output_names,".html") |> map(~browseURL(file.path(output_path,.x)))

    }

}
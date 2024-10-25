cleanup_output <- function(
    render_dir = file.path("results","quarto_render")
    ){
  
  html_list <- list.files(render_dir, "\\.html$")  
  
  treatment_base <- data.frame(nom_fichier = html_list) |>
    mutate(root = str_remove(nom_fichier, "_\\d{4}-\\d{2}-\\d{2}_\\d{2}-\\d{2}\\.html$"), 
           date = str_extract(nom_fichier, "_\\d{4}-\\d{2}-\\d{2}_\\d{2}-\\d{2}\\.html$")) |> 
    arrange(desc(date)) |> 
    group_by(root) |> 
    mutate(most_recent = ifelse(date == max(date, na.rm = TRUE),1,0)) |> 
    ungroup() |> filter(most_recent == 0)
  
  files_to_remove <- file.path(render_dir,treatment_base$nom_fichier)
  
  files_to_remove |> map(~file.remove(.x))
  
  
  
  
}
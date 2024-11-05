# Convert database into long format which is easier to be manipulated
long_input <- function(data,nom_ref = "baseline"){
  data_long <- data %>%
    as.data.frame() %>%
    mutate(values_ref = get(nom_ref)) %>%
    pivot_longer(c(-year, -variable, -sector, -commodity, -values_ref), 
                 names_to = "scenario", values_to = "values") %>%
    mutate(index_scen = case_when(
      scenario == nom_ref ~ 1,
      scenario != nom_ref ~ 0)) %>%
    as.data.frame()
  
  return(data_long)
}
